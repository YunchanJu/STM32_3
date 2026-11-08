# vivado -mode batch -source scripts/create_project.tcl -tclargs rx
# Optional second argument: absolute path of a populated spi_pins.tcl.
# Add 'bitstream' as third argument only after the pin map is verified.
set root [file normalize [file join [file dirname [info script]] ..]]
set role [lindex $argv 0]
if {$role ni {rx tx}} {error "Choose rx or tx"}
set pinfile [lindex $argv 1]
if {$pinfile eq ""} {set pinfile [file join $root xdc spi_pins.tcl]}
source $pinfile
set build_bitstream [expr {[lindex $argv 2] eq "bitstream"}]
set pins_ready 1
foreach variable {SPI_SCK_PIN SPI_MOSI_PIN SPI_CS_PIN} {
 if {[set $variable] eq ""} {set pins_ready 0}
}
if {$build_bitstream && !$pins_ready} {error "SPI extension PACKAGE_PIN map is required for bitstream"}
create_project spi_$role [file join $root build spi_$role] -part xc7s75fgga484-1 -force
set_property source_mgmt_mode None [current_project]
add_files [glob [file join $root src *.v]]
add_files -fileset sim_1 [glob [file join $root sim *.sv]]
add_files -fileset constrs_1 [file join $root xdc board_common.xdc]
set_property top spi_${role}_top [get_filesets sources_1]
set_property top tb_spi_system [get_filesets sim_1]
# Explicit module order is used; synthesis resolves instantiated modules.
if {$pins_ready} {
 set ports {spi_sck spi_mosi spi_cs_n}
 set physical [list $SPI_SCK_PIN $SPI_MOSI_PIN $SPI_CS_PIN]
 if {$role eq "rx"} {lappend ports uart_tx_o;lappend physical $UART_TX_PIN}
 if {[llength [lsort -unique $physical]] != [llength $physical]} {error "Duplicate PACKAGE_PIN"}
 foreach pin $physical {if {$pin in {B6 K4}} {error "SPI pin overlaps clock or reset"}}
 set out [open [file join $root build spi_$role spi_resolved.xdc] w]
 foreach port $ports pin $physical {
   puts $out "set_property PACKAGE_PIN $pin \[get_ports $port\]"
 }
 close $out
 add_files -fileset constrs_1 [file join $root build spi_$role spi_resolved.xdc]
} else {puts "SPI pin map is empty; simulation and RTL elaboration only"}
if {$build_bitstream} {
 # Build in this process; do not depend on Windows Script Host run launchers.
 set outdir [file join $root build spi_$role]
 close_project
 read_verilog [glob [file join $root src *.v]]
 read_xdc [file join $root xdc board_common.xdc]
 read_xdc [file join $outdir spi_resolved.xdc]
 synth_design -top spi_${role}_top -part xc7s75fgga484-1
 opt_design
 place_design
 route_design
 report_timing_summary -file [file join $outdir timing_summary.rpt]
 report_drc -file [file join $outdir final_drc.rpt]
 write_checkpoint -force [file join $outdir spi_${role}_routed.dcp]
 write_bitstream -force [file join $outdir spi_${role}_top.bit]
 close_design
 close_project
}
