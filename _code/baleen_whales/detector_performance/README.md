# DeepAcoustics Detector Performance

This folder contains the reproducible code used to calculate final CalCurCEAS 2024 baleen-whale DeepAcoustics detector-performance summaries.

The workflow starts from deployment-level true-positive, false-positive, and false-negative counts for the six focal call types.

## Supporting input

```text
_data/BaleenWhales/
CalCurCEAS_DeepAcoustics_performance_counts_by_deployment_calltype.csv
```

This file contains one row per deployment and call type with:

- deployment
- call type
- original detections
- reviewed truth calls
- true positives
- false positives
- false negatives

The final dataset contains 20 evaluated deployments and six focal call types.

## Script

Run from the repository root:

```text
_code/baleen_whales/detector_performance/
deep_acoustics_detector_performance_summary.R
```

Run in R with:

```r
source(
  "_code/baleen_whales/detector_performance/deep_acoustics_detector_performance_summary.R"
)
```

## Outputs

The script creates two final public data products:

```text
supplement/BaleenWhales/
CalCurCEAS_DeepAcoustics_performance_by_deployment_calltype.csv
CalCurCEAS_DeepAcoustics_performance_pooled_by_calltype.csv
```

### Deployment-level performance

`CalCurCEAS_DeepAcoustics_performance_by_deployment_calltype.csv`

Contains deployment-specific precision, recall, and F1 scores calculated from the underlying TP, FP, and FN counts.

### Pooled performance

`CalCurCEAS_DeepAcoustics_performance_pooled_by_calltype.csv`

Contains detector performance pooled across all evaluated deployments for each call type.

Pooled metrics are calculated from summed TP, FP, and FN counts:

```text
Precision = TP / (TP + FP)

Recall = TP / (TP + FN)

F1 = 2 × Precision × Recall / (Precision + Recall)
```

Pooled performance is not calculated by averaging deployment-level precision, recall, or F1 values.

## Focal call types

The six focal classes are:

- Blue A
- Blue B
- Blue D
- Fin 20 Hz
- Fin 40 Hz
- Sei DS

## Retention criterion

Call types with pooled F1 scores of at least 0.80 were retained for the secondary automated call-level analyses.

Retained classes:

- Blue A
- Blue B
- Fin 20 Hz

Classes not retained for call-level magnitude analyses:

- Blue D
- Fin 40 Hz
- Sei DS

## Final pooled performance

| Call type | Precision | Recall | F1 | Retained |
|---|---:|---:|---:|---|
| Blue A | 0.996 | 0.946 | 0.970 | Yes |
| Blue B | 0.988 | 0.675 | 0.802 | Yes |
| Blue D | 0.963 | 0.587 | 0.729 | No |
| Fin 20 Hz | 0.973 | 0.749 | 0.846 | Yes |
| Fin 40 Hz | 0.583 | 0.061 | 0.110 | No |
| Sei DS | 0.864 | 0.481 | 0.618 | No |

## Quality checks

The script checks that:

- 20 deployments are present
- all six expected call types are present
- each deployment-call-type combination occurs only once
- `original_detections = true_positive + false_positive`
- `reviewed_truth_calls = true_positive + false_negative`
- final pooled precision, recall, F1, and retention decisions match the final report values

## R dependencies

The script requires:

```r
library(tidyverse)
```

For archival reproducibility, package versions used for the final run can be recorded with:

```r
sessionInfo()
```

## Notes

- Run the script from the repository root.
- `_data/BaleenWhales/` contains the supporting TP/FP/FN source data used to calculate the final products.
- `supplement/BaleenWhales/` contains the final reusable detector-performance CSVs.
- Deployment-level and pooled metrics are regenerated directly from the underlying counts.
- The pooled product is the basis for the final call-type retention decisions used in downstream automated call-activity analyses.
