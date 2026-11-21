# 3D CT phase segmentation (native CUDA)

Windows x64 native CUDA build completed on 2026-11-21. Host-side tests passed; physical GPU operation and real-soil segmentation accuracy remain unverified.

- [Download SoilSegmentationCUDA.exe](SoilSegmentationCUDA.exe)
- [Download configurable parameters](config_segmentation.txt)
- [Download Windows launcher](run_segmentation.bat)
- [Successful Windows build record](https://github.com/Clifford-Wang/Soil_Pore_Structure_3D/actions/runs/44905298000)

## Scope and method

The executable implements supervised, four-class Random Forest voxel classification.
Five image features are grayscale intensity, 3x3x3 local mean, local standard
deviation, centered gradient magnitude and local discrete Laplacian magnitude.
The forest uses bagged CART trees, stratified sampling and Gini-impurity splits.
CPU code fits the forest; CUDA kernels classify the 3D volume. This is a
classical machine-learning baseline, **not** a trained 3D U-Net.

Classes: **1 air, 2 water, 3 mineral, 4 organic matter**. Labels 0 and 255 in
the reference annotations are ignored. The class names are operational labels
defined by the user-provided reference data; this executable does not identify
chemical composition from grayscale alone.

## Input

Set nx, ny and nz in config_segmentation.txt. Supported formats:

- Raw grayscale: uint16 little-endian (default), optionally uint8; x varies
  fastest, then y, then z. For 200³ uint16: exactly 16,000,000 bytes.
- A single multi-frame TIFF, or a directory containing TIFF slices. TIFF
  decoding uses Windows Imaging Component; slices are sorted by filename.
- Reference annotations: uint8 raw or grayscale TIFF labels, one byte
  per voxel, with identical dimensions and ordering as the source grayscale.

First train with train_model=1, providing training_image and training_labels
(all four classes must be manually represented), and set prediction_image to
the CT volume to classify. A trained forest is saved in model_path and can be
reused with train_model=0 on subsequent images. Reusing a model across
different scanners or contrast settings requires validation.

## Output

- phase_labels_u8.raw: 1–4 material labels, one byte per voxel.
- phase_labels.vtk: 3D label volume, viewable in ParaView.
- confidence_f32.raw: maximum forest vote score, **not** a calibrated posterior.
- phase_summary.csv: phase volume fractions and low-confidence fraction.
- probabilities_f32.raw: optional interleaved four-class scores.
- pores_air_water_for_structure.txt: optional pore=0, solid=1 mask for the
  separate 3D structure analysis EXE.
- validation.csv: per-class precision, recall, Dice and IoU if independently
  annotated reference labels are supplied through validation_labels.

If training and validation use the same region, the reported accuracy is
optimistic. Scientific evaluation should use independent cores or independent
annotated spatial regions. Air/water/organic matter attenuation can overlap in
a single-energy scan. Paired dry/wet scans, contrast agents or multi-energy CT
may be needed for identifiable four-phase reference data.

The Windows executable includes a 72-hour first-use trial guard. Compilation
and synthetic host-side tests do not substitute for validation on representative
soil CT samples and an NVIDIA GPU.
