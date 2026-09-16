# CalCurCEAS 2024
# Regional validated hourly acoustic-scene figures.
# Run from the repository root.

library(tidyverse)
library(PAMscapes)

input_file <- file.path(
  "supplement",
  "BaleenWhales",
  "CalCurCEAS_baleen_validated_hourly_presence_absence.csv"
)

figure_dir <- file.path("_figs", "BaleenWhales")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

zone_levels <- c(
  "Columbia River",
  "Oregon",
  "Northern California",
  "Central California",
  "Southern California"
)

call_info <- tribble(
  ~call_type,   ~column,             ~freq_min, ~freq_max, ~color,
  "Fin 20 Hz",  "fin_20hz_present",  18,        25,        "#F8766D",
  "Fin 40 Hz",  "fin_40hz_present",  40,        80,        "#B79F00",
  "Blue A",     "blue_a_present",    70,        100,       "#00BA38",
  "Blue B",     "blue_b_present",    15,        20,        "#00BFC4",
  "Blue D",     "blue_d_present",    30,        100,       "#619CFF",
  "Sei DS",     "sei_ds_present",    44,        100,       "#F564E3"
)

freq_map <- call_info %>%
  transmute(
    type = call_type,
    freqMin = freq_min,
    freqMax = freq_max,
    color = color
  ) %>%
  as.data.frame()

plot_freq_min <- 10
plot_freq_max <- 120

light_shade_label <- "No effort"
dark_shade_label <- "Unusable acoustic data"

fill_values <- c(
  setNames(call_info$color, call_info$call_type),
  "No effort" = "#C4D6E3",
  "Unusable acoustic data" = "#6F6F6F"
)

fill_breaks <- c(
  call_info$call_type,
  light_shade_label,
  dark_shade_label
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
  "hour_end_utc",
  "geographic_zone",
  "validated_analysis_hour",
  "exclusion_reason",
  call_info$column
)

missing_cols <- setdiff(required_cols, names(hourly))

if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

duplicate_hours <- hourly %>%
  count(deployment, hour_start_utc) %>%
  filter(n != 1)

if (nrow(duplicate_hours) > 0) {
  stop("Input data contain duplicate deployment-hour rows.")
}

if (any(is.na(hourly$geographic_zone))) {
  stop("At least one hourly row lacks a geographic-zone assignment.")
}

if (sum(hourly$validated_analysis_hour, na.rm = TRUE) != 4266) {
  stop("Validated Analysis Hours do not match the final report total of 4,266.")
}

validated_values <- hourly %>%
  filter(validated_analysis_hour) %>%
  select(all_of(call_info$column)) %>%
  unlist(use.names = FALSE)

if (any(is.na(validated_values)) || any(!validated_values %in% c(0, 1))) {
  stop("Validated call-type presence fields must contain only 0 or 1.")
}

