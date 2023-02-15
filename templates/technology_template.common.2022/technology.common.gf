################################################################################
# Generic Flow v5.0 (February 2023)
################################################################################
#
# Copyright 2011-2023 Gennady Kirpichev (https://github.com/32xlr8/gflow.git)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################
# Filename: templates/technology_template.common.2022/technology.common.gf
# Purpose:  Technology configuration for Generic Config toolkit
################################################################################

gf_info "Loading technology-specific configuration steps ..."

gf_create_step -name gconfig_technology_settings '

    ##############################
    # Variables
    ##############################

    # Technology OCV margins
    gconfig::define_variables -group "Process OCV margins" -variables {cell_data cell_early cell_late net_data net_early net_late check_derates_pattern}

    # Variables used in file names
    gconfig::define_variables -group "Project file name substitutions" {mode pvt pvt_p pvt_v pvt_t pvt_rc qrc check}

    # MMMC variables
    gconfig::define_variables -group "Process clock uncertainty" -variables {jitter process_uncertainty setup_uncertainty hold_uncertainty}

    ##############################
    # Switches
    ##############################

    # Standard cell libraries types
    gconfig::define_switches -group "MMMC libraries presets" -required -switches {nldm_libraries ecsm_libraries ccs_libraries lvf_libraries}

    # Factory uncertainty control
    gconfig::define_switches -group "OCV uncertainty preset" -optional -switches default_uncertainty

    ##############################
    # Generic Config data
    ##############################

    # Temperature values for extraction corners
    gconfig::add_extraction_temperatures {
        -views {* * * m60 * *} -60
        -views {* * * m40 * *} -40
        -views {* * *   0 * *} 0
        -views {* * *  25 * *} 25
        -views {* * *  85 * *} 85
        -views {* * * 125 * *} 125
        -views {* * * 150 * *} 150
    }

    # Variables used in file name patterns
    gconfig::add_section {
        # Views mask is {<constraint_mode> <process> <voltage> <temperature> <rc_corner> <check>}

        # Constraint mode variants to use in file name patterns
        -views {func * * * * *} {$mode func}
        -views {scan * * * * *} {$mode scan}

        # Process variants to use in file name patterns
        -views {* tt * * * *} {$pvt_p {tt TT nominal typical}}
        -views {* ss * * * *} {$pvt_p {ssgnp ssg ss SSGNP SSG SS slow worst}}
        -views {* ff * * * *} {$pvt_p {ffgnp ffg ff FFGNP FFG FF fast best}}

        # Voltage variants to use in file name patterns
        -views {* * 0p500v * * *} {$pvt_v {0p500v 0p50v 0p5v}}
        -views {* * 0p550v * * *} {$pvt_v {0p550v 0p55v}}
        -views {* * 0p600v * * *} {$pvt_v {0p600v 0p60v 0p6v}}

        -views {* * 0p540v * * *} {$pvt_v {0p540v 0p54v}}
        -views {* * 0p600v * * *} {$pvt_v {0p600v 0p60v 0p6v}}
        -views {* * 0p660v * * *} {$pvt_v {0p660v 0p66v}}

        -views {* * 0p630v * * *} {$pvt_v {0p630v 0p63v}}
        -views {* * 0p700v * * *} {$pvt_v {0p700v 0p70v 0p7v}}
        -views {* * 0p770v * * *} {$pvt_v {0p770v 0p77v}}

        -views {* * 0p675v * * *} {$pvt_v {0p675v}}
        -views {* * 0p750v * * *} {$pvt_v {0p750v 0p75v}}
        -views {* * 0p825v * * *} {$pvt_v {0p825v}}

        -views {* * 0p720v * * *} {$pvt_v {0p720v 0p72v}}
        -views {* * 0p800v * * *} {$pvt_v {0p800v 0p80v 0p8v}}
        -views {* * 0p880v * * *} {$pvt_v {0p880v 0p88v}}

        -views {* * 0p810v * * *} {$pvt_v {0p810v 0p81v}}
        -views {* * 0p900v * * *} {$pvt_v {0p900v 0p90v 0p9v}}
        -views {* * 0p990v * * *} {$pvt_v {0p990v 0p99v}}

        -views {* * 0p765v * * *} {$pvt_v {0p765v}}
        -views {* * 0p850v * * *} {$pvt_v {0p850v 0p85v}}
        -views {* * 0p935v * * *} {$pvt_v {0p935v}}

        # -views {* * 0p900v * * *} {$pvt_v {0p900v 0p90v 0p9v}}
        -views {* * 1p000v * * *} {$pvt_v {1p000v 1p00v 1p0v 1v}}
        -views {* * 1p050v * * *} {$pvt_v {1p050v 1p05v}}
        
        # -views {* * 0p990v * * *} {$pvt_v {0p990v 0p99v}}
        -views {* * 1p100v * * *} {$pvt_v {1p100v 1p10v 1p1v}}
        -views {* * 1p210v * * *} {$pvt_v {1p210v 1p21v}}

        # Temperature variants to use in file name patterns
        -views {* * * m60 * *} {$pvt_t {m60 m60c n60c}}
        -views {* * * m40 * *} {$pvt_t {m40 m40c n40c}}
        -views {* * *   0 * *} {$pvt_t {0 0c}}
        -views {* * *  25 * *} {$pvt_t {25 25c}}
        -views {* * *  85 * *} {$pvt_t {85 85c}}
        -views {* * * 125 * *} {$pvt_t {125 125c}}
        -views {* * * 150 * *} {$pvt_t {150 150c}}

        # Extraction variants to use in file name patterns
        -views {* tt * * * *} {$pvt_rc {typical_max typ.max}}
        -views {* ss * * * *} {$pvt_rc {worst_max worst.max}}
        -views {* ff * * * *} {$pvt_rc {best_min best.min}}

        # PVT corner variants to use in file name patterns
        -views {* tt *  25 * *} {$pvt {tc typ}}
        -views {* tt * 125 * *} {$pvt {tl ttth}}
        -views {* ss * m40 * *} {$pvt {wcl worstn40c}}
        -views {* ss *   0 * *} {$pvt {wcz worstzero}}
        -views {* ss * 125 * *} {$pvt {wc worst}}
        -views {* ff * m40 * *} {$pvt {lt best}}
        -views {* ff *   0 * *} {$pvt {bc bestzero}}
        -views {* ff * 125 * *} {$pvt {ml leak}}

        # QRC variants to use in file name patterns
        -views {* * * *   cb *} {$qrc {cb   cbest       cbest_CCBest                            cbest/Tech/cbest_CCbest}}
        -views {* * * *  cbt *} {$qrc {cbt  cbest_T     cbest_T_CCBest      cbest_CCbest_T      cbest/Tech/cbest_CCbest_T}}
        -views {* * * *   cw *} {$qrc {cw   cworst      cworst_CCWorst                          cworst/Tech/cworst_CCworst}}
        -views {* * * *  cwt *} {$qrc {cwt  cworst_T    cworst_T_CCworst    cworst_CCworst_T    cworst/Tech/cworst_CCworst_T}}
        -views {* * * *  rcb *} {$qrc {rcb  rcbest      rcbest_CCBest                           rcbest/Tech/rcbest_CCbest}}
        -views {* * * * rcbt *} {$qrc {rcbt rcbest_T    rcbest_T_CCBest     rcbest_CCbest_T     rcbest/Tech/rcbest_CCbest_T}}
        -views {* * * *  rcw *} {$qrc {rcw  rcworst     rcworst_CCWorst                         rcworst/Tech/rcworst_CCworst}}
        -views {* * * * rcwt *} {$qrc {rcwt rcworst_T   rcworst_T_CCWorst   rcworst_CCworst_T   rcworst/Tech/rcworst_CCworst_T}}
        -views {* * * *   ct *} {$qrc {ct   typical     Typical             typical/Tech/typical}}
        
        # STA check variants to use in file name patterns
        -views {* * * * * s} {$check {s setup}}
        -views {* * * * * {h p l d}} {$check {h hold}}
    }

    # Default OCV margins for not covered views
    gconfig::add_section {
        $cell_data 0.0 $cell_early 0.0 $cell_late 0.0
        $net_data 0.0 $net_early 0.0 $net_late 0.0
        $process_uncertainty 0 $setup_uncertainty 0 $hold_uncertainty 0
    }
    
    # Clock uncertainty commands for OCV
    #   Variable $constraint_mode_name stores automatically-given constraint mode name based on the view mask.
    #   Switch default_uncertainty identifies if uncertainty should be set manually not in SDC
    gconfig::add_clock_uncertainty_commands {
        -when default_uncertainty {
            set_interactive_constraint_mode $constraint_mode_name
            set_clock_uncertainty -setup [expr {($jitter+$process_uncertainty+$setup_uncertainty)/1000.0}] \[get_clocks \*\]
            set_clock_uncertainty -hold [expr {$hold_uncertainty/1000.0}] \[get_clocks \*\]
            puts \"INFO: Setup ${COLOR}$jitter+$process_uncertainty+$setup_uncertainty ps${NO_COLOR} and hold ${COLOR}${hold_uncertainty} ps${NO_COLOR} uncertainty applied to ${COLOR}$constraint_mode_name${NO_COLOR} constraint mode.\"
        }
    }

    # Timing derate commands for OCV configuration
    #   Variable $delay_corner_name stores automatically-given delay corner name based on the view mask.
    #   Switches flat, aocv, socv when enabled define current OCV mode.
    gconfig::add_timing_derate_commands {
        -when !no_derates {
            set_timing_derate -delay_corner $delay_corner_name -cell_delay -data [expr {1.0 + $cell_data/100.0}]
            set_timing_derate -delay_corner $delay_corner_name -cell_delay -clock -early [expr {1.0 + $cell_early/100.0}]
            set_timing_derate -delay_corner $delay_corner_name -cell_delay -clock -late [expr {1.0 + $cell_late/100.0}]
            set_timing_derate -delay_corner $delay_corner_name -net_delay -data [expr {1.0 + $net_data/100.0}]
            set_timing_derate -delay_corner $delay_corner_name -net_delay -clock -early [expr {1.0 + $net_early/100.0}]
            set_timing_derate -delay_corner $delay_corner_name -net_delay -clock -late [expr {1.0 + $net_late/100.0}]
            puts \"INFO: Flat OCV derate factors applied to delay corner ${COLOR}$delay_corner_name${NO_COLOR}.\"
        }
    }

    # Voltage and temperature OCV requirements
    gconfig::define_variables -group "Voltage/Temperature OCV margins" -variables {voltage_drop cells_IR_dV_dT_table}

    # Proc to apply IR-drop-aware OCV derates
    proc gf_apply_ir_cell_derates {IR cells_IR_dV_dT_table check_derates_pattern delay_corner_name args} {
        set derated_cells [get_db base_cells $check_derates_pattern]
        foreach row $cells_IR_dV_dT_table {
            set cells [lindex $row 0]
            set IR_row [lindex $row 1]
            set dV_row [lindex $row 2]
            set dT [lindex $row 3]
            set PDF [lindex $row 4]
            if {[llength $IR_row] < 1} {
                puts "\033\[31;41m \033\[0m ERROR: \033\[1m$cells\033\[0m IR-drop table is empty in $delay_corner_name delay corner"
            } elseif {[llength $IR_row] != [llength $dV_row]} {
                puts "\033\[31;41m \033\[0m ERROR: \033\[1m$cells\033\[0m IR-drop and dV/dT table columns number is different in $delay_corner_name delay corner"
            } else {
                if {$IR > [lindex $IR_row end]} {
                    set dV [lindex $dV_row end]
                    puts "\033\[31;41m \033\[0m ERROR: \033\[1m$cells\033\[0m IR-drop value \033\[1m${IR}\033\[0mmV is out of the range in $delay_corner_name delay corner"
                } else {
                    set dV 0
                    set IR_left 0
                    set dV_left 0
                    set index 0
                    foreach value $IR_row {
                        set IR_right $value
                        set dV_right [lindex $dV_row $index]
                        if {($IR >= $IR_left) && ($IR < $IR_right)} {
                            if {$dV_right < $dV_left} {
                                puts "\033\[31;41m \033\[0m ERROR: \033\[1m$cells\033\[0m IR-drop table is not monotonous in $delay_corner_name delay corner"
                            }
                            if {$IR_right < $IR_left} {
                                puts "\033\[31;41m \033\[0m ERROR: \033\[1m$cells\033\[0m dV/dT table is not monotonous in $delay_corner_name delay corner"
                            } 
                            if {($dV_right != $dV_left) && ($IR_right != $IR_left)} {
                                set dV [expr {0.0001*round(($dV_right-($dV_right-$dV_left)*(($IR-$IR_right)/($IR_left-$IR_right)))*10000)}]
                            }
                        }
                        set IR_left $IR_right
                        set dV_left $dV_right
                        incr index
                    }
                }
                if {[get_db base_cells $cells] != ""} {
                    foreach command $args {eval "$command"}
                    foreach base_cell [get_db [get_db base_cells $cells] .name] {
                        if {[lsearch -exact $derated_cells $base_cell]<0} {
                            lappend derated_cells $base_cell
                        } else {
                            puts "\033\[33;43m \033\[0m WARNING: \033\[1m$base_cell\033\[0m dV/dT derates applied several times in $delay_corner_name delay corner"
                        }
                    }
                }
            }
        }
        if {$check_derates_pattern == ""} {set check_derates_pattern {*}}
        foreach base_cell [get_db [get_db base_cells $check_derates_pattern] .name] {
            if {[lsearch -exact $derated_cells $base_cell]<0} {
                puts "\033\[31;41m \033\[0m ERROR: \033\[1m$base_cell\033\[0m dV/dT derates not found for $delay_corner_name delay corner"
            }
        }
    }
    
    # Timing derate commands for OCV configuration
    #   Variable $delay_corner_name stores automatically-given delay corner name based on the view mask.
    #   Variable $dV $dT and $IR are available inside gf_apply_ir_cell_derates.
    #   Switches flat, aocv, socv when enabled define current OCV mode.
    gconfig::add_timing_derate_commands {
        -when vt_derates {
        
            # Cell-specific timing derates
            -views {* {tt ss} * * * s} {
                gf_apply_ir_cell_derates {$voltage_drop} {$cells_IR_dV_dT_table} {$check_derates_pattern} {$delay_corner_name} \
                    {set_timing_derate -delay_corner {$delay_corner_name} -cell_delay -add -early \[expr -0.01*(\$dV+\$dT)\] \$cells} \
                    {puts "INFO: dV ${COLOR}\$dV\%${NO_COLOR} and dT ${COLOR}\$dT\%${NO_COLOR} early clock derate (IR-drop ${COLOR}\${IR}mV${NO_COLOR}, ${COLOR}10C${NO_COLOR}) applied to ${COLOR}\$cells${NO_COLOR} cells in ${COLOR}$delay_corner_name${NO_COLOR} delay corner."}
            }
            -views {* {tt ss} * * * h} {
                gf_apply_ir_cell_derates {$voltage_drop} {$cells_IR_dV_dT_table} {$check_derates_pattern} {$delay_corner_name} \
                    {set_timing_derate -delay_corner {$delay_corner_name} -cell_delay -add -early -data \[expr -0.01*(\$dV+\$dT)\] \$cells} \
                    {set_timing_derate -delay_corner {$delay_corner_name} -cell_delay -add -early -clock \[expr -0.01*(\$dV+\$dT)\] \$cells} \
                    {puts "INFO: dV ${COLOR}\$dV\%${NO_COLOR} and dT ${COLOR}\$dT\%${NO_COLOR} early data and clock derate (IR-drop ${COLOR}\${IR}mV${NO_COLOR}, ${COLOR}10C${NO_COLOR}) applied to ${COLOR}\$cells${NO_COLOR} cells in ${COLOR}$delay_corner_name${NO_COLOR} delay corner."}
            }
            -views {* ff * * * h} {
                gf_apply_ir_cell_derates {$voltage_drop} {$cells_IR_dV_dT_table} {$check_derates_pattern} {$delay_corner_name} \
                    {set_timing_derate -delay_corner {$delay_corner_name} -cell_delay -add -late \[expr +0.01*(\$dV+\$dT)\] \$cells} \
                    {puts "INFO: dV ${COLOR}\$dV\%${NO_COLOR} and dT ${COLOR}\$dT\%${NO_COLOR} late clock derate (IR-drop ${COLOR}\${IR}mV${NO_COLOR}, ${COLOR}10C${NO_COLOR}) applied to ${COLOR}\$cells${NO_COLOR} cells in ${COLOR}$delay_corner_name${NO_COLOR} delay corner."}
            }
        }
    }

    # Regular OCV requirements
    # Views mask is {<constraint_mode> <process> <voltage> <temperature> <rc_corner> <check>}
    gconfig::add_section {

        # Flat OCV mode margins (process derates and uncertainty)
        -when flat_derates {
            # -views {* tt 0p000v * * s} {$cell_data +0.0 $cell_early -0.0 $cell_late +0.0 $process_uncertainty 0}
            # -views {* tt 0p000v * * h} {$cell_data -0.0 $cell_early -0.0 $cell_late +0.0 $process_uncertainty 0}
            -views {* ss 0p000v * * s} {$cell_data +0.0 $cell_early -0.0 $cell_late +0.0 $process_uncertainty 0}
            -views {* ss 0p000v * * h} {$cell_data -0.0 $cell_early -0.0 $cell_late +0.0 $process_uncertainty 0}
            -views {* ff 0p000v * * h} {$cell_data -0.0 $cell_early -0.0 $cell_late +0.0 $process_uncertainty 0}
        }
        
        # Net OCV margins
        # -views {* tt * * * s} {$net_data +0.0 $net_early -0.0 $net_late +0.0}
        # -views {* tt * * * h} {$net_data -0.0 $net_early -0.0 $net_late +0.0}
        -views {* ss * * * s} {$net_data +0.0 $net_early -0.0 $net_late +0.0}
        -views {* ss * * * h} {$net_data -0.0 $net_early -0.0 $net_late +0.0}
        -views {* ff * * {cb rcb} h} {$net_data -0.0 $net_early -0.0 $net_late +0.0}
        -views {* ff * * {cw rcw} h} {$net_data -0.0 $net_early -0.0 $net_late +0.0}

        # Process clock uncertainty (without jitter) in ps
        -when default_uncertainty {
            # -views {* tt 0p000v * * *} {$setup_uncertainty 0 $hold_uncertainty 0}
            -views {* ss 0p000v * * *} {$setup_uncertainty 0 $hold_uncertainty 0}
            -views {* ff 0p000v * * *} {$setup_uncertainty 0 $hold_uncertainty 0}
        }
    }

    # # Cell pattern to check missing dV/dT derates
    # gconfig::add_section {
    #     $check_derates_pattern {*BWP*}
    # }
    #
    # # Voltage and temperature OCV requirements
    # # Default IR-drop value for voltage OCV to be defined in block.common.gf
    # # Derate tables: <cell pattern> <voltage-drop table> <dV derate table> <dT> <reference PDF>
    # # Views mask is {<constraint_mode> <process> <voltage> <temperature> <rc_corner> <check>}
    # # Run ./gflow/templates/technology_template.common.2022/create_tsmc_vt_tables.sh ./TSMCHOME/digital/Front_End/*/ utility to get it from PDF
    # gconfig::add_section {
    #     -views {* <PLACEHOLDER:pvt_p> <PLACEHOLDER:pvt_v> <PLACEHOLDER:pvt_t> * *} $cells_IR_dV_dT_table {
    #         { <PLACEHOLDER:cells pattern> {<PLACEHOLDER:IR-drop values} {<PLACEHOLDER:voltage derates>}  {<PLACEHOLDER:temperature derate>} {PDF}}
    #     }
    #     -views {* ss 0p675v 0 * *} $cells_IR_dV_dT_table {
    #         { <PLACEHOLDER:*BWP16P90CPD>  {0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0}  {0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0}  {0.0} {DB_SBOCV*.pdf}}
    #     }
    # }
'
