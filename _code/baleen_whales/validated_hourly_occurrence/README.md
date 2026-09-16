# Validated Hourly Occurrence

This folder contains the reproducible code used to generate the final CalCurCEAS 2024 baleen-whale validated hourly occurrence summaries and figures.

The workflow starts from the finalized, analysis-ready hourly dataset:

```text
supplement/BaleenWhales/
CalCurCEAS_baleen_validated_hourly_presence_absence.csv
```

That dataset already contains the final hourly positions, geographic-zone assignments, data-quality exclusions, call-type presence fields, and species-level presence fields. The scripts in this folder do not recreate those preprocessing steps.

## Scripts

Run all scripts from the repository root.

### `species_hourly_occurrence_products.R`

Creates the species-level validated hourly occurrence summary and figure for blue, fin, and sei whales by geographic zone.

Outputs:

```text
output/BaleenWhales/
CalCurCEAS_baleen_validated_hourly_occurrence_by_geographic_zone.csv

_figs/BaleenWhales/
CalCurCEAS_baleen_validated_hourly_occurrence_by_geographic_zone.png
```

This workflow corresponds to the species-level regional occurrence summary presented in the BOEM report.

### `call_type_hourly_occurrence_figures.R`

Creates validated hourly occurrence figures by call type for:

- Blue A, Blue B, and Blue D calls
- Fin 20 Hz and Fin 40 Hz calls

Outputs:

```text
_figs/BaleenWhales/
CalCurCEAS_blue_call_type_hourly_occurrence_by_geographic_zone.png
CalCurCEAS_fin_call_type_hourly_occurrence_by_geographic_zone.png
```

### `regional_acoustic_scenes.R`

Creates one validated hourly acoustic-scene figure for each geographic zone using `PAMscapes`.

Outputs:

```text
_figs/BaleenWhales/
CalCurCEAS_baleen_validated_hourly_acoustic_scene_Columbia_River.png
CalCurCEAS_baleen_validated_hourly_acoustic_scene_Oregon.png
CalCurCEAS_baleen_validated_hourly_acoustic_scene_Northern_California.png
CalCurCEAS_baleen_validated_hourly_acoustic_scene_Central_California.png
CalCurCEAS_baleen_validated_hourly_acoustic_scene_Southern_California.png
```

In these figures, pale blue-gray shading indicates periods with no effort in the target geographic zone and dark gray shading indicates hours excluded because of unusable acoustic data or recording gaps.

## Run order

The scripts are independent once the finalized hourly dataset is present. A typical run order is:

```r
source("_code/baleen_whales/validated_hourly_occurrence/species_hourly_occurrence_products.R")

source("_code/baleen_whales/validated_hourly_occurrence/call_type_hourly_occurrence_figures.R")

source("_code/baleen_whales/validated_hourly_occurrence/regional_acoustic_scenes.R")
```

## Geographic zones

Each hourly bin is assigned using the recorder's hourly latitude:

| Geographic zone | Latitude definition |
|---|---|
| Columbia River | 45.0 to 47.1 degrees N |
| Oregon | 42.0 to <45.0 degrees N |
| Northern California | 38.33 to <42.0 degrees N |
| Central California | 34.5 to <38.33 degrees N |
| Southern California | <34.5 degrees N |

A deployment may therefore contribute hours to more than one geographic zone.

## Validated-hour exclusions

The finalized hourly dataset already incorporates the exclusions used for the validated hourly occurrence analysis. The scripts retain only rows where `validated_analysis_hour` is `TRUE`.

The final dataset contains:

- 4,266 Validated Analysis Hours
- 230 hours excluded for unusable acoustic data
- 4 hours excluded for confirmed recording gaps

Deployments 003, 010, and 019 are excluded from the validated hourly occurrence analysis. Deployments 008 and 014 remain included because hourly occurrence was fully manually validated.

## Final validated occurrence totals

The scripts include QA checks against the final validated dataset totals:

| Metric | Final total |
|---|---:|
| Validated Analysis Hours | 4,266 |
| Blue whale positive hours | 2,447 |
| Fin whale positive hours | 2,633 |
| Sei whale positive hours | 486 |
| Blue A positive hours | 427 |
| Blue B positive hours | 2,311 |
| Blue D positive hours | 274 |
| Fin 20 Hz positive hours | 2,605 |
| Fin 40 Hz positive hours | 84 |

If these totals change unexpectedly, the relevant script stops rather than silently creating a different result.

## R dependencies

The species- and call-type occurrence scripts require:

```r
library(tidyverse)
```

The regional acoustic-scene workflow additionally requires:

```r
library(PAMscapes)
```

For archival reproducibility, the R and package versions used for the final run can be recorded with:

```r
sessionInfo()
packageVersion("tidyverse")
packageVersion("PAMscapes")
```

## Notes

- All scripts use repository-relative paths and should be run from the repository root.
- Geographic zones are read directly from the finalized hourly dataset and are not recalculated in these scripts.
- Data-quality exclusions are also read directly from the finalized hourly dataset and are not reapplied downstream.
- Final machine-readable data products are stored under `supplement/BaleenWhales/`.
- Derived numerical results are stored under `output/BaleenWhales/`.
- Final rendered figures are stored under `_figs/BaleenWhales/`.
