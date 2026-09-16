# Baleen Whale Data

This folder contains supporting and upstream files used by the CalCurCEAS 2024 baleen-whale analysis. These files are retained for reproducibility and provenance but are not the primary public-facing analytical products. Final reusable CSV products are stored in `supplement/BaleenWhales/`.

## What belongs in this folder

`_data/BaleenWhales/` is intended for **supporting or upstream analysis material** that helps document or regenerate the baleen-whale workflows, but that is not itself the main final public data product.

This includes:

- supporting GIS/context layers
- upstream detector outputs
- supporting count tables used to regenerate final summary products

It does **not** need to duplicate the final reusable CSV products already published in `supplement/BaleenWhales/`.

## Files

### `CalCurCEAS_bathymetry_contours.gpkg`

Bathymetric contour data used to provide geographic context in the automated call-activity magnitude maps.

The GeoPackage contains the layer:

```text
Bathymetry_1000m
```

with contours at:

- -1,000 m
- -2,000 m
- -3,000 m
- -4,000 m
- -5,000 m

The layer is stored in WGS84 / EPSG:4326.

It is used by:

```text
_code/baleen_whales/relative_call_activity/
spatial_automated_call_activity_magnitude_maps.r
```

The authoritative automated call detections and hourly positions are not stored in this GeoPackage; they come from the finalized CSV in `supplement/BaleenWhales/`.

### `CalCurCEAS_DeepAcoustics_performance_counts_by_deployment_calltype.csv`

Supporting TP/FP/FN counts used to regenerate deployment-level and pooled detector-performance metrics.

It is used by:

```text
_code/baleen_whales/detector_performance/
deep_acoustics_detector_performance_summary.R
```

The final detector-performance products generated from these counts are stored in:

```text
supplement/BaleenWhales/
CalCurCEAS_DeepAcoustics_performance_by_deployment_calltype.csv
CalCurCEAS_DeepAcoustics_performance_pooled_by_calltype.csv
```

## `DeepAcoustics_Output/`

This subfolder contains the per-deployment Network 17 DeepAcoustics detection-output `.mat` files retained as supporting analysis material.

Files are named using the pattern:

```text
CalCurCEAS_###_DA_Detections_Network17.mat
```

Outputs are present for the 25 deployments from which acoustic recordings were recovered. Deployments 005 and 007 do not have detector-output files because usable recorder data were not recovered from those deployments.

These `.mat` files are intentionally kept in `_data/BaleenWhales/` because they are **upstream detector outputs**, not final cleaned public products. They provide useful provenance and preserve the direct DeepAcoustics output associated with the final Network 17 run, while the cleaned public workflows in `_code/baleen_whales/` generally begin from finalized CSV analysis products rather than reprocessing these `.mat` files directly.

In other words:

- `DeepAcoustics_Output/` preserves the raw detector-output archive for transparency and provenance
- `supplement/BaleenWhales/` preserves the cleaned final analytical products derived from those outputs

## What is not included here

This folder is intentionally limited. The following types of files are generally kept elsewhere:

- final reusable CSV products → `supplement/BaleenWhales/`
- final detector/model file → `supplement/BaleenWhales/`
- derived report-style summary tables → `output/BaleenWhales/`
- final rendered figures → `_figs/BaleenWhales/`
- shared project-level metadata or effort files used across taxa → project-level folders outside `_data/BaleenWhales/`

## Repository organization

- `_data/BaleenWhales/` — supporting or upstream analysis inputs
- `supplement/BaleenWhales/` — final reusable public data products and the final detector
- `output/BaleenWhales/` — derived numerical summaries
- `_figs/BaleenWhales/` — final rendered figures
- `_code/baleen_whales/` — reproducible analytical workflows

## Notes

- The final DeepAcoustics detector itself is stored in `supplement/BaleenWhales/CalCurCEAS_PacificLF_TinyYOLO_final.mat`.
- See the workflow-specific README files under `_code/baleen_whales/` for analysis inputs, outputs, run order, and QA checks.
