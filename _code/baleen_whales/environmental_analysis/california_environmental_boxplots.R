# CalCurCEAS 2024
# California environmental boxplots converted from the original Python workflow.
# Run from the repository root.

library(tidyverse)
library(patchwork)
library(cowplot)
library(grid)

input_file <- file.path(
  "supplement",
  "BaleenWhales",
  "CalCurCEAS_baleen_environmental_hourly.csv"
)

figure_dir <- file.path("_figs", "BaleenWhales")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(input_file)) {
  stop("Input file not found: ", input_file)
}

env_hourly <- read_csv(
  input_file,
  show_col_types = FALSE
)

required_cols <- c(
  "deployment",
  "hour_start_utc",
  "latitude",
  "geographic_zone",
  "blue_a_detections",
  "blue_b_detections",
  "fin_20hz_detections",
  "sst_c",
  "chlorophyll_a",
  "poc",
  "npp_concurrent",
  "npp_lag_30d",
  "npp_lag_60d",
  "npp_lag_90d",
  "npp_lag_120d"
)

missing_cols <- setdiff(required_cols, names(env_hourly))

if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

if (nrow(env_hourly) != 4025) {
  stop("Expected 4,025 environmental hourly rows.")
}

california_zones <- c(
  "Northern California",
  "Central California",
  "Southern California"
)

zone_labels <- c(
  "Northern California" = "Northern CA (38.33–42.0°N)",
  "Central California" = "Central CA (34.5–38.33°N)",
  "Southern California" = "Southern CA (32.47–34.5°N)"
)

zone_output_files <- c(
  "Northern California" = file.path(
    figure_dir,
    "CalCurCEAS_northern_california_environmental_boxplots.png"
  ),
  "Central California" = file.path(
    figure_dir,
    "CalCurCEAS_central_california_environmental_boxplots.png"
  ),
  "Southern California" = file.path(
    figure_dir,
    "CalCurCEAS_southern_california_environmental_boxplots.png"
  )
)

expected_zone_hours <- c(
  "Northern California" = 657,
  "Central California" = 956,
  "Southern California" = 1397
)

expected_thresholds <- tribble(
  ~call_metric, ~geographic_zone,          ~threshold,
  "Fin 20 Hz",  "Northern California",      8,
  "Fin 20 Hz",  "Central California",      11,
  "Fin 20 Hz",  "Southern California",     15,
  "Blue A/B",   "Northern California",      5,
  "Blue A/B",   "Central California",       9,
  "Blue A/B",   "Southern California",      8
)

expected_counts <- tribble(
  ~call_metric, ~geographic_zone,          ~activity_category, ~n,
  "Fin 20 Hz",  "Northern California",     "High",             165,
  "Fin 20 Hz",  "Northern California",     "Low",              173,
  "Fin 20 Hz",  "Northern California",     "No calls",         319,
  "Fin 20 Hz",  "Central California",      "High",             245,
  "Fin 20 Hz",  "Central California",      "Low",              390,
  "Fin 20 Hz",  "Central California",      "No calls",         321,
  "Fin 20 Hz",  "Southern California",     "High",             357,
  "Fin 20 Hz",  "Southern California",     "Low",              730,
  "Fin 20 Hz",  "Southern California",     "No calls",         310,
  "Blue A/B",   "Northern California",     "High",             177,
  "Blue A/B",   "Northern California",     "Low",              286,
  "Blue A/B",   "Northern California",     "No calls",         194,
  "Blue A/B",   "Central California",      "High",             258,
  "Blue A/B",   "Central California",      "Low",              483,
  "Blue A/B",   "Central California",      "No calls",         215,
  "Blue A/B",   "Southern California",     "High",             381,
  "Blue A/B",   "Southern California",     "Low",              601,
  "Blue A/B",   "Southern California",     "No calls",         415
)

activity_levels <- c("High", "Low", "No calls")

fin_colors <- c(
  High = "#DC143C",
  Low = "#4682B4",
  `No calls` = "#BEBEBE"
)

blue_colors <- c(
  High = "#FF8C00",
  Low = "#008080",
  `No calls` = "#BEBEBE"
)

base_theme <- theme_bw(base_size = 11) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.major.y = element_line(
      colour = "grey80",
      linewidth = 0.35
    ),
    panel.grid.minor.y = element_line(
      colour = "grey90",
      linewidth = 0.25
    ),
    plot.title = element_text(
      face = "bold",
      hjust = 0.5,
      size = 12
    ),
    axis.title = element_text(size = 10),
    axis.text.x = element_text(size = 9),
    axis.text.y = element_text(size = 8.5)
  )

