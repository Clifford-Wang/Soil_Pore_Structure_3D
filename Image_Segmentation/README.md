# 3D CT phase segmentation | Native CUDA

Windows x64 native CUDA executable for supervised **three-phase segmentation** (air, water, mineral) and optional four-phase segmentation (including organic matter). The full user configuration is editable; a 72-hour first-use trial applies. Source code is not distributed as plaintext.

- [Download native CUDA EXE](SoilSegmentationCUDA.exe)
- [Download configuration](config_segmentation.txt)
- [Windows launcher](run_segmentation.bat)
- [Windows CUDA build history](https://github.com/Clifford-Wang/Soil_Pore_Structure_3D/actions/workflows/build-structure.yml)

## Classification method

Random Forest training uses manually annotated voxels and five local features: CT attenuation, 3×3×3 mean, standard deviation, gradient magnitude and discrete Laplacian magnitude. Forest training is performed on the CPU; native CUDA kernels perform whole-volume inference.

The user may choose **air=1, water=2, mineral=3**, or include **organic=4** when separate organic reference annotations are available. The latter has not yet been evaluated on real soil CT. Labels 0 (unlabeled) and 255 (ignored) are omitted from supervised fitting and reference scoring. Grayscale attenuation alone does not uniquely identify chemical composition.

Class-specific `phase_weight_*` parameters multiply Random Forest vote fractions before normalization. A second optional three-phase step, `air_spatial_filter`, checks whether a voxel classified as air has sufficient support among nearby provisional air voxels. This uses a separable three-dimensional box filter on CUDA; poorly supported air predictions are reassigned to their best non-air class. The radius, support fraction and initial seed-class weights are configurable. This second step is intentionally disabled by default until calibrated for a new sample.

## Benchmark on published soil CT

The preliminary three-phase evaluation used paired grayscale CT and published phase labels from the TU Hamburg transient-water-retention dataset (DOI [10.15480/336.4291](https://doi.org/10.15480/336.4291)). A spatially registered 64 × 192 × 192 region was separated into: training slices 0–19, parameter calibration slices 24–39, and untouched final test slices 44–63 (**737,280 voxels**). The same fitted forest is used in every comparison.

| Held-out test metric | Unweighted RF | Weighted RF | Weighted RF + 3D air-coherence filter |
|:--|--:|--:|--:|
| Air Dice | 0.1816 | 0.4666 | **0.5971** |
| Water Dice | 0.9369 | 0.9670 | **0.9701** |
| Mineral Dice | 0.9862 | 0.9867 | **0.9867** |
| Overall voxel accuracy | 0.9566 | 0.9777 | **≈0.9798** |

The last method uses final class weights (air=0.125, water=0.700, mineral=1.000); a 5×5×5 support neighborhood, minimum air support of 0.40, and seed weights (air=0.075, water=0.850). An independent C++ implementation of the discrete filter produced air Dice=0.597127, water Dice=0.970070 and mineral Dice=0.986743; the small difference from the initial Python floating-point neighborhood calculation was limited to rounding at the support threshold. No testing labels were used in selecting these parameters.

Additional intervening held-out slices (20–23 and 40–43) also showed higher air, water and mineral Dice under this fixed profile. **All comparisons originate from the same CT acquisition.** The improved air Dice remains below 0.6 and performance on a different soil, scanner or moisture regime is not established. The benchmark evaluates CPU-equivalent model and refinement calculations; successful Windows native CUDA compilation is not a substitute for full GPU execution and validation.

## Input and operation

1. Specify `nx`, `ny`, `nz` and grayscale images in [config_segmentation.txt](config_segmentation.txt). Supported formats: little-endian uint16/uint8 raw stacks, multipage TIFF, or sequential TIFF slices.
2. Provide matching uint8 annotation voxels for all three base classes. Set `train_model=1` to fit and save a forest; use `train_model=0` with `model_path` to reuse it under matching acquisition conditions.
3. Leave weights=1 and `air_spatial_filter=0` for an uncalibrated sample. For the specific TUHH validation crop, use the calibrated values above. **Recalibrate on spatially separate annotated data before applying the profile to a different CT volume.** The spatial filter only accepts three-phase forests; four-phase models remain supported with this filter disabled.
4. Optionally provide `validation_labels` for independent reference scoring.

## Output files

- `phase_labels_u8.raw` and `phase_labels.vtk`: final material classes, including optional spatial refinement.
- `confidence_f32.raw`: weighted vote score of the final emitted class. If spatial correction reassigns a voxel, the value is the fallback class score.
- `phase_summary.csv`: class fractions and fraction below the confidence threshold.
- `probabilities_f32.raw`: optional four-slot weighted vote fractions **before spatial label refinement**; the organic slot is zero for three-phase forests.
- `pores_air_water_for_structure.txt`: optional binary pore/solid mask.
- `validation.csv`: per-class precision, recall, Dice, and IoU if reference labels are provided.

Weighted forest scores are **not calibrated posterior probabilities**. Organic-matter segmentation requires its own ground-truth data and has not been validated here. Physical GPU execution and 72-hour expiry behavior remain to be tested on user hardware.
