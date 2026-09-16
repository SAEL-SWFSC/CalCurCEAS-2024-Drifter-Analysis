# CalCurCEAS 2024
# Species-level validated hourly occurrence products from the final baleen dataset.
# Run from the repository root.

library(tidyverse)

input_file <- file.path(
  "supplement",
  "BaleenWhales",
  "CalCurCEAS_baleen_validated_hourly_presence_absence.csv"
)

figure_dir <- file.path("_figs", "BaleenWhales")
output_dir <- file.path("output", "BaleenWhales")

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

figure_file <- file.path(
  figure_dir,
  "CalCurCEAS_baleen_validated_hourly_occurrence_by_geographic_zone.png"
)

table_file <- file.path(
  output_dir,
  "CalCurCEAS_baleen_validated_hourly_occurrence_by_geographic_zone.csv"
)

zone_levels <- c(
  "Columbia River",
  "Oregon",
  "Northern California",
  "Central California",
  "Southern California"
)

species_levels <- c(
  "Blue whale",
  "Fin whale",
  "Sei whale"
)

species_columns <- c(
  "Blue whale" = "blue_whale_present",
  "Fin whale" = "fin_whale_present",
  "Sei whale" = "sei_whale_present"
)

species_labels <- c(
  "Blue whale" = "A. Blue whale",
  "Fin whale" = "B. Fin whale",
  "Sei whale" = "C. Sei whale"
)

species_colors <- c(
  "Blue whale" = "#5481BF",
  "Fin whale" = "#64AC83",
  "Sei whale" = "#9070B4"
)

if (!file.exists(input_file)) {
  stop("Input file not found: ", input_file)
}

hourly <- read_csv(
  input_file,
  col_types = cols(
    hour_start_utc = col_datetime(),
    hour_end_utc = col_datetime(),
    .default = col_guess()
  ),
  show_col_types = FALSE
)

required_cols <- c(
  "deployment",
  "hour_start_utc",
  "geographic_zone",
  "validated_analysis_hour",
  unname(species_columns)
)

missing_cols <- setdiff(required_cols, names(hourly))

if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

analysis <- hourly %>%
  filter(validated_analysis_hour) %>%
  mutate(
    geographic_zone = factor(geographic_zone, levels = zone_levels),
    across(all_of(unname(species_columns)), as.integer)
  )

if (any(is.na(analysis$geographic_zone))) {
  stop("At least one validated hour lacks a recognized geographic zone.")
}

if (length(setdiff(zone_levels, unique(as.character(analysis$geographic_zone)))) > 0) {
  stop("One or more expected geographic zones are absent.")
}

duplicate_hours <- analysis %>%
  count(deployment, hour_start_utc) %>%
  filter(n != 1)

if (nrow(duplicate_hours) > 0) {
  stop("Validated data contain duplicate deployment-hour rows.")
}

presence_values <- analysis %>%
  select(all_of(unname(species_columns))) %>%
  unlist(use.names = FALSE)

if (any(is.na(presence_values)) || any(!presence_values %in% c(0L, 1L))) {
  stop("Validated species-presence fields must contain only 0 or 1.")
}

expected_totals <- c(
  validated_hours = 4266,
  blue_positive_hours = 2447,
  fin_positive_hours = 2633,
  sei_positive_hours = 486
)

observed_totals <- c(
  validated_hours = nrow(analysis),
  blue_positive_hours = sum(analysis$blue_whale_present),
  fin_positive_hours = sum(analysis$fin_whale_present),
  sei_positive_hours = sum(analysis$sei_whale_present)
)

if (!all(observed_totals == expected_totals)) {
  stop(
    "Validated-hour totals do not match the final report values. Observed: ",
    paste(names(observed_totals), observed_totals, collapse = "; ")
  )
}

zone_deployments <- analysis %>%
  group_by(geographic_zone) %>%
  summarise(
    n_contributing_deployments = n_distinct(deployment),
    deployment_ids = paste(
      sort(unique(str_remove(deployment, "^CalCurCEAS_"))),
      collapse = ", "
    ),
    .groups = "drop"
  ) %>%
  mutate(
    contributing_deployments = paste0(
      n_contributing_deployments,
      " (",
      deployment_ids,
      ")"
    )
  )

table4 <- analysis %>%
  group_by(geographic_zone) %>%
  summarise(
    validated_hours = n(),
    blue_positive_hours = sum(blue_whale_present),
    fin_positive_hours = sum(fin_whale_present),
    sei_positive_hours = sum(sei_whale_present),
    .groups = "drop"
  ) %>%
  left_join(zone_deployments, by = "geographic_zone") %>%
  mutate(
    blue_occurrence_pct = 100 * blue_positive_hours / validated_hours,
    fin_occurrence_pct = 100 * fin_positive_hours / validated_hours,
    sei_occurrence_pct = 100 * sei_positive_hours / validated_hours
  ) %>%
  select(
    geographic_zone,
    contributing_deployments,
    validated_hours,
    blue_positive_hours,
    blue_occurrence_pct,
    fin_positive_hours,
    fin_occurrence_pct,
    sei_positive_hours,
    sei_occurrence_pct
  ) %>%
  mutate(geographic_zone = as.character(geographic_zone))

