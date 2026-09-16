# CalCurCEAS 2024
# Spatial automated call-activity magnitude maps.
# Run from the repository root.

library(tidyverse)
library(sf)
library(maps)
library(rnaturalearth)
library(cowplot)

hourly_file <- file.path(
  "supplement",
  "BaleenWhales",
  "CalCurCEAS_baleen_retained_automated_hourly_call_activity.csv"
)

bathy_file <- file.path(
  "_data",
  "BaleenWhales",
  "CalCurCEAS_bathymetry_contours.gpkg"
)

figure_dir <- file.path("_figs", "BaleenWhales")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

blue_map_file <- file.path(
  figure_dir,
  "CalCurCEAS_blue_automated_call_activity_magnitude_map.png"
)

fin_map_file <- file.path(
  figure_dir,
  "CalCurCEAS_fin_20hz_automated_call_activity_magnitude_map.png"
)

combined_map_file <- file.path(
  figure_dir,
  "CalCurCEAS_baleen_automated_call_activity_magnitude_maps.png"
)

map_xlim <- c(-130.26, -118.65)
map_ylim <- c(30.35, 47.36)
track_color <- "#5A22E0"

if (!file.exists(hourly_file)) {
  stop("Input file not found: ", hourly_file)
}

if (!file.exists(bathy_file)) {
  stop("Input file not found: ", bathy_file)
}

hourly <- read_csv(
  hourly_file,
  col_types = cols(
    hour_start_utc = col_datetime(),
    .default = col_guess()
  ),
  show_col_types = FALSE
)

