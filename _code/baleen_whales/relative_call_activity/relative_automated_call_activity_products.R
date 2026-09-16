# CalCurCEAS 2024
# Relative automated call activity by geographic zone.
# Run from the repository root.

library(tidyverse)

input_file <- file.path(
  "supplement",
  "BaleenWhales",
  "CalCurCEAS_baleen_retained_automated_hourly_call_activity.csv"
)

output_dir <- file.path("output", "BaleenWhales")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

output_file <- file.path(
  output_dir,
  "CalCurCEAS_baleen_relative_automated_call_activity_by_geographic_zone.csv"
)

zone_levels <- c(
  "Columbia River",
  "Oregon",
  "Northern California",
  "Central California",
  "Southern California"
)

if (!file.exists(input_file)) {
  stop("Input file not found: ", input_file)
}

hourly <- read_csv(
  input_file,
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
  "geographic_zone",
  "usable_audio_minutes",
  "blue_a_count",
  "blue_b_count",
  "fin_20hz_count"
)

missing_cols <- setdiff(required_cols, names(hourly))

if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

hourly <- hourly %>%
  mutate(
    geographic_zone = factor(geographic_zone, levels = zone_levels)
  )

if (any(is.na(hourly$geographic_zone))) {
  stop("At least one row lacks a recognized geographic zone.")
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

count_values <- hourly %>%
  select(blue_a_count, blue_b_count, fin_20hz_count) %>%
  unlist(use.names = FALSE)

if (any(is.na(count_values)) || any(count_values < 0)) {
  stop("Call counts contain missing or negative values.")
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

summary_by_zone <- hourly %>%
  group_by(geographic_zone) %>%
  summarise(
    usable_recording_hours = sum(usable_audio_minutes) / 60,
    blue_a_count = sum(blue_a_count),
    blue_b_count = sum(blue_b_count),
    fin_20hz_count = sum(fin_20hz_count),
    .groups = "drop"
  ) %>%
  mutate(
    blue_a_detections_per_hour = blue_a_count / usable_recording_hours,
    blue_b_detections_per_hour = blue_b_count / usable_recording_hours,
    fin_20hz_detections_per_hour = fin_20hz_count / usable_recording_hours,
    geographic_zone = as.character(geographic_zone)
  )

total_row <- tibble(
  geographic_zone = "TOTAL",
  usable_recording_hours = sum(hourly$usable_audio_minutes) / 60,
  blue_a_count = sum(hourly$blue_a_count),
  blue_b_count = sum(hourly$blue_b_count),
  fin_20hz_count = sum(hourly$fin_20hz_count),
  blue_a_detections_per_hour = blue_a_count / usable_recording_hours,
  blue_b_detections_per_hour = blue_b_count / usable_recording_hours,
  fin_20hz_detections_per_hour = fin_20hz_count / usable_recording_hours
)

write_csv(
  bind_rows(summary_by_zone, total_row),
  output_file,
  na = ""
)

cat("Created:\n", output_file, "\n", sep = "")
