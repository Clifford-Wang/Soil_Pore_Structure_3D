# 3D CT air–water–solid segmentation | Native CUDA

Windows x64 native CUDA program for supervised classification of **air (1), water (2), and solid (3)**. The solid phase is represented as a single class. The program uses an editable user configuration and a 72-hour first-use trial; C++/CUDA source is not released as plaintext.

- [Download SoilSegmentationCUDA.exe](SoilSegmentationCUDA.exe)
- [Parameter configuration](config_segmentation.txt)
- [Windows launcher](run_segmentation.bat)
- [CUDA build history](https://github.com/Clifford-Wang/Soil_Pore_Structure_3D/actions/workflows/build-structure.yml)

# 3D CT phase segmentation (native CUDA)

## Scope and method

The executable implements supervised three-class Random Forest voxel classification.
Five image features are grayscale intensity, 3x3x3 local mean, local standard
deviation, centered gradient magnitude and local discrete Laplacian magnitude.
The forest uses bagged CART trees, stratified sampling and Gini-impurity splits.
CPU code fits the forest; CUDA kernels classify the 3D volume. This is a
classical machine-learning baseline, **not** a trained 3D U-Net.

Classes: **1 air, 2 water, 3 solid**. All material classified as solid is
represented by one label. Labels 0 and 255 are excluded from fitting and
reference scoring.

## Independent CT benchmark

Paired CT labels from the TU Hamburg transient-water-retention dataset
(DOI: 10.15480/336.4291) were evaluated on 737,280 held-out voxels in
spatially separated slices of one aligned acquisition. The user-calibrated
3D neighborhood filter produced the following comparison:

| Reference class | Weighted forest Dice | Weighted forest + 3D air filter Dice |
|---|---:|---:|
| Air | 0.4666 | 0.5971 |
| Water | 0.9670 | 0.9701 |
| Solid | 0.9867 | 0.9867 |

These results originate from one scan. They validate the reference CPU
equivalent of the CUDA calculations, rather than direct GPU execution on
an independent soil core. Different imaging and moisture conditions require
their own calibration and held-out evaluation.

## Input

Set nx, ny and nz in config_segmentation.txt. Supported formats:

- Raw grayscale: uint16 little-endian (default), optionally uint8; x varies
  fastest, then y, then z. For 200³ uint16: exactly 16,000,000 bytes.
- A single multi-frame TIFF, a PNG, or a directory containing PNG/TIFF slices. Image
  decoding uses Windows Imaging Component; slices are sorted by filename.
- Reference annotations: uint8 raw or grayscale PNG/TIFF labels, one byte
  per voxel, with identical dimensions and ordering as the source grayscale.

First train with train_model=1, providing training_image and training_labels
(all three phases should be manually represented in the reference), and set prediction_image to
the CT volume to classify. A trained forest is saved in model_path and can be
reused with train_model=0 on subsequent images. Reusing a model across
different scanners or contrast settings requires validation.

## Output

- phase_labels_u8.raw: 1–3 material labels, one byte per voxel.
- phase_labels.vtk: 3D label volume, viewable in ParaView.
- confidence_f32.raw: maximum forest vote score, **not** a calibrated posterior.
- phase_summary.csv: phase volume fractions and low-confidence fraction.
- probabilities_f32.raw: optional interleaved three-class scores.
- pores_air_water_for_structure.txt: optional pore=0, solid=1 mask for the
  separate 3D structure analysis EXE.
- validation.csv: per-class precision, recall, Dice and IoU if independently
  annotated reference labels are supplied through validation_labels.

The optional CUDA air-neighborhood filter requires sample-specific calibration;
it is disabled by default. A previously saved model produced by the older
four-label format is incompatible with this three-class release and must be
retrained. Training and validation must use independent regions to avoid
optimistic accuracy estimates. A single grayscale CT scan may be insufficient
to distinguish liquid water from air without suitable acquisition conditions.

The Windows executable includes a 72-hour first-use trial guard. Compilation
and synthetic host-side tests do not substitute for validation on representative
soil CT samples and an NVIDIA GPU.
