# Environmental Analysis

This folder contains the reproducible code used for the CalCurCEAS 2024 baleen-whale exploratory environmental analyses.

The quantitative workflow starts from the finalized hourly environmental dataset:

```text
supplement/BaleenWhales/
CalCurCEAS_baleen_environmental_hourly.csv
```

This dataset contains hourly drifter position, retained automated call counts, geographic-zone assignment, and the environmental values used in the analysis.

## Scripts

Run all scripts from the repository root.

### `environmental_zone_activity_summary.R`

Recreates the final environmental summaries by geographic zone and call-activity category.

Run with:

```r
source(
  "_code/baleen_whales/environmental_analysis/environmental_zone_activity_summary.R"
)
```

Output:

```text
supplement/BaleenWhales/
CalCurCEAS_environmental_summary_by_zone_activity.csv
```

The script classifies hourly bins separately for Blue A/B and Fin 20 Hz within each California geographic zone using the 75th percentile of hourly call count, calculated across all hours in that zone including zero-call hours.

Activity categories are:

- `high_call`: call count greater than or equal to the regional 75th-percentile threshold
- `low_call`: call count greater than zero but below the threshold
- `no_call`: zero retained detections

Regional thresholds are:

| Call metric | Northern California | Central California | Southern California |
|---|---:|---:|---:|
| Blue A/B | 5 | 9 | 8 |
| Fin 20 Hz | 8 | 11 | 15 |

The summary includes medians and interquartile ranges for:

- GEBCO bathymetry
- sea-surface temperature (SST)
- chlorophyll-a
- phytoplankton carbon
- particulate organic carbon (POC)
- concurrent NPP CAFE
- NPP CAFE lagged by 30, 60, 90, and 120 days

### `california_environmental_boxplots.R`

Creates one combined environmental boxplot figure for each California geographic zone.

Run with:

```r
source(
  "_code/baleen_whales/environmental_analysis/california_environmental_boxplots.R"
)
```

Outputs:

```text
_figs/BaleenWhales/
CalCurCEAS_northern_california_environmental_boxplots.png
CalCurCEAS_central_california_environmental_boxplots.png
CalCurCEAS_southern_california_environmental_boxplots.png
```

Each figure contains:

- Panel A: Fin 20 Hz
- Panel B: Blue A/B

Within each species panel, the figure shows:

- NPP CAFE at concurrent, 30-day, 60-day, 90-day, and 120-day lags
- SST
- chlorophyll-a
- particulate organic carbon

The boxplot workflow follows the original analysis logic: quartiles and whiskers are calculated from the untransformed data, while NPP CAFE, chlorophyll-a, and POC are displayed on logarithmic y-axes.


### `full_environmental_distribution_boxplots.R`

Creates the coastwide environmental-distribution figure comparing hours with retained Fin 20 Hz detections, retained Blue A/B detections, and no retained detections.

Run with:

```r
source(
  "_code/baleen_whales/environmental_analysis/full_environmental_distribution_boxplots.R"
)
```

Output:

```text
_figs/BaleenWhales/
CalCurCEAS_Full_Environmental_Distribution_box_plots.png
```

The script uses the finalized hourly environmental dataset and displays distributions for:

- GEBCO bathymetric depth
- sea-surface temperature (SST)
- chlorophyll-a
- phytoplankton carbon
- particulate organic carbon (POC)
- concurrent NPP CAFE

The Fin 20 Hz and Blue A/B groups are not mutually exclusive: an hour containing both retained call types contributes to both groups. `No retained calls` indicates an hour with zero retained Fin 20 Hz detections and zero retained Blue A/B detections. Sample sizes shown beneath each boxplot are calculated after excluding missing values for the environmental variable being plotted.

## Environmental-analysis dataset

The finalized environmental dataset contains 4,025 hourly bins across 20 deployments.

This is slightly smaller than the retained automated call-activity dataset because the environmental workflow excluded 47 hourly bins that overlapped flagged unusable-acoustic-data periods. Some of those bins contained a partially usable portion of acoustic recording and were retained in the relative call-activity workflow using exact usable minutes.

Therefore:

- the environmental analysis uses the finalized 4,025-bin dataset
- the relative call-activity analysis may retain partially usable portions of some additional hourly bins
- the environmental dataset and its outputs should not be expected to contain exactly the same number of hourly rows as the call-activity dataset

The existing environmental results were produced from the 4,025-bin dataset, so that dataset is retained as the authoritative input for this workflow.

## Geographic scope

Regional high/low/no-call environmental comparisons are provided for:

- Northern California
- Central California
- Southern California

The California geographic-zone definitions are:

| Geographic zone | Latitude definition |
|---|---|
| Northern California | 38.33 to <42.0 degrees N |
| Central California | 34.5 to <38.33 degrees N |
| Southern California | <34.5 degrees N |

## Spatial environmental context figure

The four-panel Southern California environmental context figure used in the final report was prepared separately in QGIS by Liz using the environmental raster products described in the report, bathymetric contours, drifter positions, and hourly Fin 20 Hz detections.

The figure contains environmental context panels for:

- chlorophyll-a
- MUR SST
- particulate organic carbon
- NPP CAFE

The original QGIS mapping workflow and source raster layers are not reproduced in this repository. The spatial map is retained as a final figure product for provenance and reference, while the hourly environmental values used in the quantitative analyses are provided in:

```text
supplement/BaleenWhales/
CalCurCEAS_baleen_environmental_hourly.csv
```

The final QGIS-produced figure is stored as:

```text
_figs/BaleenWhales/
Fin_Nov24_Dec01_ChA_SST_POC_NPP_Day0.png
```

This figure is illustrative and is not generated by the R scripts in this folder.

## R dependencies

The environmental summary script requires:

```r
library(tidyverse)
```

The California boxplot script requires:

```r
library(tidyverse)
library(patchwork)
library(cowplot)
library(grid)
```

The full environmental-distribution boxplot script requires:

```r
library(tidyverse)
library(patchwork)
```

For archival reproducibility, package versions used for the final run can be recorded with:

```r
sessionInfo()
```

## Repository organization

```text
supplement/BaleenWhales/
```

contains final reusable environmental data products.

```text
_data/BaleenWhales/
```

contains supporting or upstream analysis inputs that are not intended as final public data products.

```text
output/BaleenWhales/
```

contains derived numerical results when needed.

```text
_figs/BaleenWhales/
```

contains final rendered environmental figures, including the California regional boxplots, Appendix Figure E-1, and the QGIS-produced spatial context figure.

## Notes

- Run R scripts from the repository root.
- The environmental analysis is exploratory and does not imply abundance or density.
- Call-activity categories are defined separately by call metric and geographic zone.
- Blue A/B combines retained Blue A and Blue B automated detections.
- Fin 20 Hz uses retained automated Fin 20 Hz detections.
- The final hourly environmental dataset is the authoritative input for the reproducible quantitative workflow.
