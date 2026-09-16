# CalCurCEAS DeepAcoustics Baleen-Whale Detector

## Model

**File:** `CalCurCEAS_PacificLF_TinyYOLO_final.mat`  
**Final network:** Network 17  
**Architecture:** TinyYOLO  
**Analysis bandwidth:** 400 Hz  
**Detector software:** DeepAcoustics / MATLAB  
**Detection confidence threshold:** 0.5

This is the final low-frequency baleen-whale detector used for the CalCurCEAS 2024 drifting-recorder analysis.

## Target call classes

The network detects six focal call types:

- Blue A
- Blue B
- Blue D
- Fin 20 Hz
- Fin 40 Hz
- Sei DS

## Training data

The final network was developed from an existing OSA Pacific low-frequency TinyYOLO model and additional CalCurCEAS/Pacific training data.

Additional training material included:

- manually annotated CalCurCEAS deployments 008 and 014
- two sei-whale sonobuoy datasets from PIFSC
- additional noise examples
- augmented training examples

Because deployments 008 and 014 contributed to model training, they were excluded from novel-data detector-performance evaluation and from downstream automated call-activity analyses intended to represent novel CalCurCEAS recordings.

## Performance and intended use

Detector performance was evaluated on novel CalCurCEAS recordings using manually reviewed data.

For secondary automated call-level analyses, only call classes with pooled F1 scores of at least 0.80 were retained:

- Blue A
- Blue B
- Fin 20 Hz

Blue D, Fin 40 Hz, and Sei DS did not meet that threshold and were not used for automated call-magnitude analyses. These classes were retained for manually validated hourly occurrence analyses.

Detailed deployment-level and pooled performance results are provided in:

```text
supplement/BaleenWhales/
CalCurCEAS_DeepAcoustics_performance_by_deployment_calltype.csv
CalCurCEAS_DeepAcoustics_performance_pooled_by_calltype.csv
```

## Use notes

- The `.mat` file is a DeepAcoustics/MATLAB model file and is not a standalone executable detector.
- CalCurCEAS recordings were decimated to 400 Hz for this low-frequency detector workflow.
- A confidence threshold of 0.5 was used for detector output in the final analysis.
- Detection counts are indices of relative acoustic activity and should not be interpreted as whale abundance or density.
- Performance may differ in acoustic environments or recorder configurations not represented in the training and evaluation data.

For the full training, validation, evaluation, and analysis methods, see the CalCurCEAS report and the repository detector-performance documentation.
