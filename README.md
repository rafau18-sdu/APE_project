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

## 1) Train network
- Start `APE_project.ipynb` in a Google colab session or any local session set up with Tensorflow.
- Run script from beginning.
- When script asks to choose file to upload choose \<git repo>/neural_network_design/data.zip
- Prints information regarding the network such as training progress, an overview of the network structure, test accuracy, and a random test inference result at the end.
- Should generate several .txt files containing the weights of the network.
- Download zip file with weights and extract in \<git repo>/HLS/

## 2) Create HLS project
- Open HLS -> Create Project -> Name and Location -> Next
- Design files: Add files -> [``lstm_impl.cpp``](/HLS/lstm_impl.cpp) and [``lstm_impl.hpp``](/HLS/lstm_impl.hpp) -> Top function -> nn_inference -> Next
- TestBench files: Add files ->[``lstm_impl_tb.cpp``](/HLS/lstm_impl_tb.cpp) -> Next
- Select Configuration: Part -> Boards -> pynq-z2 -> Finish
- (edit files to fit any network customization)
- If you did the last step in the previous section, the weights have been updated, along with the number of neurons in any layer.
- Run C Simulation to verify design with testbench file. Compare with value from the last section of `APE_project.ipynb`.
- Run C Synthesis (choose appropriate clock Period (ns) to match what you want in design) to synthesize design into VHDL/Verilog.
- Export RTL to obtain IP that can be imported to Vivado. Choose location: \<git repo>/HDL/custom_ip
- Unzip the updated \<git repo>/HDL/custom_ip/export.zip in the folder \<git repo>/HDL/custom_ip/

## 3) Create Vivado project
- Open Vivado
- Run script `imu2nn.tcl` using: Tools -> Run TCL Script... -> locate \<git repo>/HDL/imu2nn.tcl
- Generate Bitstream (may take a while).
- Finally, go to File -> Export Hardware -> Next -> Include bitstream -> Next -> Location -> Next -> Finish
