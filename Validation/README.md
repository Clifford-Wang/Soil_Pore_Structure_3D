# Validation | 数值验证

This page summarizes numerical checks for the **3D pore-structure analysis** and **air–water–solid CT segmentation** modules. The reported tests distinguish analytical or synthetic checks from comparisons with an independently annotated CT region.

## 1. 3D pore-structure analysis

The native structure-analysis implementation was checked against prescribed binary geometries with known topological and geometric properties.

| Synthetic geometry | Verification target |
|:--|:--|
| Fully solid volume | Zero pore volume, zero connected components and zero internal pore–solid interface |
| One enclosed pore voxel | One closed component, six internal interface faces and Euler characteristic of one |
| Two separated pore voxels | Two isolated components and twelve internal interface faces |
| Fully porous 3 × 3 × 3 volume | Through-connectivity along all axes, zero internal interface and 54 exterior open faces |
| Straight 5-voxel channel | Through-connectivity only along the channel, unit geometrical tortuosity and one-voxel critical opening diameter |
| Two diagonally touching voxels | Two components with 6-neighbour connectivity but one with 26-neighbour connectivity |

All listed host-side synthetic checks passed in the Windows build. They establish consistency for these defined geometries, not accuracy for every natural soil morphology.

## 2. Air–water–solid segmentation

### Reference data and experimental design

The real-CT comparison used the publicly available TU Hamburg research dataset [*Data from in situ X-ray CT imaging of transient water retention experiments with cyclic drainage and imbibition*](https://doi.org/10.15480/336.4291), which contains CT images of a sand specimen during drainage and imbibition.

A registered **64 × 192 × 192 voxel** subvolume was divided along its depth axis:

- **Model fitting:** slices 0–19.
- **Parameter calibration:** slices 24–39.
- **Untouched test:** slices 44–63 (**737,280 voxels**).
- Slices 20–23 and 40–43 separate the fitted, calibration and test regions.

The Random Forest and its feature representation were held fixed across comparisons. Only the class weights and the optional three-dimensional air-neighbourhood refinement differed. No test labels were used to select the final parameters.

### Held-out test results

| Metric | Unweighted Random Forest | Weighted Random Forest | Weighted RF + 3D air filter |
|:--|--:|--:|--:|
| Air Dice | 0.1816 | 0.4666 | **0.5971** |
| Water Dice | 0.9369 | 0.9670 | **0.9701** |
| Solid Dice | 0.9862 | 0.9867 | **0.9867** |
| Overall voxel accuracy | 0.9566 | 0.9777 | **≈0.9798** |

The final calibration used class weights **air 0.125, water 0.700 and solid 1.000**. The optional air filter used a **5 × 5 × 5** neighbourhood, minimum air support **0.40**, and preliminary seed weights **air 0.075, water 0.850**. The reference implementation of this discrete filter yielded air/water/solid Dice **0.597127 / 0.970070 / 0.986743**.

### Scope of verification

The spatial filter improved the air-class overlap while maintaining the high water and solid scores within this CT acquisition. However, the air Dice remains below 0.60; transfer to other soil materials, imaging conditions or moisture regimes has not been demonstrated.

The published test metrics were obtained by comparing CPU-equivalent inference and refinement calculations against the independent reference labels. [Windows CUDA compilation and host-side tests passed](https://github.com/Clifford-Wang/Soil_Pore_Structure_3D/actions/runs/45015743525), but execution on a physical NVIDIA GPU and the complete 72-hour trial-expiry process remain to be verified on user hardware.