detections <- hourly %>%
  filter(validated_analysis_hour) %>%
  select(
    deployment,
    hour_start_utc,
    hour_end_utc,
    geographic_zone,
    all_of(call_info$column)
  ) %>%
  pivot_longer(
    cols = all_of(call_info$column),
    names_to = "column",
    values_to = "presence"
  ) %>%
  left_join(call_info %>% select(call_type, column), by = "column") %>%
  filter(presence == 1) %>%
  transmute(
    UTC = format(hour_start_utc, "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    end = format(hour_end_utc, "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    species = call_type,
    deployment = deployment,
    geographic_zone = geographic_zone
  )

if (nrow(detections) == 0) {
  stop("No validated call-positive hours were found.")
}

det_loaded <- loadDetectionData(
  x = detections,
  source = "csv",
  columnMap = list(
    UTC = "UTC",
    end = "end",
    species = "species"
  ),
  detectionType = "auto",
  wide = FALSE,
  tz = "UTC",
  extraCols = c(
    "deployment",
    "geographic_zone"
  )
)

for (zone_name in zone_levels) {

  dep_list <- hourly %>%
    filter(
      validated_analysis_hour,
      geographic_zone == zone_name
    ) %>%
    distinct(deployment) %>%
    arrange(deployment) %>%
    pull(deployment)

  if (length(dep_list) == 0) {
    warning("No validated hours found for ", zone_name, "; figure skipped.")
    next
  }

  det_zone <- det_loaded %>%
    filter(
      geographic_zone == zone_name,
      deployment %in% dep_list
    )

  if (nrow(det_zone) == 0) {
    warning("No call-positive hours found for ", zone_name, "; figure skipped.")
    next
  }

  dep_zone_ranges <- hourly %>%
    filter(
      deployment %in% dep_list,
      geographic_zone == zone_name
    ) %>%
    group_by(deployment) %>%
    summarise(
      zone_start_dep = min(hour_start_utc),
      zone_end_dep = max(hour_end_utc),
      .groups = "drop"
    )

  zone_start <- min(dep_zone_ranges$zone_start_dep)
  zone_end <- max(dep_zone_ranges$zone_end_dep)

  plot_span_days <- ceiling(
    as.numeric(difftime(zone_end, zone_start, units = "days"))
  )

  date_break_interval <- if (plot_span_days <= 16) {
    "1 day"
  } else if (plot_span_days <= 30) {
    "2 days"
  } else if (plot_span_days <= 45) {
    "3 days"
  } else {
    "4 days"
  }

  outside_zone <- hourly %>%
    filter(
      deployment %in% dep_list,
      hour_end_utc > zone_start,
      hour_start_utc < zone_end,
      geographic_zone != zone_name
    ) %>%
    transmute(
      deployment,
      start = pmax(hour_start_utc, zone_start),
      end = pmin(hour_end_utc, zone_end),
      shade_type = light_shade_label
    )

  pre_shading <- dep_zone_ranges %>%
    filter(zone_start_dep > zone_start) %>%
    transmute(
      deployment,
      start = zone_start,
      end = zone_start_dep,
      shade_type = light_shade_label
    )

  post_shading <- dep_zone_ranges %>%
    filter(zone_end_dep < zone_end) %>%
    transmute(
      deployment,
      start = zone_end_dep,
      end = zone_end,
      shade_type = light_shade_label
    )

  light_shading <- bind_rows(
    outside_zone,
    pre_shading,
    post_shading
  ) %>%
    filter(end > start)

  dark_shading <- hourly %>%
    filter(
      deployment %in% dep_list,
      geographic_zone == zone_name,
      !validated_analysis_hour,
      hour_end_utc > zone_start,
      hour_start_utc < zone_end
    ) %>%
    transmute(
      deployment,
      start = pmax(hour_start_utc, zone_start),
      end = pmin(hour_end_utc, zone_end),
      shade_type = dark_shade_label
    ) %>%
    filter(end > start)

  p_zone <- plotAcousticScene(
    x = det_zone,
    freqMap = freq_map,
    typeCol = "species",
    title = zone_name,
    bin = "1hour",
    by = "deployment",
    effort = NULL,
    scale = "log",
    freqMin = plot_freq_min,
    freqMax = plot_freq_max,
    alpha = 0.8
  )

  if (!is.null(p_zone$facet$params)) {
    if ("switch" %in% names(p_zone$facet$params)) {
      p_zone$facet$params$switch <- NULL
    }
    if ("strip.position" %in% names(p_zone$facet$params)) {
      p_zone$facet$params$strip.position <- "right"
    }
  }

  if (nrow(light_shading) > 0) {
    p_zone <- p_zone +
      geom_rect(
        data = light_shading,
        aes(
          xmin = start,
          xmax = end,
          ymin = plot_freq_min,
          ymax = plot_freq_max,
          fill = shade_type
        ),
        inherit.aes = FALSE,
        alpha = 0.45,
        colour = NA,
        show.legend = TRUE
      )
  }

  if (nrow(dark_shading) > 0) {
    p_zone <- p_zone +
      geom_rect(
        data = dark_shading,
        aes(
          xmin = start,
          xmax = end,
          ymin = plot_freq_min,
          ymax = plot_freq_max,
          fill = shade_type
        ),
        inherit.aes = FALSE,
        alpha = 0.75,
        colour = NA,
        show.legend = TRUE
      )
  }

  p_zone <- p_zone +
    scale_fill_manual(
      values = fill_values,
      breaks = fill_breaks,
      drop = FALSE
    ) +
    scale_x_datetime(
      limits = c(zone_start, zone_end),
      date_breaks = date_break_interval,
      date_labels = "%b %d",
      expand = expansion(mult = c(0.01, 0.01))
    ) +
    labs(
      x = "Date (UTC)",
      y = "Frequency (Hz)",
      fill = NULL
    ) +
    guides(
      fill = guide_legend(
        title = NULL,
        nrow = 2,
        byrow = TRUE,
        override.aes = list(alpha = 1)
      )
    ) +
    theme(
      plot.title = element_text(
        size = 16,
        face = "bold",
        hjust = 0.5
      ),
      axis.title = element_text(size = 13),
      axis.text.x = element_text(
        size = 11,
        angle = 45,
        hjust = 1
      ),
      axis.text.y = element_text(size = 11),
      strip.placement = "outside",
      strip.text.y.right = element_text(size = 11),
      strip.background = element_blank(),
      legend.text = element_text(size = 10),
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank(),
      legend.position = "bottom"
    )

  safe_zone <- str_replace_all(zone_name, "[^A-Za-z0-9]+", "_")

  output_file <- file.path(
    figure_dir,
    paste0(
      "CalCurCEAS_baleen_validated_hourly_acoustic_scene_",
      safe_zone,
      ".png"
    )
  )

  ggsave(
    filename = output_file,
    plot = p_zone,
    width = 14,
    height = max(5, 2.4 * length(dep_list)),
    units = "in",
    dpi = 300,
    bg = "white",
    limitsize = FALSE
  )

  cat("Created: ", output_file, "\n", sep = "")
}
