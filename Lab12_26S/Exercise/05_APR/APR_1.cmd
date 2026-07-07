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
set init_lef_file {LEF/header6_V55_20ka_cic.lef LEF/fsa0m_a_generic_core.lef LEF/FSA0M_A_GENERIC_CORE_ANT_V55.lef LEF/fsa0m_a_t33_generic_io.lef LEF/FSA0M_A_T33_GENERIC_IO_ANT_V55.lef LEF/BONDPAD.lef LEF/Linear_512X64X1BM1.lef LEF/QK_256X64X1BM1.lef LEF/weight_256X32X1BM1.lef}
set init_verilog CHIP_SYN.v
set init_mmmc_file CHIP_mmmc.view
set init_io_file CHIP.io
set init_top_cell CHIP
set init_pwr_net VCC
init_design
getIoFlowFlag
setIoFlowFlag 0
floorPlan -site core_5040 -r 1 0.5 250 250 250 250 
dbGet top.fPlan.coreBox
scan [dbGet top.fPlan.box] "{%f %f %f %f}" x1 y1 x2 y2
set w [expr $x2 - $x1]
set h [expr $y2 - $y1]
puts "[expr $w * $h] um2"

deselectAll

# ── Core boundary ──────────────────────────────
set halo  15
set cx1   390.6
set cx2   3002.04
set cy1   390.88
set cy2   2996.56

set xl [expr {$cx1 + $halo}]
set xr [expr {$cx2 - $halo}]
set yb [expr {$cy1 + $halo}]
set yt [expr {$cy2 - $halo}]

set cw [expr {$xr - $xl}]
set ch [expr {$yt - $yb}]

set W_lg 1005.02
set H_lg 294
set W_sm 542.5
set H_sm 215.6
set W_qk 994.48

###############################################################
# TOP  R0  y2=yt
###############################################################
set top_y2 $yt
set top_y1 [expr {$yt - $H_lg}]
set top_x0 [expr {$xl + ($cw - ($W_lg * 2 + $halo)) / 2.0}]

set x1 $top_x0
set x2 [expr {$top_x0 + $W_lg}]
setObjFPlanBox Instance CORE/in_img_sram $x1 $top_y1 $x2 $top_y2
dbSet [dbGet top.insts.name CORE/in_img_sram -p].orient R0
deselectAll

set x1 [expr {$top_x0 + $W_lg + $halo}]
set x2 [expr {$x1 + $W_lg}]
setObjFPlanBox Instance CORE/conv_result_sram $x1 $top_y1 $x2 $top_y2
dbSet [dbGet top.insts.name CORE/conv_result_sram -p].orient R0
deselectAll

###############################################################
# BOTTOM  R180  y1=yb
###############################################################
set bot_y1 $yb
set bot_y2 [expr {$yb + $H_lg}]
set bot_x0 $top_x0

set x1 $bot_x0
set x2 [expr {$bot_x0 + $W_lg}]
setObjFPlanBox Instance CORE/Q_sram $x1 $bot_y1 $x2 $bot_y2
dbSet [dbGet top.insts.name CORE/Q_sram -p].orient R180
deselectAll

set x1 [expr {$bot_x0 + $W_lg + $halo}]
set x2 [expr {$x1 + $W_lg}]
setObjFPlanBox Instance CORE/K_sram $x1 $bot_y1 $x2 $bot_y2
dbSet [dbGet top.insts.name CORE/K_sram -p].orient R180
deselectAll

###############################################################
# LEFT  R90  x1=xl
# V_sram: 轉後寬=H_lg=294, 高=W_lg=1005.02
# QK_sram: 轉後寬=H_sm=215.6, 高=W_qk=994.48
###############################################################
set lft_total [expr {$W_lg + $halo + $W_qk}]
set lft_y0    [expr {$yb + ($ch - $lft_total) / 2.0}]

set v_y1 $lft_y0
set v_y2 [expr {$lft_y0 + $W_lg}]
set v_x1 $xl
set v_x2 [expr {$xl + $H_lg}]
setObjFPlanBox Instance CORE/V_sram $v_x1 $v_y1 $v_x2 $v_y2
dbSet [dbGet top.insts.name CORE/V_sram -p].orient R90
deselectAll

set qk_y1 [expr {$v_y2 + $halo}]
set qk_y2 [expr {$qk_y1 + $W_qk}]
set qk_x1 $xl
set qk_x2 [expr {$xl + $H_sm}]
setObjFPlanBox Instance CORE/QK_sram $qk_x1 $qk_y1 $qk_x2 $qk_y2
dbSet [dbGet top.insts.name CORE/QK_sram -p].orient R90
deselectAll

###############################################################
# RIGHT  R270  x2=xr
# 各 SRAM: 轉後寬=H_sm=215.6, 高=W_sm=542.5
###############################################################
set rgt_total [expr {$W_sm * 3 + $halo * 2}]
set rgt_y0    [expr {$yb + ($ch - $rgt_total) / 2.0}]
set rgt_x1    [expr {$xr - $H_sm}]
set rgt_x2    $xr

set y1 $rgt_y0
set y2 [expr {$rgt_y0 + $W_sm}]
setObjFPlanBox Instance CORE/weight_sram $rgt_x1 $y1 $rgt_x2 $y2
dbSet [dbGet top.insts.name CORE/weight_sram -p].orient R270
deselectAll

set y1 [expr {$rgt_y0 + $W_sm + $halo}]
set y2 [expr {$y1 + $W_sm}]
setObjFPlanBox Instance CORE/partial_sram0 $rgt_x1 $y1 $rgt_x2 $y2
dbSet [dbGet top.insts.name CORE/partial_sram0 -p].orient R270
deselectAll

set y1 [expr {$rgt_y0 + ($W_sm + $halo) * 2}]
set y2 [expr {$y1 + $W_sm}]
setObjFPlanBox Instance CORE/partial_sram1 $rgt_x1 $y1 $rgt_x2 $y2
dbSet [dbGet top.insts.name CORE/partial_sram1 -p].orient R270
deselectAll

###############################################################
addHaloToBlock {15 15 15 15} -allMacro
deselectAll
saveDesign CHIP_floorplan.inn
scan [dbGet top.fPlan.box] "{%f %f %f %f}" x1 y1 x2 y2
set w [expr $x2 - $x1]
set h [expr $y2 - $y1]
puts "[expr $w * $h] um2"

#  foreach inst [dbGet top.insts] {
#      set cell_name [dbGet $inst.cell.name]
#      if {$cell_name == "weight_256X32X1BM1" || $cell_name == "Linear_512X64X1BM1" || $cell_name == "QK_256X64X1BM1"} {
#          puts "inst = [dbGet $inst.name]"
#          puts "cell = $cell_name"
#          puts "box  = [dbGet $inst.box]"
#          puts "--------------------------------"
#      }
#  }