required_cols <- c(
  "deployment",
  "hour_start_utc",
  "latitude",
  "longitude",
  "usable_audio_minutes",
  "blue_a_count",
  "blue_b_count",
  "fin_20hz_count"
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

if (any(hourly$usable_audio_minutes <= 0)) {
  stop("Usable audio minutes must be greater than zero.")
}

expected_totals <- c(
  usable_recording_hours = 4030.6,
  blue_a_count = 1353,
  blue_b_count = 15874,
  fin_20hz_count = 45529
)

observed_totals <- c(
  usable_recording_hours = round(sum(hourly$usable_audio_minutes) / 60, 1),
  blue_a_count = sum(hourly$blue_a_count),
  blue_b_count = sum(hourly$blue_b_count),
  fin_20hz_count = sum(hourly$fin_20hz_count)
)

if (!all(observed_totals == expected_totals)) {
  stop(
    "Automated call-activity totals do not match the final report values. Observed: ",
    paste(names(observed_totals), observed_totals, collapse = "; ")
  )
}

tracks <- hourly %>%
  arrange(deployment, hour_start_utc)

contours <- st_read(
  bathy_file,
  layer = "Bathymetry_1000m",
  quiet = TRUE
) %>%
  st_make_valid() %>%
  filter(ELEV %in% c(-1000, -2000, -3000, -4000, -5000)) %>%
  mutate(
    bathymetry = factor(
      ELEV,
      levels = c(-1000, -2000, -3000, -4000, -5000),
      labels = c("-1,000", "-2,000", "-3,000", "-4,000", "-5,000")
    )
  )

bathy_colors <- c(
  "-1,000" = "#B5B7AF",
  "-2,000" = "#898A84",
  "-3,000" = "#5D5E5A",
  "-4,000" = "#31312F",
  "-5,000" = "#050505"
)

country_outline <- ne_countries(
  scale = "medium",
  country = c("United States of America", "Mexico", "Canada"),
  returnclass = "sf"
) %>%
  st_transform(4326)

us_states <- map_data("state")

state_labels <- tribble(
  ~label,       ~longitude, ~latitude,
  "Washington", -121.05,    46.55,
  "Oregon",     -120.95,    43.75,
  "Nevada",     -118.95,    40.15,
  "California", -120.75,    38.25
)

blue <- hourly %>%
  transmute(
    latitude,
    longitude,
    count = blue_a_count + blue_b_count,
    size_class = cut(
      blue_a_count + blue_b_count,
      breaks = c(-Inf, 10, 20, 30, 40, 52),
      labels = c("0 - 10", "10 - 20", "20 - 30", "30 - 40", "40 - 52"),
      right = TRUE
    )
  ) %>%
  filter(count > 0)

fin <- hourly %>%
  transmute(
    latitude,
    longitude,
    count = fin_20hz_count,
    size_class = cut(
      fin_20hz_count,
      breaks = c(-Inf, 30, 60, 90, 120, 150, 180, 220),
      labels = c(
        "0 - 30",
        "30 - 60",
        "60 - 90",
        "90 - 120",
        "120 - 150",
        "150 - 180",
        "180 - 220"
      ),
      right = TRUE
    )
  ) %>%
  filter(count > 0)

add_map_annotations <- function(p) {
  p +
    annotate(
      "segment",
      x = -129.45,
      xend = -129.45,
      y = 45.95,
      yend = 46.95,
      linewidth = 0.8,
      arrow = arrow(length = grid::unit(0.16, "inches"))
    ) +
    annotate(
      "text",
      x = -129.45,
      y = 47.12,
      label = "N",
      fontface = "bold",
      size = 4.3
    ) +
    annotate(
      "rect",
      xmin = -121.25,
      xmax = -120.46,
      ymin = 30.72,
      ymax = 30.92,
      fill = "black",
      colour = "black",
      linewidth = 0.25
    ) +
    annotate(
      "rect",
      xmin = -120.46,
      xmax = -119.67,
      ymin = 30.72,
      ymax = 30.92,
      fill = "white",
      colour = "black",
      linewidth = 0.25
    ) +
    annotate(
      "text",
      x = c(-121.25, -120.46, -119.67),
      y = 31.03,
      label = c("0", "75", "150 km"),
      size = 3.2
    ) +
    annotate(
      "text",
      x = -130.02,
      y = 30.55,
      label = "Coordinate System: WGS84",
      hjust = 0,
      fontface = "bold",
      size = 3.2
    )
}

make_base_panel <- function(
  point_data,
  point_shape,
  point_fill,
  size_values
) {

  p <- ggplot() +
    geom_sf(
      data = country_outline,
      fill = "white",
      colour = "grey55",
      linewidth = 0.25
    ) +
    geom_polygon(
      data = us_states,
      aes(x = long, y = lat, group = group),
      fill = "#958B8B",
      colour = "black",
      linewidth = 0.25
    ) +
    geom_sf(
      data = contours,
      aes(colour = bathymetry),
      linewidth = 0.30,
      fill = NA,
      show.legend = FALSE
    ) +
    scale_colour_manual(
      values = bathy_colors,
      guide = "none",
      drop = FALSE
    ) +
    geom_path(
      data = tracks,
      aes(x = longitude, y = latitude, group = deployment),
      colour = track_color,
      linewidth = 0.55,
      alpha = 1
    ) +
    geom_point(
      data = point_data,
      aes(x = longitude, y = latitude, size = size_class),
      shape = point_shape,
      fill = point_fill,
      colour = "black",
      stroke = 0.30,
      alpha = 0.88,
      show.legend = FALSE
    ) +
    scale_size_manual(
      values = size_values,
      guide = "none",
      drop = FALSE
    ) +
    geom_text(
      data = state_labels,
      aes(x = longitude, y = latitude, label = label),
      fontface = "bold",
      colour = "#2A2828",
      size = 4.5
    ) +
    coord_sf(
      xlim = map_xlim,
      ylim = map_ylim,
      expand = FALSE,
      crs = st_crs(4326),
      default_crs = st_crs(4326)
    ) +
    theme_bw(base_size = 11) +
    theme(
      axis.title = element_blank(),
      panel.grid.major = element_line(
        colour = "grey82",
        linewidth = 0.30
      ),
      panel.grid.minor = element_blank(),
      panel.border = element_rect(
        colour = "black",
        fill = NA,
        linewidth = 0.7
      ),
      axis.text = element_text(
        size = 10,
        colour = "black"
      ),
      plot.margin = margin(6, 6, 6, 6)
    )

  add_map_annotations(p)
}

build_combined_legend <- function(
  size_labels,
  size_values,
  size_title,
  point_fill,
  point_shape = 23
) {

  y_points <- seq(0.76, 0.30, length.out = length(size_labels))
  y_bathy <- seq(0.74, 0.38, length.out = length(bathy_colors))

  g <- cowplot::ggdraw() +
    cowplot::draw_grob(
      grid::rectGrob(
        x = 0.5,
        y = 0.5,
        width = 1,
        height = 1,
        gp = grid::gpar(
          fill = "white",
          col = "grey55",
          lwd = 0.8
        )
      )
    ) +
    cowplot::draw_label(
      size_title,
      x = 0.05,
      y = 0.89,
      hjust = 0,
      vjust = 0.5,
      size = 9
    ) +
    cowplot::draw_label(
      "Bathymetry (m)",
      x = 0.59,
      y = 0.89,
      hjust = 0,
      vjust = 0.5,
      size = 9
    )

  for (i in seq_along(size_labels)) {
    symbol_mm <- 1.2 + 0.55 * size_values[i]

    g <- g +
      cowplot::draw_grob(
        grid::pointsGrob(
          x = grid::unit(0.11, "npc"),
          y = grid::unit(y_points[i], "npc"),
          pch = point_shape,
          size = grid::unit(symbol_mm, "mm"),
          gp = grid::gpar(
            fill = point_fill,
            col = "black",
            lwd = 0.6
          )
        )
      ) +
      cowplot::draw_label(
        size_labels[i],
        x = 0.18,
        y = y_points[i],
        hjust = 0,
        vjust = 0.5,
        size = 8
      )
  }

  for (i in seq_along(bathy_colors)) {
    g <- g +
      cowplot::draw_grob(
        grid::segmentsGrob(
          x0 = grid::unit(0.60, "npc"),
          x1 = grid::unit(0.71, "npc"),
          y0 = grid::unit(y_bathy[i], "npc"),
          y1 = grid::unit(y_bathy[i], "npc"),
          gp = grid::gpar(
            col = unname(bathy_colors[i]),
            lwd = 1.3
          )
        )
      ) +
      cowplot::draw_label(
        names(bathy_colors)[i],
        x = 0.75,
        y = y_bathy[i],
        hjust = 0,
        vjust = 0.5,
        size = 8
      )
  }

  g +
    cowplot::draw_grob(
      grid::segmentsGrob(
        x0 = grid::unit(0.12, "npc"),
        x1 = grid::unit(0.24, "npc"),
        y0 = grid::unit(0.11, "npc"),
        y1 = grid::unit(0.11, "npc"),
        gp = grid::gpar(
          col = track_color,
          lwd = 2
        )
      )
    ) +
    cowplot::draw_label(
      "CalCurCEAS Drifter Tracks",
      x = 0.28,
      y = 0.11,
      hjust = 0,
      vjust = 0.5,
      size = 8
    )
}

compose_map <- function(
  base_plot,
  legend_box,
  legend_x = 0.20,
  legend_y = 0.085,
  legend_width = 0.35,
  legend_height = 0.145
) {
  cowplot::ggdraw(base_plot) +
    cowplot::draw_plot(
      legend_box,
      x = legend_x,
      y = legend_y,
      width = legend_width,
      height = legend_height
    )
}

blue_sizes <- c(
  "0 - 10" = 1.0,
  "10 - 20" = 2.75,
  "20 - 30" = 4.5,
  "30 - 40" = 6.25,
  "40 - 52" = 8.0
)

fin_sizes <- c(
  "0 - 30" = 1.0,
  "30 - 60" = 2.16667,
  "60 - 90" = 3.33333,
  "90 - 120" = 4.5,
  "120 - 150" = 5.66667,
  "150 - 180" = 6.83333,
  "180 - 220" = 8.0
)

blue_base <- make_base_panel(
  point_data = blue,
  point_shape = 23,
  point_fill = "#D97814",
  size_values = blue_sizes
)

fin_base <- make_base_panel(
  point_data = fin,
  point_shape = 23,
  point_fill = "#2FB62A",
  size_values = fin_sizes
)

blue_legend <- build_combined_legend(
  size_labels = names(blue_sizes),
  size_values = unname(blue_sizes),
  size_title = "Blue whale A and B calls",
  point_fill = "#D97814"
)

fin_legend <- build_combined_legend(
  size_labels = names(fin_sizes),
  size_values = unname(fin_sizes),
  size_title = "Fin Whale 20Hz",
  point_fill = "#2FB62A"
)

blue_plot <- compose_map(
  blue_base,
  blue_legend
)

fin_plot <- compose_map(
  fin_base,
  fin_legend
)

combined_plot <- cowplot::plot_grid(
  blue_plot,
  fin_plot,
  ncol = 2,
  labels = c("A", "B"),
  label_fontface = "bold",
  label_size = 20
)

ggsave(
  filename = blue_map_file,
  plot = blue_plot,
  width = 8.5,
  height = 11,
  units = "in",
  dpi = 300,
  bg = "white"
)

ggsave(
  filename = fin_map_file,
  plot = fin_plot,
  width = 8.5,
  height = 11,
  units = "in",
  dpi = 300,
  bg = "white"
)

ggsave(
  filename = combined_map_file,
  plot = combined_plot,
  width = 16,
  height = 10.5,
  units = "in",
  dpi = 300,
  bg = "white"
)

cat(
  "Created:\n",
  blue_map_file, "\n",
  fin_map_file, "\n",
  combined_map_file, "\n",
  sep = ""
)
