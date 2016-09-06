# Adapted from the Xilinx AXI_UARTLite core



proc init {cellPath otherInfo} {
    puts "Hello world!"
    
    set fooList "clk_freq"

    puts "LOL"
    # I don't know why this is needed, or what it does, but I can only guess
    # it registers this cell as "propagatable". I _assume_ the second parameter
    # goes into the otherInfo dict, but I've not had time to properly check.
    bd::mark_propagate_only [get_bd_cells $cellPath] $fooList
}

proc post_propagate {cellPath otherInfo } {
    set cell [get_bd_cells $cellPath]
    set clkPin [get_bd_pins $cell/CLK]
    set clkFreq [get_property CONFIG.FREQ_HZ $clkPin]
    if { $clkFreq == "" } {
        puts "ERROR: Could not get clock freqnency from CLK pin"
    }

    puts "Got clock frequency $clkFreq"
    
    set_property CONFIG.clk_freq $clkFreq $cell
}
