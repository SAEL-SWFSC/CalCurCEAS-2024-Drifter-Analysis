# CalCurCEAS 2024
# DeepAcoustics detector performance products.
# Run from the repository root.

library(tidyverse)

input_file <- file.path(
  "_data",
  "BaleenWhales",
  "CalCurCEAS_DeepAcoustics_performance_counts_by_deployment_calltype.csv"
)

output_dir <- file.path("supplement", "BaleenWhales")

deployment_output <- file.path(
  output_dir,
  "CalCurCEAS_DeepAcoustics_performance_by_deployment_calltype.csv"
)

pooled_output <- file.path(
  output_dir,
  "CalCurCEAS_DeepAcoustics_performance_pooled_by_calltype.csv"
)

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(input_file)) {
  stop("Input file not found: ", input_file)
}

performance_counts <- read_csv(
  input_file,
  show_col_types = FALSE
)

required_cols <- c(
  "deployment",
  "call_type",
  "original_detections",
  "reviewed_truth_calls",
  "true_positive",
  "false_positive",
  "false_negative"
)

missing_cols <- setdiff(required_cols, names(performance_counts))

if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

call_levels <- c(
  "Blue A",
  "Blue B",
  "Blue D",
  "Fin 20 Hz",
  "Fin 40 Hz",
  "Sei DS"
)

if (nrow(performance_counts) != 120) {
  stop("Expected 120 deployment-call-type rows.")
}

if (n_distinct(performance_counts$deployment) != 20) {
  stop("Expected 20 evaluated deployments.")
}

if (!setequal(unique(performance_counts$call_type), call_levels)) {
  stop("Unexpected call types in detector-performance input.")
}

duplicate_rows <- performance_counts %>%
  count(deployment, call_type) %>%
  filter(n != 1)

if (nrow(duplicate_rows) > 0) {
  stop("Duplicate deployment-call-type rows found.")
}

if (any(
  performance_counts$original_detections !=
    performance_counts$true_positive +
    performance_counts$false_positive
)) {
  stop("original_detections does not equal TP + FP for all rows.")
}

if (any(
  performance_counts$reviewed_truth_calls !=
    performance_counts$true_positive +
    performance_counts$false_negative
)) {
  stop("reviewed_truth_calls does not equal TP + FN for all rows.")
}

safe_ratio <- function(numerator, denominator) {
  if_else(
    denominator > 0,
    numerator / denominator,
    NA_real_
  )
}

deployment_performance <- performance_counts %>%
  mutate(
    precision_raw = safe_ratio(
      true_positive,
      true_positive + false_positive
    ),
    recall_raw = safe_ratio(
      true_positive,
      true_positive + false_negative
    ),
    f1_raw = if_else(
      !is.na(precision_raw) &
        !is.na(recall_raw) &
        (precision_raw + recall_raw) > 0,
      2 * precision_raw * recall_raw /
        (precision_raw + recall_raw),
      NA_real_
    ),
    precision = round(precision_raw, 3),
    recall = round(recall_raw, 3),
    f1_score = round(f1_raw, 3)
  ) %>%
  select(
    deployment,
    call_type,
    original_detections,
    reviewed_truth_calls,
    true_positive,
    false_positive,
    false_negative,
    precision,
    recall,
    f1_score
  ) %>%
  mutate(
    call_type = factor(call_type, levels = call_levels)
  ) %>%
  arrange(deployment, call_type) %>%
  mutate(
    call_type = as.character(call_type)
  )

pooled_performance <- performance_counts %>%
  group_by(call_type) %>%
  summarise(
    deployments_evaluated = n_distinct(deployment),
    deployments_with_reference_calls =
      sum(reviewed_truth_calls > 0),
    original_detections = sum(original_detections),
    reviewed_truth_calls = sum(reviewed_truth_calls),
    true_positive = sum(true_positive),
    false_positive = sum(false_positive),
    false_negative = sum(false_negative),
    .groups = "drop"
  ) %>%
  mutate(
    precision_raw = safe_ratio(
      true_positive,
      true_positive + false_positive
    ),
    recall_raw = safe_ratio(
      true_positive,
      true_positive + false_negative
    ),
    f1_raw = if_else(
      !is.na(precision_raw) &
        !is.na(recall_raw) &
        (precision_raw + recall_raw) > 0,
      2 * precision_raw * recall_raw /
        (precision_raw + recall_raw),
      NA_real_
    ),
    precision = round(precision_raw, 3),
    recall = round(recall_raw, 3),
    f1_score = round(f1_raw, 3),
    retained_for_call_level_analysis = f1_raw >= 0.80
  ) %>%
  select(
    call_type,
    deployments_evaluated,
    deployments_with_reference_calls,
    original_detections,
    reviewed_truth_calls,
    true_positive,
    false_positive,
    false_negative,
    precision,
    recall,
    f1_score,
    retained_for_call_level_analysis
  ) %>%
  mutate(
    call_type = factor(call_type, levels = call_levels)
  ) %>%
  arrange(call_type) %>%
  mutate(
    call_type = as.character(call_type)
  )

expected_pooled <- tribble(
  ~call_type,   ~precision, ~recall, ~f1_score, ~retained,
  "Blue A",          0.996,   0.946,     0.970, TRUE,
  "Blue B",          0.988,   0.675,     0.802, TRUE,
  "Blue D",          0.963,   0.587,     0.729, FALSE,
  "Fin 20 Hz",       0.973,   0.749,     0.846, TRUE,
  "Fin 40 Hz",       0.583,   0.061,     0.110, FALSE,
  "Sei DS",          0.864,   0.481,     0.618, FALSE
)

qa <- pooled_performance %>%
  select(
    call_type,
    precision,
    recall,
    f1_score,
    retained_for_call_level_analysis
  ) %>%
  left_join(
    expected_pooled,
    by = "call_type"
  )

if (any(
  qa$precision.x != qa$precision.y |
    qa$recall.x != qa$recall.y |
    qa$f1_score.x != qa$f1_score.y |
    qa$retained_for_call_level_analysis != qa$retained
)) {
  stop("Pooled detector-performance QA values do not match final report values.")
}

write_csv(
  deployment_performance,
  deployment_output,
  na = ""
)

write_csv(
  pooled_performance,
  pooled_output,
  na = ""
)

cat(
  "Created:\n",
  deployment_output, "\n",
  pooled_output, "\n",
  sep = ""
)