total_row <- tibble(
  geographic_zone = "TOTAL",
  contributing_deployments = paste0(
    n_distinct(analysis$deployment),
    " deployments"
  ),
  validated_hours = nrow(analysis),
  blue_positive_hours = sum(analysis$blue_whale_present),
  blue_occurrence_pct = 100 * blue_positive_hours / validated_hours,
  fin_positive_hours = sum(analysis$fin_whale_present),
  fin_occurrence_pct = 100 * fin_positive_hours / validated_hours,
  sei_positive_hours = sum(analysis$sei_whale_present),
  sei_occurrence_pct = 100 * sei_positive_hours / validated_hours
)

write_csv(
  bind_rows(table4, total_row),
  table_file,
  na = ""
)

daily_species <- analysis %>%
  select(
    deployment,
    hour_start_utc,
    geographic_zone,
    all_of(unname(species_columns))
  ) %>%
  pivot_longer(
    cols = all_of(unname(species_columns)),
    names_to = "species_column",
    values_to = "presence"
  ) %>%
  mutate(
    species = recode(
      species_column,
      !!!setNames(names(species_columns), unname(species_columns))
    ),
    species = factor(species, levels = species_levels),
    date = as.Date(hour_start_utc, tz = "UTC")
  ) %>%
  group_by(geographic_zone, species, date) %>%
  summarise(
    effort_hours = n(),
    positive_hours = sum(presence),
    .groups = "drop"
  )

survey_dates <- seq.Date(
  min(daily_species$date),
  max(daily_species$date),
  by = "day"
)

daily_species <- daily_species %>%
  complete(
    geographic_zone = factor(zone_levels, levels = zone_levels),
    species = factor(species_levels, levels = species_levels),
    date = survey_dates,
    fill = list(
      effort_hours = 0,
      positive_hours = 0
    )
  ) %>%
  arrange(geographic_zone, species, date)

if (any(daily_species$positive_hours > daily_species$effort_hours)) {
  stop("At least one daily positive-hour count exceeds available effort.")
}

y_max <- max(
  100,
  ceiling(max(daily_species$effort_hours) / 20) * 20
)

figure4 <- ggplot(daily_species, aes(x = date)) +
  geom_col(
    aes(y = positive_hours, fill = species),
    width = 0.85,
    show.legend = FALSE
  ) +
  geom_step(
    aes(y = effort_hours),
    colour = "black",
    linewidth = 0.45,
    direction = "mid"
  ) +
  facet_grid(
    rows = vars(geographic_zone),
    cols = vars(species),
    labeller = labeller(species = species_labels),
    drop = FALSE
  ) +
  scale_fill_manual(
    values = species_colors,
    drop = FALSE
  ) +
  scale_x_date(
    date_breaks = "1 month",
    date_labels = "%b",
    expand = expansion(mult = c(0.005, 0.005))
  ) +
  scale_y_continuous(
    limits = c(0, y_max),
    breaks = seq(0, y_max, by = 20),
    expand = expansion(mult = c(0, 0))
  ) +
  labs(
    x = NULL,
    y = "Deployment-hours per day"
  ) +
  theme_bw(base_size = 10) +
  theme(
    strip.background = element_blank(),
    strip.text.x = element_text(
      face = "bold",
      size = 10,
      margin = margin(b = 4)
    ),
    strip.text.y.right = element_text(
      angle = 270,
      size = 9,
      margin = margin(l = 4)
    ),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(
      linewidth = 0.25,
      colour = "grey90"
    ),
    panel.grid.major.y = element_line(
      linewidth = 0.25,
      colour = "grey90"
    ),
    panel.border = element_rect(
      colour = "grey60",
      fill = NA,
      linewidth = 0.5
    ),
    axis.text.x = element_text(
      angle = 45,
      hjust = 1,
      vjust = 1,
      size = 8
    ),
    axis.text.y = element_text(size = 8),
    axis.title.y = element_text(
      size = 10,
      margin = margin(r = 8)
    ),
    panel.spacing.x = grid::unit(0.08, "cm"),
    panel.spacing.y = grid::unit(0.30, "cm"),
    plot.margin = margin(t = 6, r = 8, b = 6, l = 6)
  )

ggsave(
  filename = figure_file,
  plot = figure4,
  width = 10.5,
  height = 8.5,
  units = "in",
  dpi = 300,
  bg = "white"
)

cat(
  "Created:\n",
  table_file, "\n",
  figure_file, "\n",
  sep = ""
)
