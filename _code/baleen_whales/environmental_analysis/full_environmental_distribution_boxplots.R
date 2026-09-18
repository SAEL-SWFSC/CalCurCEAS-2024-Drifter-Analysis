# CalCurCEAS 2024
# Appendix E - Figure E-1
# Full environmental-variable distributions by acoustic activity.
# Run from the repository root.

library(tidyverse)
library(patchwork)

# ------------------------------------------------------------
# 1. Input and output paths
# ------------------------------------------------------------

input_file <- file.path(
  "supplement",
  "BaleenWhales",
  "CalCurCEAS_baleen_environmental_hourly.csv"
)

figure_dir <- file.path("_figs", "BaleenWhales")

output_file <- file.path(
  figure_dir,
  "CalCurCEAS_Full_Environmental_Distribution_box_plots.png"
)

dir.create(
  figure_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

if (!file.exists(input_file)) {
  stop("Input file not found: ", input_file)
}

# ------------------------------------------------------------
# 2. Read and validate the finalized environmental dataset
# ------------------------------------------------------------

dat <- read_csv(
  input_file,
  show_col_types = FALSE
)

required_cols <- c(
  "deployment",
  "hour_start_utc",
  "blue_a_detections",
  "blue_b_detections",
  "fin_20hz_detections",
  "gebco_bathymetry_m",
  "sst_c",
  "chlorophyll_a",
  "phytoplankton_carbon",
  "poc",
  "npp_concurrent"
)

missing_cols <- setdiff(
  required_cols,
  names(dat)
)

if (length(missing_cols) > 0) {
  stop(
    "Missing required columns: ",
    paste(missing_cols, collapse = ", ")
  )
}

if (nrow(dat) != 4025) {
  stop("Expected 4,025 environmental hourly rows.")
}

if (n_distinct(dat$deployment) != 20) {
  stop("Expected 20 analyzed deployments.")
}

# Create the retained-call metrics used for Figure E-1.
dat <- dat %>%
  mutate(
    Blue_A_B = blue_a_detections + blue_b_detections,
    Fin_20Hz = fin_20hz_detections
  )

# ------------------------------------------------------------
# 3. Create the three acoustic-activity groups
#
# NOTE:
# Fin 20 Hz and Blue A/B groups are NOT mutually exclusive.
# An hour containing both call types occurs in both groups.
#
# "No retained calls" = zero Fin 20 Hz AND zero Blue A/B.
# ------------------------------------------------------------

fin_dat <- dat %>%
  filter(Fin_20Hz > 0) %>%
  mutate(Call_group = "Fin 20 Hz present")

blue_dat <- dat %>%
  filter(Blue_A_B > 0) %>%
  mutate(Call_group = "Blue A/B present")

no_call_dat <- dat %>%
  filter(
    Fin_20Hz == 0,
    Blue_A_B == 0
  ) %>%
  mutate(Call_group = "No retained calls")

plot_dat <- bind_rows(
  fin_dat,
  blue_dat,
  no_call_dat
) %>%
  mutate(
    Call_group = factor(
      Call_group,
      levels = c(
        "Fin 20 Hz present",
        "Blue A/B present",
        "No retained calls"
      )
    )
  )

# ------------------------------------------------------------
# 4. Function for making each boxplot
# ------------------------------------------------------------

make_env_plot <- function(
  data,
  variable,
  panel,
  title,
  ylab,
  log_scale = FALSE
) {

  # Sample size for each group after excluding missing values
  # for the environmental variable being plotted.
  n_dat <- data %>%
    filter(!is.na(.data[[variable]])) %>%
    count(Call_group, name = "n") %>%
    mutate(
      x_label = paste0(
        Call_group,
        "\n(n=", scales::comma(n), ")"
      )
    )

  # Add sample-size labels to plotting data.
  pdat <- data %>%
    filter(!is.na(.data[[variable]])) %>%
    left_join(
      n_dat,
      by = "Call_group"
    ) %>%
    mutate(
      x_label = factor(
        x_label,
        levels = n_dat$x_label
      )
    )

  p <- ggplot(
    pdat,
    aes(
      x = x_label,
      y = .data[[variable]]
    )
  ) +
    geom_boxplot(
      width = 0.6,
      outlier.shape = NA
    ) +
    labs(
      title = paste0(panel, ". ", title),
      x = NULL,
      y = ylab
    ) +
    theme_bw(base_size = 10) +
    theme(
      plot.title = element_text(
        face = "bold",
        size = 11
      ),
      axis.text.x = element_text(
        size = 8.5
      ),
      axis.title.y = element_text(
        size = 9.5
      ),
      panel.grid.minor = element_blank()
    )

  if (log_scale) {
    p <- p +
      scale_y_log10()
  }

  p
}

# ------------------------------------------------------------
# 5. Create the six panels
# ------------------------------------------------------------

pA <- make_env_plot(
  data = plot_dat,
  variable = "gebco_bathymetry_m",
  panel = "A",
  title = "Bathymetric depth",
  ylab = "Depth (m; negative below sea level)",
  log_scale = FALSE
)

pB <- make_env_plot(
  data = plot_dat,
  variable = "sst_c",
  panel = "B",
  title = "Sea surface temperature",
  ylab = "SST (°C)",
  log_scale = FALSE
)

pC <- make_env_plot(
  data = plot_dat,
  variable = "chlorophyll_a",
  panel = "C",
  title = "Chlorophyll-a",
  ylab = expression(
    paste("Chlorophyll-a (mg ", m^{-3}, ")")
  ),
  log_scale = TRUE
)

pD <- make_env_plot(
  data = plot_dat,
  variable = "phytoplankton_carbon",
  panel = "D",
  title = "Phytoplankton carbon",
  ylab = expression(
    paste("Phytoplankton carbon (mg ", m^{-3}, ")")
  ),
  log_scale = TRUE
)

pE <- make_env_plot(
  data = plot_dat,
  variable = "poc",
  panel = "E",
  title = "Particulate organic carbon",
  ylab = expression(
    paste("POC (mg ", m^{-3}, ")")
  ),
  log_scale = TRUE
)

pF <- make_env_plot(
  data = plot_dat,
  variable = "npp_concurrent",
  panel = "F",
  title = "Net primary productivity",
  ylab = expression(
    paste("NPP (mg C ", m^{-2}, " ", d^{-1}, ")")
  ),
  log_scale = TRUE
)

# ------------------------------------------------------------
# 6. Combine and save Figure E-1
# ------------------------------------------------------------

fig_E1 <- (
  pA + pB +
    pC + pD +
    pE + pF
) +
  plot_layout(
    ncol = 2
  )

fig_E1

ggsave(
  filename = output_file,
  plot = fig_E1,
  width = 10,
  height = 12,
  units = "in",
  dpi = 300,
  bg = "white"
)

cat(
  "Created:\n",
  output_file,
  "\n",
  sep = ""
)
