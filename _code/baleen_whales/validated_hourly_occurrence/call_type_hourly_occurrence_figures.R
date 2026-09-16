# CalCurCEAS 2024
# Blue and fin whale call-type validated hourly occurrence figures.
# Run from the repository root.

library(tidyverse)

input_file <- file.path(
  "supplement",
  "BaleenWhales",
  "CalCurCEAS_baleen_validated_hourly_presence_absence.csv"
)

figure_dir <- file.path("_figs", "BaleenWhales")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

blue_figure_file <- file.path(
  figure_dir,
  "CalCurCEAS_blue_call_type_hourly_occurrence_by_geographic_zone.png"
)

fin_figure_file <- file.path(
  figure_dir,
  "CalCurCEAS_fin_call_type_hourly_occurrence_by_geographic_zone.png"
)

zone_levels <- c(
  "Columbia River",
  "Oregon",
  "Northern California",
  "Central California",
  "Southern California"
)

call_info <- tribble(
  ~call_type,   ~column,             ~group, ~color,
  "Blue A",     "blue_a_present",    "Blue", "#009E73",
  "Blue B",     "blue_b_present",    "Blue", "#0072B2",
  "Blue D",     "blue_d_present",    "Blue", "#E69F00",
  "Fin 20 Hz",  "fin_20hz_present",  "Fin",  "#7B3294",
  "Fin 40 Hz",  "fin_40hz_present",  "Fin",  "#D95F5F"
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
  call_info$column
)

missing_cols <- setdiff(required_cols, names(hourly))

if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

analysis <- hourly %>%
  filter(validated_analysis_hour) %>%
  mutate(
    geographic_zone = factor(geographic_zone, levels = zone_levels),
    across(all_of(call_info$column), as.integer)
  )

if (any(is.na(analysis$geographic_zone))) {
  stop("At least one validated hour lacks a recognized geographic zone.")
}

duplicate_hours <- analysis %>%
  count(deployment, hour_start_utc) %>%
  filter(n != 1)

if (nrow(duplicate_hours) > 0) {
  stop("Validated data contain duplicate deployment-hour rows.")
}

call_values <- analysis %>%
  select(all_of(call_info$column)) %>%
  unlist(use.names = FALSE)

if (any(is.na(call_values)) || any(!call_values %in% c(0L, 1L))) {
  stop("Validated call-type presence fields must contain only 0 or 1.")
}

expected_totals <- c(
  blue_a_present = 427,
  blue_b_present = 2311,
  blue_d_present = 274,
  fin_20hz_present = 2605,
  fin_40hz_present = 84
)

observed_totals <- colSums(
  analysis %>% select(all_of(names(expected_totals)))
)

if (!all(observed_totals == expected_totals)) {
  stop(
    "Call-type totals do not match the final validated dataset values. Observed: ",
    paste(names(observed_totals), observed_totals, collapse = "; ")
  )
}

call_hourly <- analysis %>%
  select(
    deployment,
    hour_start_utc,
    geographic_zone,
    all_of(call_info$column)
  ) %>%
  pivot_longer(
    cols = all_of(call_info$column),
    names_to = "column",
    values_to = "presence"
  ) %>%
  left_join(call_info, by = "column") %>%
  mutate(
    date = as.Date(hour_start_utc, tz = "UTC")
  )

make_call_type_figure <- function(group_name, output_file, width) {

  group_info <- call_info %>%
    filter(group == group_name)

  group_data <- call_hourly %>%
    filter(group == group_name) %>%
    mutate(
      call_type = factor(call_type, levels = group_info$call_type)
    ) %>%
    group_by(geographic_zone, call_type, date) %>%
    summarise(
      validated_hours = n(),
      positive_hours = sum(presence),
      .groups = "drop"
    )

  survey_dates <- seq.Date(
    min(group_data$date),
    max(group_data$date),
    by = "day"
  )

  group_data <- group_data %>%
    complete(
      geographic_zone = factor(zone_levels, levels = zone_levels),
      call_type = factor(group_info$call_type, levels = group_info$call_type),
      date = survey_dates,
      fill = list(
        validated_hours = 0,
        positive_hours = 0
      )
    ) %>%
    arrange(geographic_zone, call_type, date)

  if (any(group_data$positive_hours > group_data$validated_hours)) {
    stop(group_name, " positive-hour counts exceed available effort.")
  }

  y_max <- max(
    100,
    ceiling(max(group_data$validated_hours) / 20) * 20
  )

  p <- ggplot(group_data, aes(x = date)) +
    geom_col(
      aes(y = positive_hours, fill = call_type),
      width = 0.85,
      show.legend = FALSE
    ) +
    geom_step(
      aes(y = validated_hours),
      colour = "black",
      linewidth = 0.45,
      direction = "mid"
    ) +
    facet_grid(
      rows = vars(geographic_zone),
      cols = vars(call_type),
      drop = FALSE
    ) +
    scale_fill_manual(
      values = setNames(group_info$color, group_info$call_type),
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
      y = "Validated Hours per Day"
    ) +
    theme_bw(base_size = 10) +
    theme(
      legend.position = "none",
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
    filename = output_file,
    plot = p,
    width = width,
    height = 8.5,
    units = "in",
    dpi = 300,
    bg = "white"
  )
}

make_call_type_figure(
  "Blue",
  blue_figure_file,
  width = 10.5
)

make_call_type_figure(
  "Fin",
  fin_figure_file,
  width = 8.0
)

cat(
  "Created:\n",
  blue_figure_file, "\n",
  fin_figure_file, "\n",
  sep = ""
)
