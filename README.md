# Energy_Calibration

Standalone Charge2Energy calibration module and helper scripts for applying
SuperNEMO calorimeter calibration constants to reconstructed real data.

This repository represents the **second stage** of the calibration workflow used
in the thesis. The first stage, performed in

- https://github.com/YaKozina/Calibration_Constants_Extraction

extracts the calibration constants for each optical module (OM). This repository
then applies those constants to reconstructed `.brio` files and writes calibrated
energy estimates back into the calibrated-data bank.

---

## Origin of the software

This repository is based on the original **CalibrationTools** package developed
by F. Koňařík for the SuperNEMO calorimeter energy calibration:

- https://github.com/konarfil/CalibrationTools

In particular, the `charge2energy.conf` configuration is derived from the
original template:

- https://github.com/konarfil/CalibrationTools/blob/main/Charge2EnergyModule/charge2energy.conf.in

The version stored here is a separated and adapted copy focused specifically on
the **Charge2Energy** part of the calibration chain. In the original
CalibrationTools package, the calibration tools are used as part of a broader
software framework. Here, the constant-extraction stage and the energy-calibration
stage are kept in separate repositories to make the workflow easier to run,
repeat, and combine with the unified Falaise-based processing chain used in the
analysis.

The original calibration method and core software framework should therefore be
attributed to F. Koňařík. This repository documents the adapted version used for
the second stage of the thesis workflow: applying previously extracted
calibration constants to real SuperNEMO calibration data.

---

## Purpose of this repository

The purpose of this repository is to run the **Charge2EnergyModule** on
reconstructed real-data `.brio` files containing the `pCD`, `CD`, and `PTD`
banks.

For each calorimeter hit, the module:

1. reads the measured PMT charge from the `pCD` bank;
2. reads the calibration constants `a_j` and `b_j` for the corresponding OM;
3. converts charge into energy using the linear calibration relation;
4. applies optical and/or energy-loss corrections where the required track
   information is available;
5. stores several calibrated energy estimates in the hit auxiliaries;
6. writes a new calibrated `.brio` file.

The output files are then used as input for later event selection and spectrum
analysis, for example in:

- https://github.com/YaKozina/Calibration_testing

---

## Position in the full workflow

The complete real-data calibration workflow is:

```text
raw / preprocessed data
        |
        v
pCD, CD, PTD reconstruction
        |
        v
Calibration_Constants_Extraction
        |
        |  produces CSV files with OM calibration constants
        v
Energy_Calibration
        |
        |  applies constants and writes calibrated energies
        v
calibrated brio files
        |
        v
SNCuts event selection and ROOT-level analysis
```

This repository corresponds to the **Energy_Calibration** step only.

---

## Repository structure

```text
Energy_Calibration/
├── CMakeLists.txt
├── install.sh
├── README.md
├── Charge2EnergyModule/
│   ├── CMakeLists.txt
│   ├── charge2energy.conf.in
│   ├── include/
│   │   └── charge2energy_module.h
│   └── src/
│       └── charge2energy_module.cc
├── EnergyCorrectionCalculator/
│   ├── CMakeLists.txt
│   ├── include/
│   │   └── energy_correction_calculator.h
│   └── src/
│       └── energy_correction_calculator.cc
└── scripts/
    ├── submit_calibrate_using_BOTH-const_array.sh
    ├── run_calibrate_using_BOTH-const_array.sh
    ├── send.sh
    └── examples_of_working_files/
        ├── charge2energy-BOTH.conf
        ├── charge2energy-EXAMPLE.conf
        ├── charge2energy-NOCALIB.conf
        └── charge2energy-OPTICAL.conf
```

---

## Main components

### Charge2EnergyModule

`Charge2EnergyModule` is a Falaise plugin module that performs the charge-to-energy
conversion.

It requires the following input banks:

| Bank | Role |
|------|------|
| `pCD` | contains the precalibrated calorimeter charge |
| `CD` | contains calibrated calorimeter hits to be filled/updated |
| `PTD` | contains reconstructed particle tracks and track-calo associations |

