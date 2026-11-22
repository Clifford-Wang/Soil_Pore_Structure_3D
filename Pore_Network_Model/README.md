# Pore Network Model | 孔隙网络模型

This module combines two **independent image-to-network extraction routes** with one network-transport model. The extraction algorithms are not interchangeable: PoreSpy **SNOW2** partitions void space by marker-based watershed, whereas Imperial College **pnextract** applies a maximal-ball-based geometric network extraction. Only pore-scale quantities with consistent definitions should be compared between the extracted networks.

## Methods and model scope

| Stage | Method | Implementation scope |
|:--|:--|:--|
| Network extraction A | Original PoreSpy `networks.snow2` | External reference extractor; standardized `pores.csv` / `throats.csv` accepted |
| Network extraction B | Original `pnextract` maximal-ball method | Imports the documented four-file Statoil network format directly |
| Network properties | Pore coordination, pore/throat radius, volume, connected flow paths | Native network reader and health checks |
| Drainage | Inlet-accessible quasi-static non-wetting-phase invasion; Young–Laplace throat-entry threshold; optional hydrostatic pressure correction | CUDA entry-pressure calculation; CPU graph invasion |
| Capillary retention | Water saturation from pore and throat occupancy volumes at each imposed capillary pressure | `capillary_relative.csv` |
| Two-phase relative permeability | Separate water- and gas-conducting pore/throat subnetworks; hydraulic network equations, normalized by single-phase reference | `capillary_relative.csv` |
| Solute transport | Water-phase advection–diffusion, optional first-order reaction; saturated or a prescribed drainage state | `solute_breakthrough.csv` |

The program is a **native Windows CUDA executable**, not a port of the full original PoreSpy or pnextract extraction libraries. Extraction is performed with those scientific packages independently, and the resulting networks are imported. CUDA is used for throat-entry calculations; graph invasion and current pressure/solute equations are host-side. The first release implements **quasi-static drainage and connectivity-controlled phase conductance**, not dynamic two-phase LBM, film flow, snap-off, trapping or hysteretic imbibition.

## Network input

The volume needs to be segmented before network extraction. Set `format=statoil` for the four pnextract files `Image_node1.dat`, `Image_node2.dat`, `Image_link1.dat`, `Image_link2.dat` (prefix configurable). This is the conventional Statoil/Øren format, not the newer `Net.xmf` format.

For an original PoreSpy SNOW2 network, export into the following standardized files (all physical lengths in **metres**):

- `pores.csv`: `id,x_m,y_m,z_m,radius_m,volume_m3,boundary_mask`
- `throats.csv`: `pore_id_1,pore_id_2,radius_m,length_m,volume_m3`
- `domain.txt`: single line `Lx Ly Lz` (metres)

For SNOW2, use `pore.inscribed_diameter / 2` for pore radius, `throat.inscribed_diameter / 2` for throat radius, and select/document the conduit length from the original extracted geometry. The choice of hydraulic diameter and length is a **model assumption**; the exporter must preserve the same definitions for every sample. The `boundary_mask` bits are 1/2 (X−/X+), 4/8 (Y−/Y+), and 16/32 (Z−/Z+). The executable also identifies bounding-face pores geometrically when explicit masks are not supplied.

For both formats, the coordinate axes must match the physical sample orientation. **Air enters the high-coordinate face**, representing top-entry drainage when `direction=z` and Z increases upward. The hydraulic pressure boundary for the permeability and solute calculations is from the low-coordinate to the high-coordinate face; reversing flow direction does not change linear intrinsic permeability but does change the solute-injection side.

Each sample should be in its own subdirectory of `input`. All numerical and physical inputs are controlled through `config_pnm.txt`; output is written to a separate folder for each sample. A compatible NVIDIA GPU and Windows x64 are required.

## Interpretation

The current hydraulic conductance assumes **circular cylindrical throats** with no separate pore-body resistance. This assumption is deliberately explicit because the original SNOW2 and maximal-ball networks contain different geometric descriptors. The resulting permeability and relative-permeability curves are model predictions, not exact reconstructions of pore-scale Navier–Stokes flow. Water and air occupy exclusive discrete pore/throat elements; unresolved wetting films and trapping are not represented.

Solute concentration is transported only in the **spanning water-phase network**. `solute_pc_Pa=-1` selects a fully saturated network; a nonnegative value selects water remaining after air invasion to that pressure. Set all diffusivities, viscosities, pressure limits, time steps and reaction constants to the experiment under study. The current solver uses an explicit conservative flux discretization with adaptive substepping for stability, and outputs a water-phase breakthrough curve. It does not simulate sorption, diffusion through stagnant unconnected water clusters, or reactive changes in pore geometry.

## Validation and distribution

Analytical and synthetic network tests cover cylindrical Hagen–Poiseuille flow, flux continuity, hydraulic disconnection, monotonic drainage saturation, both relative-permeability endpoints, CSV/Statoil import and solute breakthrough file generation. These tests **do not establish quantitative agreement with actual CT samples**. Both extraction routes must still be compared on the same segmented sample, and simulated absolute permeability, Pc–Sw and relative-permeability curves need independent benchmarks or measurements before use as validated research results.

Only configuration files, a Windows launcher and the executable are made available to end users. The executable uses a **72-hour trial from first use**, and the plaintext native source is not distributed.

Methods documentation: [PoreSpy SNOW2](https://porespy.org/examples/networks/reference/snow2.html), [Imperial College pnextract](https://github.com/ImperialCollegeLondon/pnextract), [OpenPNM relative permeability](https://openpnm.org/examples/applications/relative_permeability.html).
