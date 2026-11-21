# Soil Structure 3D | 三维孔隙结构分析

> **发布状态：**Windows x64 原生 CUDA EXE 已通过 GitHub Actions 编译和主机端测试（2026-11-21）；尚未在真实 NVIDIA GPU 上完成运行验证。

用于对三维二值孔隙结构进行批量分析，支持孔隙率、连通域、贯通孔隙、孔–固界面面积、距离变换半径分布、几何迂曲度、欧拉示性数、连通概率、分形维数和临界贯通孔径的计算；可按规则提取贯通与未保留的孔隙结构。

## 下载与运行

- [下载 SoilStructureCUDA.exe](release/SoilStructureCUDA.exe)
- [下载参数配置](release/config_structure.txt)
- [下载启动脚本](release/run_structure.bat)
- [Windows CUDA 构建记录](https://github.com/Clifford-Wang/Soil_Pore_Structure_3D/actions/runs/44888410491)

1. 将 `SoilStructureCUDA.exe`、`config_structure.txt` 和 `run_structure.bat` 放在同一文件夹。
2. 在配置文件中设置体素尺寸、三维网格、邻域规则及输入目录。
3. 把结构 TXT 放入 `input` 文件夹，双击 BAT 启动。
4. 从 `output` 中查看样品汇总、沿三个方向的孔隙率分布及选定的孔隙结构。

输入数据必须是**已完成分割**的三维二值结构 TXT：默认以 `0` 表示孔隙、非零表示固体，可修改 `pore_value`。支持 F/C 两种一维重塑顺序；三维尺寸必须与输入数据相符。当前版本不包含原始 CT 灰度图的阈值分割、Otsu 或分水岭分割功能。

**说明：**孔径分布输出是体素到固相的欧氏距离分布，不等同于最大内切球局部厚度分布。临界贯通孔径采用离散球形结构元的形态学开运算，并以 6 邻域判定方向贯通。欧拉示性数采用闭合立方体复形定义，不能直接与 6 邻域连通域数量混为一谈。

Windows 原生 CUDA 程序要求兼容的 NVIDIA 显卡及驱动。程序内置从首次运行起连续 72 小时的试用校验；Windows 编译和主机端测试已通过，真实 GPU 运行及完整 72 小时到期行为仍需实机复验。仓库不公开明文求解源码。

数值核查包括形态学、连通域、孔–固界面和欧氏距离变换等标准合成样品。复杂自然土壤输入仍建议检查分割精度、体素分辨率及代表性体积。
