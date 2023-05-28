# APE_project

### Prerequisites
Pynq-Z2 board, PC, ICM-20948, USB-A to micro USB cable.

https://github.com/barbedo/vivado-git set up in the used Vivado installation for automatically setting up the Vivado project.

Tested with:
- `Ubuntu 22.04.2 LTS (host PC)`
- `Vivado / Vitis / Vitis HLS 2022.2` (with cable drivers and board files installed)
   - Place board_files folder in .../Xilinx/Vivado/2022.2/data/boards/ directory to install pynq-z2 board files.
   - Make sure Zynq 7000 series compatibility was ticked during installation. Else, in Vivado, go to Help->Add Design Tools or Devices and add it.

## 0) Prepare workspace
- Unzip \<git repo>/HDL/custom_ip/export.zip in the folder \<git repo>/HDL/custom_ip/

## 1) Create Vivado project
- Open Vivado
- Run script `imu2nn.tcl` using: Tools -> Run TCL Script... -> locate \<git repo>/HDL/imu2nn.tcl
- Generate Bitstream (may take a while).