box_stats <- function(x) {

  x <- x[is.finite(x)]

  if (length(x) == 0) {
    return(
      tibble(
        ymin = NA_real_,
        lower = NA_real_,
        middle = NA_real_,
        upper = NA_real_,
        ymax = NA_real_,
        n = 0L
      )
    )
  }

  q <- quantile(
    x,
    probs = c(0.25, 0.50, 0.75),
    type = 7,
    names = FALSE
  )

  iqr <- q[3] - q[1]

  lower_fence <- q[1] - 1.5 * iqr
  upper_fence <- q[3] + 1.5 * iqr

  tibble(
    ymin = min(x[x >= lower_fence]),
    lower = q[1],
    middle = q[2],
    upper = q[3],
    ymax = max(x[x <= upper_fence]),
    n = length(x)
  )
}

log_axis_breaks <- function(limits) {

  limits <- limits[is.finite(limits) & limits > 0]

  if (length(limits) < 2) {
    return(NULL)
  }

  low_exp <- floor(log10(min(limits)))
  high_exp <- ceiling(log10(max(limits)))

  candidates <- as.vector(
    outer(
      c(1, 2, 3, 4, 6),
      10^(low_exp:high_exp)
    )
  )

  sort(
    unique(
      candidates[
        candidates >= min(limits) &
          candidates <= max(limits)
      ]
    )
  )
}

log_axis_labels <- function(x) {

  exponent <- floor(log10(x))
  coefficient <- x / (10^exponent)

  labels <- ifelse(
    abs(coefficient - 1) < 1e-8,
    paste0("10^", exponent),
    paste0(
      format(round(coefficient, 6), trim = TRUE, scientific = FALSE),
      "%*%10^",
      exponent
    )
  )

  parse(text = labels)
}

make_activity_data <- function(data, call_metric, zone_name) {

  call_count <- if (call_metric == "Fin 20 Hz") {
    data$fin_20hz_detections
  } else if (call_metric == "Blue A/B") {
    data$blue_a_detections + data$blue_b_detections
  } else {
    stop("Unknown call metric: ", call_metric)
  }

  threshold <- as.numeric(
    quantile(
      call_count,
      probs = 0.75,
      na.rm = TRUE,
      type = 7
    )
  )

  expected_threshold <- expected_thresholds %>%
    filter(
      .data$call_metric == .env$call_metric,
      .data$geographic_zone == .env$zone_name
    ) %>%
    pull(threshold)

  if (length(expected_threshold) != 1 || threshold != expected_threshold) {
    stop(
      call_metric,
      " threshold for ",
      zone_name,
      " does not match the final analysis."
    )
  }

  output <- data %>%
    mutate(
      call_count = call_count,
      activity_category = case_when(
        call_count == 0 ~ "No calls",
        call_count >= threshold ~ "High",
        call_count > 0 & call_count < threshold ~ "Low",
        TRUE ~ NA_character_
      ),
      activity_category = factor(
        activity_category,
        levels = activity_levels
      )
    )

  observed_counts <- output %>%
    count(activity_category, name = "n") %>%
    mutate(
      call_metric = call_metric,
      geographic_zone = zone_name,
      activity_category = as.character(activity_category)
    )

  expected_counts_this <- expected_counts %>%
    filter(
      .data$call_metric == .env$call_metric,
      .data$geographic_zone == .env$zone_name
    )

  qa <- observed_counts %>%
    full_join(
      expected_counts_this,
      by = c(
        "call_metric",
        "geographic_zone",
        "activity_category"
      ),
      suffix = c("_observed", "_expected")
    )

  if (
    nrow(qa) != 3 ||
    any(qa$n_observed != qa$n_expected)
  ) {
    stop(
      call_metric,
      " category counts for ",
      zone_name,
      " do not match the final analysis."
    )
  }

  list(
    data = output,
    threshold = threshold,
    category_counts = setNames(
      qa$n_observed,
      qa$activity_category
    )
  )
}

