Zedboard
========
This is a simple design showing how to create the platform on a Zedboard.

To create the Vivado project, run ./create_project.tcl. Xilinx Vivado 2015.2 **must** be in your PATH for this to work.

TODO
----
This is not finished.

* Due to a limitation with the current TCL scripts, automation does not work for resets. ext_reset_in **must** be connected manually
* The Microblaze is not currently connected up to a block-RAM. This will be fixed in future.
