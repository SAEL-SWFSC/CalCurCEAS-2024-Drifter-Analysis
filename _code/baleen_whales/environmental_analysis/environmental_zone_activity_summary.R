# CalCurCEAS 2024
# Environmental summaries by geographic zone and call-activity category.
# Run from the repository root.

library(tidyverse)

input_file <- file.path(
  "supplement",
  "BaleenWhales",
  "CalCurCEAS_baleen_environmental_hourly.csv"
)

output_file <- file.path(
  "supplement",
  "BaleenWhales",
  "CalCurCEAS_environmental_summary_by_zone_activity.csv"
)

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
  "geographic_zone",
  "blue_a_detections",
  "blue_b_detections",
  "fin_20hz_detections",
  "gebco_bathymetry_m",
  "sst_c",
  "chlorophyll_a",
  "phytoplankton_carbon",
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

if (n_distinct(env_hourly$deployment) != 20) {
  stop("Expected 20 analyzed deployments.")
}

duplicate_hours <- env_hourly %>%
  count(deployment, hour_start_utc) %>%
  filter(n != 1)

if (nrow(duplicate_hours) > 0) {
  stop("Duplicate deployment-hour rows found.")
}

california_zones <- c(
  "Northern California",
  "Central California",
  "Southern California"
)

environmental_variables <- tribble(
  ~environmental_variable,   ~units,
  "gebco_bathymetry_m",      "m",
  "sst_c",                    "deg_C",
  "chlorophyll_a",            "mg_m-3",
  "phytoplankton_carbon",     "mg_m-3",
  "poc",                      "mg_m-3",
  "npp_concurrent",           "mg_C_m-2_d-1",
  "npp_lag_30d",              "mg_C_m-2_d-1",
  "npp_lag_60d",              "mg_C_m-2_d-1",
  "npp_lag_90d",              "mg_C_m-2_d-1",
  "npp_lag_120d",             "mg_C_m-2_d-1"
)

activity_data <- env_hourly %>%
  filter(geographic_zone %in% california_zones) %>%
  mutate(
    `Blue A/B` = blue_a_detections + blue_b_detections,
    `Fin 20 Hz` = fin_20hz_detections
  ) %>%
  select(
    deployment,
    hour_start_utc,
    geographic_zone,
    all_of(environmental_variables$environmental_variable),
    `Blue A/B`,
    `Fin 20 Hz`
  ) %>%
  pivot_longer(
    cols = c(`Blue A/B`, `Fin 20 Hz`),
    names_to = "call_metric",
    values_to = "call_count"
  ) %>%
  group_by(call_metric, geographic_zone) %>%
  mutate(
    high_call_threshold = as.numeric(
      quantile(call_count, 0.75, na.rm = TRUE, type = 7)
    ),
    activity_category = case_when(
      call_count == 0 ~ "no_call",
      call_count >= high_call_threshold ~ "high_call",
      call_count > 0 & call_count < high_call_threshold ~ "low_call",
      TRUE ~ NA_character_
    )
  ) %>%
  ungroup()

expected_thresholds <- tribble(
  ~call_metric, ~geographic_zone,          ~high_call_threshold,
  "Blue A/B",   "Northern California",     5,
  "Blue A/B",   "Central California",      9,
  "Blue A/B",   "Southern California",     8,
  "Fin 20 Hz",  "Northern California",     8,
  "Fin 20 Hz",  "Central California",      11,
  "Fin 20 Hz",  "Southern California",     15
)

observed_thresholds <- activity_data %>%
  distinct(
    call_metric,
    geographic_zone,
    high_call_threshold
  ) %>%
  arrange(call_metric, geographic_zone)

threshold_qa <- observed_thresholds %>%
  full_join(
    expected_thresholds,
    by = c("call_metric", "geographic_zone"),
    suffix = c("_observed", "_expected")
  )

if (
  nrow(threshold_qa) != nrow(expected_thresholds) ||
  any(
    threshold_qa$high_call_threshold_observed !=
      threshold_qa$high_call_threshold_expected
  )
) {
  stop("Call-activity thresholds do not match the final analysis.")
}