make_npp_plot <- function(
  data,
  threshold,
  category_counts,
  colors
) {

  npp_long <- data %>%
    select(
      activity_category,
      npp_concurrent,
      npp_lag_30d,
      npp_lag_60d,
      npp_lag_90d,
      npp_lag_120d
    ) %>%
    pivot_longer(
      cols = starts_with("npp_"),
      names_to = "npp_lag",
      values_to = "value"
    ) %>%
    mutate(
      npp_lag = recode(
        npp_lag,
        npp_concurrent = "0d",
        npp_lag_30d = "30d",
        npp_lag_60d = "60d",
        npp_lag_90d = "90d",
        npp_lag_120d = "120d"
      ),
      npp_lag = factor(
        npp_lag,
        levels = c("0d", "30d", "60d", "90d", "120d")
      )
    ) %>%
    filter(
      !is.na(value),
      value > 0
    )

  lag_levels <- levels(npp_long$npp_lag)

  npp_stats <- npp_long %>%
    group_by(npp_lag, activity_category) %>%
    group_modify(
      ~ box_stats(.x$value)
    ) %>%
    ungroup() %>%
    mutate(
      lag_index = match(
        as.character(npp_lag),
        lag_levels
      ),
      x = lag_index + case_when(
        activity_category == "High" ~ -0.27,
        activity_category == "Low" ~ 0,
        activity_category == "No calls" ~ 0.27
      )
    )

  log_min <- log10(min(npp_stats$ymin, na.rm = TRUE))
  log_max <- log10(max(npp_stats$ymax, na.rm = TRUE))
  log_span <- log_max - log_min

  axis_lower <- log_min - 0.05 * log_span
  axis_upper <- log_max + 0.05 * log_span

  label_y <- 10^(
    axis_lower +
      0.035 * (axis_upper - axis_lower)
  )

  npp_stats <- npp_stats %>%
    mutate(
      label_y = label_y
    )

  legend_labels <- c(
    High = paste0(
      "High (≥",
      threshold,
      ", n=",
      category_counts["High"],
      ")"
    ),
    Low = paste0(
      "Low (0<x<",
      threshold,
      ", n=",
      category_counts["Low"],
      ")"
    ),
    `No calls` = paste0(
      "No calls (n=",
      category_counts["No calls"],
      ")"
    )
  )

  y_limits <- 10^c(axis_lower, axis_upper)
  y_breaks <- log_axis_breaks(y_limits)

  ggplot(
    npp_stats,
    aes(
      x = x,
      fill = activity_category,
      group = interaction(npp_lag, activity_category)
    )
  ) +
    geom_boxplot(
      aes(
        ymin = ymin,
        lower = lower,
        middle = middle,
        upper = upper,
        ymax = ymax
      ),
      stat = "identity",
      width = 0.24,
      alpha = 0.7,
      colour = "grey25",
      linewidth = 0.45
    ) +
    geom_segment(
      aes(
        x = x - 0.07,
        xend = x + 0.07,
        y = ymin,
        yend = ymin
      ),
      colour = "grey25",
      linewidth = 0.45,
      inherit.aes = FALSE
    ) +
    geom_segment(
      aes(
        x = x - 0.07,
        xend = x + 0.07,
        y = ymax,
        yend = ymax
      ),
      colour = "grey25",
      linewidth = 0.45,
      inherit.aes = FALSE
    ) +
    geom_text(
      aes(
        y = label_y,
        label = paste0("n=", n),
        colour = activity_category
      ),
      size = 2.6,
      fontface = "bold",
      show.legend = FALSE
    ) +
    scale_x_continuous(
      breaks = seq_along(lag_levels),
      labels = lag_levels,
      expand = expansion(add = 0.55)
    ) +
    scale_y_log10(
      limits = y_limits,
      breaks = y_breaks,
      labels = log_axis_labels,
      expand = c(0, 0)
    ) +
    scale_fill_manual(
      values = colors,
      breaks = activity_levels,
      labels = legend_labels,
      drop = FALSE
    ) +
    scale_colour_manual(
      values = colors,
      guide = "none",
      drop = FALSE
    ) +
    labs(
      title = "NPP CAFE by Lag",
      x = "NPP CAFE lag",
      y = expression(
        "NPP CAFE (mg C " * m^{-2} * " " * d^{-1} * ")"
      ),
      fill = NULL
    ) +
    base_theme +
    theme(
      legend.position = c(0.015, 0.985),
      legend.justification = c(0, 1),
      legend.background = element_rect(
        fill = "white",
        colour = "grey75"
      ),
      legend.key.height = unit(0.38, "cm"),
      legend.key.width = unit(0.48, "cm"),
      legend.text = element_text(size = 8.2)
    )
}

