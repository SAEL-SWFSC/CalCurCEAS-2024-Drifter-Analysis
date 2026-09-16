# Baleen Whale Supplementary Data Products

This folder contains the final reusable baleen-whale data products and detector file from the CalCurCEAS 2024 drifting-recorder analysis.

The products in this directory are intended to be the primary public-facing files for reuse, interpretation, and reproducibility. Supporting or upstream analysis inputs are stored under `_data/BaleenWhales/`, derived report-oriented outputs are stored under `output/BaleenWhales/`, and final rendered figures are stored under `_figs/BaleenWhales/`.

## Data products

| File | Description | Reproducible workflow |
|---|---|---|
| `CalCurCEAS_baleen_validated_hourly_presence_absence.csv` | Final manually validated hourly presence/absence dataset for blue, fin, and sei whale call types. Includes hourly position, geographic zone, usable/excluded effort information, call-type presence, and species-level presence. | `_code/baleen_whales/validated_hourly_occurrence/` |
| `CalCurCEAS_baleen_retained_automated_hourly_call_activity.csv` | Final hourly automated call-activity dataset for call classes retained for secondary analyses: Blue A, Blue B, and Fin 20 Hz. Includes hourly position, geographic zone, exact usable acoustic effort, and retained detection counts. | `_code/baleen_whales/relative_call_activity/` |
| `CalCurCEAS_baleen_environmental_hourly.csv` | Final hourly environmental-analysis dataset containing drifter position, geographic zone, retained automated call counts, bathymetry, SST, chlorophyll-a, phytoplankton carbon, POC, concurrent NPP CAFE, and lagged NPP CAFE values. | `_code/baleen_whales/environmental_analysis/` |
| `CalCurCEAS_DeepAcoustics_performance_by_deployment_calltype.csv` | Deployment-level detector-performance results for the six focal call types, including TP, FP, FN, precision, recall, and F1 score. | `_code/baleen_whales/detector_performance/` |
| `CalCurCEAS_DeepAcoustics_performance_pooled_by_calltype.csv` | Detector performance pooled across novel CalCurCEAS deployments by call type. Pooled precision, recall, and F1 are calculated from summed TP, FP, and FN counts rather than by averaging deployment-level metrics. | `_code/baleen_whales/detector_performance/` |
| `CalCurCEAS_environmental_summary_by_zone_activity.csv` | Regional environmental summaries for Blue A/B and Fin 20 Hz high-call, low-call, and no-call categories in Northern, Central, and Southern California. Includes medians and interquartile ranges for the environmental variables used in the exploratory analysis. | `_code/baleen_whales/environmental_analysis/` |

## Final DeepAcoustics detector

The final detector is:

```text
CalCurCEAS_PacificLF_TinyYOLO_final.mat
```

Associated documentation is provided in:

```text
CalCurCEAS_PacificLF_TinyYOLO_final_README.md
```

The model is the final **Network 17, 400-Hz TinyYOLO** detector used for the low-frequency baleen-whale analysis. It targets:

- Blue A
- Blue B
- Blue D
- Fin 20 Hz
- Fin 40 Hz
- Sei DS

The model README documents training-data provenance, the 0.5 detection-confidence threshold, DeepAcoustics/MATLAB requirements, detector-performance limitations, and downstream call-class retention decisions.

## Analysis products and terminology

### Validated hourly occurrence

Hourly occurrence results are based on manually validated hourly presence/absence bins.

A **Validated Analysis Hour** is an hourly bin retained for the final validated occurrence analysis after acoustic-data exclusions.

A **call-positive hour** contains at least one retained detection of the call type or species being summarized.

### Relative automated call activity

Secondary automated call-level analyses use only call classes with pooled F1 scores of at least 0.80:

- Blue A
- Blue B
- Fin 20 Hz

Detection counts are interpreted as indices of **relative acoustic activity within call type**. They should not be interpreted as whale abundance or density.

### Environmental analysis

The environmental analysis is exploratory. High/low/no-call categories are calculated separately by call metric and California geographic zone using the regional 75th percentile of hourly call count, including zero-call hours.

The finalized environmental dataset contains 4,025 hourly bins. It is slightly smaller than the retained automated call-activity dataset because the environmental workflow excluded some hourly bins that overlapped flagged unusable-acoustic-data periods, including bins for which the call-activity workflow retained a partially usable portion of the hour.

## Geographic zones

Hourly geographic-zone assignments follow:

| Geographic zone | Latitude definition |
|---|---|
| Columbia River | 45.0 to 47.1°N |
| Oregon | 42.0 to <45.0°N |
| Northern California | 38.33 to <42.0°N |
| Central California | 34.5 to <38.33°N |
| Southern California | 32.47 to <34.5°N |

For regional hourly summaries, the geographic zone is assigned from the hourly recorder position rather than from a single deployment-level zone.

## Related code

Reproducible baleen-whale workflows are organized under:

```text
_code/baleen_whales/
```

Current workflow folders include:

```text
validated_hourly_occurrence/
relative_call_activity/
detector_performance/
environmental_analysis/
```

Each workflow folder contains its own `README.md` with inputs, outputs, run order, QA checks, and analysis-specific notes.

## Related figures

Final rendered figures are stored under:

```text
_figs/BaleenWhales/
```

The four-panel Southern California environmental context figure was prepared separately in QGIS and is retained as a final figure product rather than regenerated by the R environmental-analysis workflow.

## Notes

- Files in this folder are final public-facing products rather than raw or temporary intermediates.
- CSV products use descriptive field names and are intended to be usable independently of report table or figure numbering.
- Supporting inputs required to regenerate these products are kept outside `supplement/BaleenWhales/` when they are not themselves final reusable products.