The module processes:

- calorimeter hits associated with reconstructed particle tracks;
- isolated calorimeter hits, where only the charge-to-energy conversion and
  non-linearity correction can be stored.

For associated track hits, the module can apply trajectory-dependent corrections,
because the reconstructed track provides the source and calorimeter vertices.

### EnergyCorrectionCalculator

`EnergyCorrectionCalculator` provides the correction calculations used by
`Charge2EnergyModule`, including:

- optical non-linearity correction;
- geometrical non-uniformity correction;
- Bethe-Bloch-based energy-loss corrections in detector materials.

The correction model accounts for the detector materials used in the original
calibration approach:

- tracker gas;
- Mylar;
- nylon.

It does **not** include energy losses in the copper calibration-source frame.
That effect is studied separately in the analysis repository.

---

## Energy estimates written by the module

For each processed calorimeter hit, several energy estimates are stored in the
hit auxiliaries.

| Auxiliary name | Meaning |
|----------------|---------|
| `Ef` | energy from charge using the linear calibration relation only |
| `Ef_bc` | energy corrected for Birks-Cherenkov non-linearity |
| `Ef_optical` | energy corrected for optical effects, including geometrical non-uniformity |
| `Ef_optical_loss` | energy corrected for both optical effects and energy losses in Mylar, nylon, and tracker gas |

The nominal `CD` hit energy is set to the uncorrected linear estimate `Ef`.
The different corrected values are stored as auxiliaries so that downstream
analysis can choose which energy definition to use.

For isolated calorimeter hits, only the information that does not require a
track is available.

---

## Configuration files

The main configuration template is:

```text
Charge2EnergyModule/charge2energy.conf.in
```

Working examples are provided in:

```text
scripts/examples_of_working_files/
```

### Example configuration files

| File | Purpose |
|------|---------|
| `charge2energy-NOCALIB.conf` | applies constants extracted without corrections |
| `charge2energy-OPTICAL.conf` | applies constants extracted with optical corrections |
| `charge2energy-BOTH.conf` | applies constants extracted with both correction groups |
| `charge2energy-EXAMPLE.conf` | example/template configuration |

The exact meaning of each mode depends on the calibration constants used as
input. The module itself stores all available energy estimates; the mode-specific
configuration mainly selects which CSV file with constants is used.

### Important configuration parameters

| Parameter | Description |
|-----------|-------------|
| `Charge2EnergyModule.directory` | path to the compiled `Charge2EnergyModule` plugin |
| `gas_pressure` | tracking gas pressure in bar |
| `He_pressure` | helium fraction in the tracking gas |
| `Et_pressure` | ethanol fraction in the tracking gas |
| `Ar_pressure` | argon fraction in the tracking gas |
| `T_gas` | tracking gas temperature in kelvin |
| `calibration_path` | path to the CSV file with calibration constants |

The partial gas pressures should add up to 1. The default values used in the
example configuration files are:

```text
gas_pressure = 0.89 bar
He_pressure  = 0.955
Et_pressure  = 0.035
Ar_pressure  = 0.010
T_gas        = 298 K
```

---

## Input calibration constants

The input CSV file is produced by the first-stage repository:

- https://github.com/YaKozina/Calibration_Constants_Extraction

The expected format is a semicolon-separated file containing, for each OM, the
OM number and the corresponding calibration parameters. In the module, these are
read as:

```text
OM_number ; a_j ; b_j
```

The parameters are used in the linear charge-to-energy relation:

```text
E_f = a_j Q + b_j
```

where `Q` is the measured PMT charge and `E_f` is the reconstructed electron
energy before further corrections.

If calibration parameters are missing for some OMs, the module prints a warning
and skips energy calculation for those OMs.

---

## Building the module

On CC-IN2P3, load the SuperNEMO software stack before building. For example, the
workflow was tested with:

```bash
source "${THRONG_DIR}/config/supernemo_profile.bash"
snswmgr_load_stack falaise@2026-02-09
```

Other compatible Falaise stacks may be used depending on the dataset and local
setup.

Then build the repository:

```bash
./install.sh
```

which runs:

```bash
mkdir build
cd build
cmake ..
make
```

After compilation, the plugin library and configured files are located under:

```text
build/Charge2EnergyModule/
```

Before running `flreconstruct`, make sure that the path in the configuration file

```text
Charge2EnergyModule.directory
```

points to this compiled module directory.

---

## Running the calibration on one file

A minimal `flreconstruct` command has the form:

```bash
flreconstruct \
  -i input_PTD.brio \
  -p path/to/charge2energy-BOTH.conf \
  -o output_PTD_c2e.brio
```

The input file should contain the banks needed by the module, especially `pCD`,
`CD`, and `PTD`.

The output file is a new `.brio` file with calibrated energy information stored
in the calorimeter-hit auxiliaries.

---

## Running the calibration on many files

The `scripts/` directory contains SLURM helper scripts used to process many
real-data runs on CC-IN2P3.

### submit_calibrate_using_BOTH-const_array.sh

This script:

1. defines the input directory containing reconstructed `*_PTD.brio` files;
2. defines the output directory for calibrated files;
3. creates a list of input files;
4. submits a SLURM array job.

The script currently contains CC-IN2P3-specific paths and should be edited before
use.

Typical usage:

```bash
bash scripts/submit_calibrate_using_BOTH-const_array.sh
```

### run_calibrate_using_BOTH-const_array.sh

This is the worker script called by the SLURM array.

It:

1. reads the input file corresponding to the SLURM array index;
2. checks that the file is a `*_PTD.brio` file;
3. creates the matching output directory;
4. loads the SuperNEMO/Falaise environment;
5. runs `flreconstruct` with the selected `Charge2EnergyModule` configuration;
6. writes an output file with suffix `_c2e.brio`.

The script includes several safety checks to avoid writing outputs inside the
input directory and to verify that the source `.brio` file is not modified.

### send.sh

`send.sh` is a minimal single-file example showing how to run the module on one
test file. It is mainly useful as a template and contains paths that must be
adapted to the local setup.

---

## Typical output naming

The large-scale scripts use the following naming convention:

```text
input:  <run>_PTD.brio
output: <run>_PTD_c2e.brio
```

The `_c2e` suffix indicates that the Charge2Energy module has been applied.

---

## Downstream usage

The calibrated `.brio` files produced by this repository are used as input for
the next stages of the analysis, for example:

- applying SNCuts in calibration mode;
- selecting Bi-207 calibration events;
- converting selected events to ROOT;
- producing total and angular energy spectra;
- studying the 600-800 keV inter-peak plateau.

These later steps are documented in:

- https://github.com/YaKozina/Calibration_testing

---

## Notes and limitations

- This repository is intended for **real experimental data**. Simulated data
  already contain energy information from mock calibration and are not processed
  with this module in the same way.
- The configuration examples contain hardcoded CC-IN2P3 paths and must be updated
  before use.
- The energy-loss correction requires reconstructed track information. If a hit
  has no suitable associated straight track and source vertex, only the available
  non-track-dependent quantities are stored.
- Kinked tracks are skipped for the full energy-loss correction because the
  correction assumes a straight trajectory between the source and the calorimeter.
- The copper-frame energy-loss effect identified in the thesis is not part of
  this correction model and is investigated separately.

---

## Related repositories

| Repository | Role |
|------------|------|
| https://github.com/konarfil/CalibrationTools | original calibration software by F. Koňařík |
| https://github.com/YaKozina/Calibration_Constants_Extraction | first stage: extraction of calibration constants |
| https://github.com/YaKozina/Energy_Calibration | second stage: application of calibration constants |
| https://github.com/YaKozina/Calibration_testing | full real/simulation pipeline and spectrum-level analysis |
