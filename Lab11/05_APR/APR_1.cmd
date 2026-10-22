#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Fri May 22 01:49:02 2026                
#                                                     
#######################################################

#@(#)CDS: Innovus v20.15-s105_1 (64bit) 07/27/2021 14:15 (Linux 2.6.32-431.11.2.el6.x86_64)
#@(#)CDS: NanoRoute 20.15-s105_1 NR210726-1341/20_15-UB (database version 18.20.554) {superthreading v2.14}
#@(#)CDS: AAE 20.15-s020 (64bit) 07/27/2021 (Linux 2.6.32-431.11.2.el6.x86_64)
#@(#)CDS: CTE 20.15-s024_1 () Jul 23 2021 04:46:45 ( )
#@(#)CDS: SYNTECH 20.15-s012_1 () Jul 12 2021 23:29:38 ( )
#@(#)CDS: CPE v20.15-s071
#@(#)CDS: IQuantus/TQuantus 20.1.1-s460 (64bit) Fri Mar 5 18:46:16 PST 2021 (Linux 2.6.32-431.11.2.el6.x86_64)

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
suppressMessage ENCEXT-2799
getVersion
win
set init_design_uniquify 1
setDesignMode -process 180
suppressMessage TECHLIB 1318
suppressMessage ENCEXT-2799
save_global CHIP.globals
set init_gnd_net GND
set init_lef_file {LEF/header6_V55_20ka_cic.lef LEF/fsa0m_a_generic_core.lef LEF/FSA0M_A_GENERIC_CORE_ANT_V55.lef LEF/fsa0m_a_t33_generic_io.lef LEF/FSA0M_A_T33_GENERIC_IO_ANT_V55.lef LEF/BONDPAD.lef LEF/SUMA180_4096X12.lef}
set init_verilog CHIP_SYN.v
set init_mmmc_file CHIP_mmmc.view
set init_io_file CHIP.io
set init_top_cell CHIP
set init_pwr_net VCC
init_design
getIoFlowFlag
setIoFlowFlag 0
floorPlan -site core_5040 -r 0.77 0.86 100 100 100 100 
dbGet top.fPlan.coreBox
scan [dbGet top.fPlan.box] "{%f %f %f %f}" x1 y1 x2 y2
set w [expr $x2 - $x1]
set h [expr $y2 - $y1]
puts "[expr $w * $h] um2"
# dbGet [dbGet top.insts.name CORE/sram0_u_SRAM_4096_12 -p].box

deselectAll
# left top
setObjFPlanBox Instance CORE/sram0_u_SRAM_4096_12 \
    255.56 1024.92 1034.28 1475.72
deselectAll
# right top
setObjFPlanBox Instance CORE/sram1_u_SRAM_4096_12 \
    1064.28 1024.92 1843.00 1475.72
deselectAll
# left bottom
setObjFPlanBox Instance CORE/sram2_u_SRAM_4096_12 \
    255.56 255.80 1034.28 706.60
dbSet [dbGet top.insts.name CORE/sram2_u_SRAM_4096_12 -p].orient R180
deselectAll
# right bottom
setObjFPlanBox Instance CORE/sram3_u_SRAM_4096_12 \
    1064.28 255.80 1843.00 706.60
dbSet [dbGet top.insts.name CORE/sram3_u_SRAM_4096_12 -p].orient R180
deselectAll

addHaloToBlock {15 15 15 15} -allMacro
saveDesign CHIP_floorplan.inn
scan [dbGet top.fPlan.box] "{%f %f %f %f}" x1 y1 x2 y2
set w [expr $x2 - $x1]
set h [expr $y2 - $y1]
puts "[expr $w * $h] um2"