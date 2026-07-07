# ========================================================
# Project:  iclab APR Flow
# File:     run_apr.cmd
# Author:   Lai Lin-Hung @ Si2 Lab
# Date:     2023.07.25
# ========================================================
############################################
############  Paremeter setting  ###########
############################################
set ProcessRoot "/RAID2/COURSE/BackUp/2023_Spring/iclab/iclabta01/UMC018_CBDK/CIC/SOCE/"
set MemoryRoot "../Memory/ftclib_200901.2.1/EXE/"
set NUM_OF_CPU 48
set mmmcFile "mmmc.view"
set lefFile "
    $ProcessRoot/lef/header6_V55_20ka_cic.lef
    $ProcessRoot/lef/fsa0m_a_generic_core.lef
    $ProcessRoot/lef/FSA0M_A_GENERIC_CORE_ANT_V55.lef
    $ProcessRoot/lef/fsa0m_a_t33_generic_io.lef
    $ProcessRoot/lef/FSA0M_A_T33_GENERIC_IO_ANT_V55.lef
    $ProcessRoot/lef/BONDPAD.lef
    ../04_MEM/SUMA180_384X16X1BM1.lef
"
set topDesign "CHIP"
set verilogFile "./CHIP_SYN.v"
set ioFile "./CHIP.io"
set pwrNet "VCC"
set gndNet "GND"

############################################
############  APR UMC018 setting ###########
############################################
set init_design_uniquify 1
setDesignMode -process 180
suppressMessage TECHLIB 1318
suppressMessage ENCEXT-2799
############################################
############  Initial Design     ###########
############################################
set init_mmmc_file $mmmcFile
set init_lef_file $lefFile
set init_verilog $verilogFile
set init_top_cell $topDesign
set init_io_file $ioFile
set init_pwr_net $pwrNet
set init_gnd_net $gndNet
init_design -setup {av_func_mode_max} -hold {av_func_mode_min}

save_global CHIP.globals
win
getIoFlowFlag
setIoFlowFlag 0
floorPlan -site core_5040 -r 0.73 0.9 115.6 115.6 115.6 115.6 
dbGet top.fPlan.coreBox
scan [dbGet top.fPlan.box] "{%f %f %f %f}" x1 y1 x2 y2
set w [expr $x2 - $x1]
set h [expr $y2 - $y1]
puts "[expr $w * $h] um2"
set sram_name [dbGet top.insts.name *SRAM*]
set margin 6.4
set target_orient R90

set sram [dbGet -p top.insts.name $sram_name]

if {$sram == "" || $sram == "0x0"} {
    error "Cannot find SRAM instance: $sram_name"
}

scan [dbGet top.fPlan.coreBox] "{%f %f %f %f}" core_llx core_lly core_urx core_ury

set raw_w 326.74
set raw_h 254.80

if {$target_orient == "R90" || $target_orient == "R270"} {
    set sram_w $raw_h
    set sram_h $raw_w
} else {
    set sram_w $raw_w
    set sram_h $raw_h
}

set new_llx [expr {$core_llx + $margin}]
set core_cy  [expr {($core_lly + $core_ury) / 2.0}]
set new_lly [expr {$core_cy - $sram_h / 2.0}]
set new_urx [expr {$new_llx + $sram_w}]
set new_ury [expr {$new_lly + $sram_h}]

dbSet $sram.orient $target_orient

setObjFPlanBox Instance $sram_name \
    $new_llx $new_lly $new_urx $new_ury

addHaloToBlock {6.4 6.4 6.4 6.4} -allMacro
deselectAll

scan [dbGet top.fPlan.box] "{%f %f %f %f}" x1 y1 x2 y2

set delta 5.0
set pin_layer metal1

proc move_one_pin {pin_name x y side pin_layer} {
    set term [dbGet top.terms.name $pin_name -p]

    if {$term == "" || $term == "0x0"} {
        puts "PIN NOT FOUND: $pin_name"
        return
    }

    puts "Move $pin_name to {$x $y} side=$side layer=$pin_layer"

    editPin -pin [list $pin_name] -layer $pin_layer -assign [list $x $y] -side $side
}

move_one_pin {arid_m_inf_inst_1[3]}        [expr {$x1 + $delta}] $y2 TOP    $pin_layer
move_one_pin {araddr_m_inf_inst_2[10]}     [expr {$x2 - $delta}] $y2 TOP    $pin_layer

move_one_pin {rid_m_inf_inst_1[3]}         $x1 [expr {$y1 + $delta}] LEFT   $pin_layer
move_one_pin {awready_m_inf_data}          $x1 [expr {$y2 - $delta}] LEFT   $pin_layer

move_one_pin {wready_m_inf_data}           [expr {$x1 + $delta}] $y1 BOTTOM $pin_layer
move_one_pin {wvalid_m_inf_data}           [expr {$x2 - $delta}] $y1 BOTTOM $pin_layer

move_one_pin {araddr_m_inf_inst_2[9]}      $x2 [expr {$y1 + $delta}] RIGHT  $pin_layer
move_one_pin {bready_m_inf_data}           $x2 [expr {$y2 - $delta}] RIGHT  $pin_layer

foreach pin_name {
    {arid_m_inf_inst_1[3]}
    {araddr_m_inf_inst_2[10]}
    {rid_m_inf_inst_1[3]}
    {awready_m_inf_data}
    {wready_m_inf_data}
    {wvalid_m_inf_data}
    {araddr_m_inf_inst_2[9]}
    {bready_m_inf_data}
} {
    set term [dbGet top.terms.name $pin_name -p]
    if {$term != "" && $term != "0x0"} {
        puts "$pin_name : [dbGet $term.pt]"
    }
}
saveDesign CHIP_floorplan.inn
scan [dbGet top.fPlan.box] "{%f %f %f %f}" x1 y1 x2 y2
set w [expr $x2 - $x1]
set h [expr $y2 - $y1]
puts "[expr $w * $h] um2"
