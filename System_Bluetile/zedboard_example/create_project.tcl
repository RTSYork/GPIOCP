#!../launch_vivado.sh -source

# Make the project
bs::create_project_with_board zed_project zed

# Create the board design
# ../ because the command runs within the project folder
set board [bs::create_bd_from_yaml root_board ../zedboard.yaml]

# Add in the wrapper
set boardFname [get_property FILE_NAME $board]
make_wrapper -top [get_files $boardFname]
add_files -norecurse "zed_project.srcs/sources_1/bd/root_board/hdl/root_board_wrapper.v"