make_variable_plot <- function(
  data,
  variable,
  title,
  y_label,
  colors,
  log_scale = FALSE
) {

  plot_data <- data %>%
    transmute(
      activity_category,
      value = .data[[variable]]
    ) %>%
    filter(!is.na(value))

  if (log_scale) {
    plot_data <- plot_data %>%
      filter(value > 0)
  }

  stats <- plot_data %>%
    group_by(activity_category) %>%
    group_modify(
      ~ box_stats(.x$value)
    ) %>%
    ungroup() %>%
    mutate(
      x = match(
        as.character(activity_category),
        activity_levels
      )
    )

  axis_labels <- setNames(
    paste0(
      activity_levels,
      "\n(n=",
      stats$n[match(activity_levels, as.character(stats$activity_category))],
      ")"
    ),
    activity_levels
  )

  p <- ggplot(
    stats,
    aes(
      x = x,
      fill = activity_category,
      group = activity_category
    )
  ) +
    geom_boxplot(
      aes(
        ymin = ymin,
        lower = lower,
        middle = middle,
        upper = upper,
        ymax = ymax
      ),
      stat = "identity",
      width = 0.50,
      alpha = 0.7,
      colour = "grey25",
      linewidth = 0.45
    ) +
    geom_segment(
      aes(
        x = x - 0.14,
        xend = x + 0.14,
        y = ymin,
        yend = ymin
      ),
      colour = "grey25",
      linewidth = 0.45,
      inherit.aes = FALSE
    ) +
    geom_segment(
      aes(
        x = x - 0.14,
        xend = x + 0.14,
        y = ymax,
        yend = ymax
      ),
      colour = "grey25",
      linewidth = 0.45,
      inherit.aes = FALSE
    ) +
    scale_x_continuous(
      breaks = 1:3,
      labels = axis_labels[activity_levels],
      expand = expansion(add = 0.55)
    ) +
    scale_fill_manual(
      values = colors,
      breaks = activity_levels,
      drop = FALSE
    ) +
    labs(
      title = title,
      x = NULL,
      y = y_label
    ) +
    base_theme +
    theme(
      legend.position = "none"
    )

  if (log_scale) {

    y_min <- min(stats$ymin, na.rm = TRUE)
    y_max <- max(stats$ymax, na.rm = TRUE)

    y_breaks <- log_axis_breaks(c(y_min, y_max))

    p <- p +
      scale_y_log10(
        breaks = y_breaks,
        labels = log_axis_labels
      )
  }

  p
}

make_species_figure <- function(
  activity_result,
  zone_name,
  species_title,
  colors
) {

  data <- activity_result$data

  npp_plot <- make_npp_plot(
    data = data,
    threshold = activity_result$threshold,
    category_counts = activity_result$category_counts,
    colors = colors
  )

  sst_plot <- make_variable_plot(
    data = data,
    variable = "sst_c",
    title = "SST",
    y_label = expression("SST (" * degree * "C)"),
    colors = colors,
    log_scale = FALSE
  )

  chl_plot <- make_variable_plot(
    data = data,
    variable = "chlorophyll_a",
    title = "Chlorophyll-a",
    y_label = expression("Chl-a (mg " * m^{-3} * ")"),
    colors = colors,
    log_scale = TRUE
  )

  poc_plot <- make_variable_plot(
    data = data,
    variable = "poc",
    title = "Particulate Organic Carbon",
    y_label = expression("POC (mg " * m^{-3} * ")"),
    colors = colors,
    log_scale = TRUE
  )

  bottom_row <- sst_plot | chl_plot | poc_plot

  npp_plot / bottom_row +
    plot_layout(
      heights = c(1.1, 1)
    ) +
    plot_annotation(
      title = paste0(
        species_title,
        " — High vs. Low vs. No Calls — ",
        zone_labels[[zone_name]]
      ),
      theme = theme(
        plot.title = element_text(
          face = "plain",
          hjust = 0.5,
          size = 12
        )
      )
    )
}

zone_data <- env_hourly %>%
  filter(geographic_zone %in% california_zones)

observed_zone_hours <- zone_data %>%
  count(geographic_zone, name = "n")

if (!all(
  observed_zone_hours$n ==
    expected_zone_hours[observed_zone_hours$geographic_zone]
)) {
  stop("California-zone row counts do not match the final environmental analysis.")
}

created_files <- character()

for (zone_name in california_zones) {

  zone_subset <- zone_data %>%
    filter(geographic_zone == zone_name)

  fin_result <- make_activity_data(
    zone_subset,
    "Fin 20 Hz",
    zone_name
  )

  blue_result <- make_activity_data(
    zone_subset,
    "Blue A/B",
    zone_name
  )

  fin_plot <- make_species_figure(
    fin_result,
    zone_name,
    "Fin 20 Hz",
    fin_colors
  )

  blue_plot <- make_species_figure(
    blue_result,
    zone_name,
    "Blue A/B",
    blue_colors
  )

  combined_plot <- cowplot::plot_grid(
    fin_plot,
    blue_plot,
    ncol = 2,
    labels = c("A", "B"),
    label_fontface = "bold",
    label_size = 22,
    label_x = 0.01,
    label_y = 0.995,
    hjust = 0,
    vjust = 1,
    rel_widths = c(1, 1),
    align = "h",
    axis = "tb"
  )

  output_file <- zone_output_files[[zone_name]]

  ggsave(
    filename = output_file,
    plot = combined_plot,
    width = 18,
    height = 9,
    units = "in",
    dpi = 300,
    bg = "white"
  )

  created_files <- c(
    created_files,
    output_file
  )
}

cat(
  "Created:\n",
  paste(created_files, collapse = "\n"),
  "\n",
  sep = ""
)
