# Relative Automated Call Activity

This folder contains the reproducible code used to generate the final CalCurCEAS 2024 baleen-whale relative automated call-activity summaries and spatial magnitude maps.

The workflow starts from the finalized hourly product:

```text
supplement/BaleenWhales/
CalCurCEAS_baleen_retained_automated_hourly_call_activity.csv
```

That dataset contains only hours retained for the final automated call-level analysis and includes hourly position, usable acoustic effort, and retained automated counts for Blue A, Blue B, and Fin 20 Hz calls.

## Scripts

Run all scripts from the repository root.

### `relative_automated_call_activity_products.R`

Summarizes retained automated call activity by geographic zone using exact usable acoustic recording effort.

Output:

```text
output/BaleenWhales/
CalCurCEAS_baleen_relative_automated_call_activity_by_geographic_zone.csv
```

The output reports, by geographic zone and overall:

- usable recording hours
- Blue A detections
- Blue B detections
- Fin 20 Hz detections
- detections per recording hour for each retained call type

### `spacial_automated_call_activity_magnitude_maps.R`

Creates the final spatial magnitude maps for:

- Blue A + Blue B combined
- Fin 20 Hz

Inputs:

```text
supplement/BaleenWhales/
CalCurCEAS_baleen_retained_automated_hourly_call_activity.csv

_data/BaleenWhales/
CalCurCEAS_bathymetry_contours.gpkg
```

The GeoPackage is used for the 1,000-m bathymetric contour layers. Drifter tracks are reconstructed directly from the hourly positions in the final call-activity CSV.

Outputs:

```text
_figs/BaleenWhales/
CalCurCEAS_blue_automated_call_activity_magnitude_map.png
CalCurCEAS_fin_20hz_automated_call_activity_magnitude_map.png
CalCurCEAS_baleen_automated_call_activity_magnitude_maps.png
```

The first two files are the primary standalone map products. The combined image is provided for convenience.

## Run order

```r
source(
  "_code/baleen_whales/relative_call_activity/relative_automated_call_activity_products.R"
)

source(
  "_code/baleen_whales/relative_call_activity/spacial_automated_call_activity_magnitude_maps.R"
)
```

The two scripts are otherwise independent once the finalized hourly call-activity CSV is present.

## Analysis scope

Only call classes meeting the final pooled detector-performance retention criterion were used for this secondary automated analysis:

- Blue A
- Blue B
- Fin 20 Hz

Blue D, Fin 40 Hz, and Sei DS were not retained for call-level magnitude analyses.

Deployments used for detector training were excluded from the automated call-level analysis. The finalized hourly CSV already reflects those exclusions, so the public scripts do not reapply them.

## Effort and final totals

Usable recording effort is based on exact `usable_audio_minutes`, so partial hours contribute their actual usable duration.

The scripts include QA checks against the final totals:

| Metric | Final total |
|---|---:|
| Usable recording effort | 4,030.6 h |
| Blue A detections | 1,353 |
| Blue B detections | 15,874 |
| Fin 20 Hz detections | 45,529 |

The final hourly product contains 20 analyzed deployments.

## Geographic zones

Each hourly row in the final call-activity CSV already contains its geographic-zone assignment based on hourly recorder latitude:

| Geographic zone | Latitude definition |
|---|---|
| Columbia River | 45.0 to 47.1 degrees N |
| Oregon | 42.0 to <45.0 degrees N |
| Northern California | 38.33 to <42.0 degrees N |
| Central California | 34.5 to <38.33 degrees N |
| Southern California | <34.5 degrees N |

The scripts use those stored assignments and do not recalculate geographic zones.

## Spatial magnitude maps

The magnitude maps display hourly retained automated detections along the analyzed drifter tracks.

Blue-whale magnitude is defined as:

```text
Blue A count + Blue B count
```

Fin-whale magnitude is defined as:

```text
Fin 20 Hz count
```

Only hours with one or more retained detections are drawn as magnitude symbols. The full analyzed drifter trajectories are retained as purple track lines.

Bathymetry is shown at:

- -1,000 m
- -2,000 m
- -3,000 m
- -4,000 m
- -5,000 m

The map styling and symbol-size classes were reconstructed from the final QGIS project used to prepare the report figure.

## R dependencies

The regional summary script requires:

```r
library(tidyverse)
```

The spatial map script requires:

```r
library(tidyverse)
library(sf)
library(maps)
library(rnaturalearth)
library(cowplot)
```

For archival reproducibility, package versions used for the final run can be recorded with:

```r
sessionInfo()
```

## Notes

- Run scripts from the repository root.
- The finalized hourly CSV is the authoritative input for this workflow.
- Training-deployment exclusions and retained-call-class decisions are already reflected in the finalized input product.
- Final reusable data products are stored under `supplement/BaleenWhales/`.
- Derived numerical results are stored under `output/BaleenWhales/`.
- Final rendered figures are stored under `_figs/BaleenWhales/`.
- Supporting GIS inputs used only for figure generation are stored under `_data/BaleenWhales/`.