summary_output <- activity_data %>%
  pivot_longer(
    cols = all_of(environmental_variables$environmental_variable),
    names_to = "environmental_variable",
    values_to = "environmental_value"
  ) %>%
  left_join(
    environmental_variables,
    by = "environmental_variable"
  ) %>%
  group_by(
    call_metric,
    geographic_zone,
    activity_category,
    high_call_threshold,
    environmental_variable,
    units
  ) %>%
  summarise(
    category_hours = n(),
    n_available = sum(!is.na(environmental_value)),
    median = median(environmental_value, na.rm = TRUE),
    q25 = quantile(
      environmental_value,
      0.25,
      na.rm = TRUE,
      type = 7
    ),
    q75 = quantile(
      environmental_value,
      0.75,
      na.rm = TRUE,
      type = 7
    ),
    .groups = "drop"
  ) %>%
  mutate(
    activity_category = factor(
      activity_category,
      levels = c("high_call", "low_call", "no_call")
    ),
    geographic_zone = factor(
      geographic_zone,
      levels = california_zones
    ),
    call_metric = factor(
      call_metric,
      levels = c("Blue A/B", "Fin 20 Hz")
    ),
    environmental_variable = factor(
      environmental_variable,
      levels = environmental_variables$environmental_variable
    )
  ) %>%
  arrange(
    call_metric,
    geographic_zone,
    activity_category,
    environmental_variable
  ) %>%
  mutate(
    across(
      c(
        call_metric,
        geographic_zone,
        activity_category,
        environmental_variable
      ),
      as.character
    )
  ) %>%
  select(
    call_metric,
    geographic_zone,
    activity_category,
    high_call_threshold,
    category_hours,
    environmental_variable,
    units,
    n_available,
    median,
    q25,
    q75
  )

if (nrow(summary_output) != 180) {
  stop("Expected 180 environmental summary rows.")
}

expected_category_hours <- tribble(
  ~call_metric, ~geographic_zone,      ~activity_category, ~category_hours,
  "Blue A/B",   "Northern California", "high_call",        177,
  "Blue A/B",   "Northern California", "low_call",         286,
  "Blue A/B",   "Northern California", "no_call",          194,
  "Blue A/B",   "Central California",  "high_call",        258,
  "Blue A/B",   "Central California",  "low_call",         483,
  "Blue A/B",   "Central California",  "no_call",          215,
  "Blue A/B",   "Southern California", "high_call",        381,
  "Blue A/B",   "Southern California", "low_call",         601,
  "Blue A/B",   "Southern California", "no_call",          415,
  "Fin 20 Hz",  "Northern California", "high_call",        165,
  "Fin 20 Hz",  "Northern California", "low_call",         173,
  "Fin 20 Hz",  "Northern California", "no_call",          319,
  "Fin 20 Hz",  "Central California",  "high_call",        245,
  "Fin 20 Hz",  "Central California",  "low_call",         390,
  "Fin 20 Hz",  "Central California",  "no_call",          321,
  "Fin 20 Hz",  "Southern California", "high_call",        357,
  "Fin 20 Hz",  "Southern California", "low_call",         730,
  "Fin 20 Hz",  "Southern California", "no_call",          310
)

category_qa <- summary_output %>%
  distinct(
    call_metric,
    geographic_zone,
    activity_category,
    category_hours
  ) %>%
  full_join(
    expected_category_hours,
    by = c(
      "call_metric",
      "geographic_zone",
      "activity_category"
    ),
    suffix = c("_observed", "_expected")
  )

if (
  nrow(category_qa) != nrow(expected_category_hours) ||
  any(
    category_qa$category_hours_observed !=
      category_qa$category_hours_expected
  )
) {
  stop("Activity-category hour totals do not match the final analysis.")
}

write_csv(
  summary_output,
  output_file,
  na = ""
)

cat(
  "Created:\n",
  output_file,
  "\n",
  sep = ""
)
