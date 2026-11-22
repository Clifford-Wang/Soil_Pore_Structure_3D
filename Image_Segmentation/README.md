# 3D CT phase segmentation | Native CUDA

Windows x64 executable for supervised three-phase (air, water, mineral) or optional four-phase (including organic matter) segmentation. Only the executable and user configuration are distributed; implementation source is not published. A 72-hour first-use trial applies.

- [Native CUDA executable](SoilSegmentationCUDA.exe)
- [Configuration file](config_segmentation.txt)
- [Windows launcher](run_segmentation.bat)
- [Windows build history](https://github.com/Clifford-Wang/Soil_Pore_Structure_3D/actions/workflows/build-structure.yml)

## Numerical implementation

A Random Forest is trained on manually annotated CT voxels, using grayscale intensity, local mean, local standard deviation, gradient magnitude and discrete Laplacian magnitude. Trees are fitted on the CPU; voxel inference is implemented by native CUDA kernels. This is a supervised classical machine-learning segmentation method, **not** an independently trained U-Net.

- **Three-phase mode:** labels 1=air, 2=water, 3=mineral. Annotations for these three phases are required; label 4 is not required.
- **Four-phase mode:** optional label 4=organic matter, provided its independently annotated training voxels are available.
- Labels 0 (unlabeled) and 255 (ignored) are excluded from supervised training and reference scoring.
- Classification labels are determined by reference annotations, not by unique chemical signatures inferred from attenuation.

The configuration permits positive, finite `phase_weight_air`, `phase_weight_water`, `phase_weight_mineral` and `phase_weight_organic`. Each weight multiplies the respective forest vote fraction before renormalization. Values of 1.0 reproduce unweighted classification. **These weights are sample- and scanner-dependent** and must be selected with spatially separate labeled calibration data. The exported scores are weighted vote fractions, **not calibrated posterior probabilities**.

## Independent-slice evaluation on published soil CT

A preliminary benchmark used paired grayscale CT and published three-phase labels from the TU Hamburg transient-water-retention dataset (DOI [10.15480/336.4291](https://doi.org/10.15480/336.4291)). A 64 × 192 × 192 voxel region was spatially registered using only training slices; the reference classes were air, water and solid/mineral. Training: slices 0–19; weight selection: slices 24–39; untouched testing: slices 44–63 (737,280 voxels). The same trained model was evaluated both before and after weight adjustment.

| Metric, held-out test | Unweighted | Weighted |
|:--|--:|--:|
| Overall voxel accuracy | 0.9566 | **0.9777** |
| Air Dice | 0.1816 | **0.4666** |
| Water Dice | 0.9369 | **0.9670** |
| Mineral Dice | 0.9862 | **0.9867** |
| Macro-average Dice | 0.7016 | **0.8067** |

Dataset-specific selected weights were air=0.075, water=0.850, mineral=1.000 and organic=1.000. They are provided as a **reproducible benchmark example**, not as defaults.

**Interpretation:** Water and solid segmentation show promising agreement within this cropped sample, while air remains insufficiently robust for quantitative pore-air analysis (Dice below 0.5, low air prevalence). Training, calibration and test slices originate from a single CT acquisition; therefore the study does not establish generalization to independent soil cores or scanners. The reported experiment evaluates the CPU-equivalent forest/class-weight logic. Successful Windows compilation and synthetic host-side tests do **not** constitute physical NVIDIA GPU execution or end-to-end EXE validation.

## Data preparation and execution

1. Set `nx`, `ny`, `nz` in [config_segmentation.txt](config_segmentation.txt) and provide grayscale CT and matching annotation files. Supported image inputs: little-endian uint16/uint8 raw volume, multipage TIFF, or a directory of sequential TIFF slices; annotations are uint8 labels.
2. Set `train_model = 1` to train and save the forest. For a later image with matching imaging conditions, set `train_model = 0` and provide the saved `model_path`.
3. Leave the four phase weights at 1.0 initially. If reference data permit, calibrate them on **separate** slices or cores, and report performance on an untouched test volume.
4. Optionally set `validation_labels` to a separate reference label volume to obtain `validation.csv`.

## Outputs

- `phase_labels_u8.raw` and `phase_labels.vtk`: voxel phase labels.
- `confidence_f32.raw`: maximum weighted forest score; not a posterior probability.
- `phase_summary.csv`: material volume fractions and low-confidence fraction.
- `probabilities_f32.raw`: optional interleaved scores for all four class slots (unused organic slot remains zero in three-phase mode).
- `pores_air_water_for_structure.txt`: optional binary pore/solid mask for the separate structure-analysis executable.
- `validation.csv`: per-phase precision, recall, Dice, and intersection-over-union when ground-truth labels are supplied.

The executable uses a three-day trial measured from first use.