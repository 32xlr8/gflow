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
# Filename: templates/technology_template.2023/technology.common.gf
# Purpose:  Technology configuration for Generic Config toolkit
################################################################################

gf_info "Loading technology-specific configuration steps ..."

# On Chip Variation configuration
gf_create_step -name gconfig_ocv_settings '

    # Regular OCV requirements
    # Views mask is {<constraint_mode> <process> <voltage> <temperature> <rc_corner> <check>}
    gconfig::add_section {

        # Flat OCV mode margins (process derates and uncertainty)
        -when flat_derates {
            # -views {* tt 1p000v * * s} {$cell_data +0.0 $cell_early -0.0 $cell_late +0.0 $process_uncertainty 0}
            # -views {* tt 1p000v * * h} {$cell_data -0.0 $cell_early -0.0 $cell_late +0.0 $process_uncertainty 0}
            -views {* ss 0p900v * * s} {$cell_data +0.0 $cell_early -0.0 $cell_late +0.0 $process_uncertainty 0}
            -views {* ss 0p900v * * h} {$cell_data -0.0 $cell_early -0.0 $cell_late +0.0 $process_uncertainty 0}
            -views {* ff 1p100v * * h} {$cell_data -0.0 $cell_early -0.0 $cell_late +0.0 $process_uncertainty 0}
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
            # -views {* tt 1p000v * * *} {$setup_uncertainty 0 $hold_uncertainty 0}
            -views {* ss 0p900v * * *} {$setup_uncertainty 0 $hold_uncertainty 0}
            -views {* ff 1p100v * * *} {$setup_uncertainty 0 $hold_uncertainty 0}
        }
    }

    # # Cell pattern to check missing dV/dT derates
    # gconfig::add_section {
    #     $check_derates_pattern {*BWP*}
    # }
    #
    # # Voltage and temperature OCV requirements
    # # - Default IR-drop value for voltage OCV to be defined in block.common.gf
    # # - Derate tables: <cell pattern> <voltage-drop table> <dV derate table> <dT> <reference PDF>
    # # - Views mask is {<constraint_mode> <process> <voltage> <temperature> <rc_corner> <check>}
    # # - Run ./gflow/templates/technology_template.2023/create_tsmc_vt_tables.sh ./TSMCHOME/digital/Front_End/*/ utility to get it from PDF
    # gconfig::add_section {
    #     -views {* <PLACEHOLDER>pvt_p <PLACEHOLDER>pvt_v <PLACEHOLDER>pvt_t * *} $cells_IR_dV_dT_table {
    #         { <PLACEHOLDER>cells pattern {<PLACEHOLDER>IR-drop values} {<PLACEHOLDER>voltage derates}  {<PLACEHOLDER>temperature derate} {PDF}}
    #     }
    # }
'

# MMMC configuration
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
        -views {* * * 105 * *} 105
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
        -views {* tt * * * *} {$pvt_p {tt TT typical nominal nom}}
        -views {* ss * * * *} {$pvt_p {ssgnp ssg ss SSGNP SSG SS slow worst wc}}
        -views {* ff * * * *} {$pvt_p {ffgnp ffg ff FFGNP FFG FF fast best bc}}

        # Voltage variants to use in file name patterns
        -views {* * 0p500v * * *} {$pvt_v {0.5 0.50 0.500 0p500v 0p50v 0p5v}}
        -views {* * 0p550v * * *} {$pvt_v {0.55 0.550 0p550v 0p55v}}
        -views {* * 0p600v * * *} {$pvt_v {0.6 0.60 0.600 0p600v 0p60v 0p6v}}

        -views {* * 0p540v * * *} {$pvt_v {0.54 0.540 0p540v 0p54v}}
        # -views {* * 0p600v * * *} {$pvt_v {0.6 0.60 0.600 0p600v 0p60v 0p6v}}
        -views {* * 0p660v * * *} {$pvt_v {0.66 0.660 0p660v 0p66v}}

        -views {* * 0p630v * * *} {$pvt_v {0.63 0.630 0p630v 0p63v}}
        -views {* * 0p700v * * *} {$pvt_v {0.7 0.70 0.700 0p700v 0p70v 0p7v}}
        -views {* * 0p770v * * *} {$pvt_v {0.77 0.770 0p770v 0p77v}}

        -views {* * 0p675v * * *} {$pvt_v {0.675 0p675v}}
        -views {* * 0p750v * * *} {$pvt_v {0.75 0.750 0p750v 0p75v}}
        -views {* * 0p825v * * *} {$pvt_v {0.825 0p825v}}

        -views {* * 0p720v * * *} {$pvt_v {0.72 0.720 0p720v 0p72v}}
        -views {* * 0p800v * * *} {$pvt_v {0.8 0.80 0.800 0p800v 0p80v 0p8v}}
        -views {* * 0p880v * * *} {$pvt_v {0.88 0.880 0p880v 0p88v}}

        -views {* * 0p810v * * *} {$pvt_v {0.81 0.810 0p810v 0p81v}}
        -views {* * 0p900v * * *} {$pvt_v {0.9 0.90 0.900 0p900v 0p90v 0p9v}}
        -views {* * 0p990v * * *} {$pvt_v {0.99 0.990 0p990v 0p99v}}

        -views {* * 0p765v * * *} {$pvt_v {0.765 0p765v}}
        -views {* * 0p850v * * *} {$pvt_v {0.85 0.850 0p850v 0p85v}}
        -views {* * 0p935v * * *} {$pvt_v {0.935 0p935v}}

        # -views {* * 0p900v * * *} {$pvt_v {0.9 0.90 0.900 0p900v 0p90v 0p9v}}
        -views {* * 1p000v * * *} {$pvt_v {1 1.0 1.00 1.000 1p000v 1p00v 1p0v 1v}}
        -views {* * 1p050v * * *} {$pvt_v {1.05 1.050 1p050v 1p05v}}
        
        # -views {* * 0p900v * * *} {$pvt_v {0.9 0.90 0.900 0p900v 0p90v 0p9v}}
        # -views {* * 1p000v * * *} {$pvt_v {1 1.0 1p000v 1p00v 1p0v 1v}}
        -views {* * 1p100v * * *} {$pvt_v {1.1 1.10 1.100 1p100v 1p10v 1p1v}}
        
        # -views {* * 0p990v * * *} {$pvt_v {0.99 0.990 0p990v 0p99v}}
        # -views {* * 1p100v * * *} {$pvt_v {1.1 1.10 1.100 1p100v 1p10v 1p1v}}
        -views {* * 1p200v * * *} {$pvt_v {1.2 1.20 1.200 1p200v 1p20v 1p2v}}

        # -views {* * 1p100v * * *} {$pvt_v {1.1 1.10 1.100 1p100v 1p10v 1p1v}}
        # -views {* * 1p200v * * *} {$pvt_v {1.2 1.20 1.200 1p200v 1p20v 1p2v}}
        -views {* * 1p300v * * *} {$pvt_v {1.3 1.30 1.300 1p300v 1p30v 1p3v}}

        -views {* * 1p260v * * *} {$pvt_v {1.26 1.260 1p260v 1p26v}}
        -views {* * 1p400v * * *} {$pvt_v {1.4 1.40 1.400 1p400v 1p40v 1p4v}}
        -views {* * 1p540v * * *} {$pvt_v {1.54 1.540 1p540v 1p54v}}

        # Temperature variants to use in file name patterns
        -views {* * * m60 * *} {$pvt_t {m60 m60c n60c}}
        -views {* * * m40 * *} {$pvt_t {m40 m40c n40c}}
        -views {* * *   0 * *} {$pvt_t {0 0c}}
        -views {* * *  25 * *} {$pvt_t {25 25c}}
        -views {* * *  85 * *} {$pvt_t {85 85c}}
        -views {* * * 105 * *} {$pvt_t {105 105c}}
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
        -views {* * * *   cb *} {$qrc {CMIN     bc   cb   cbest       cbest_CCBest                            cbest/Tech/cbest_CCbest}}
        -views {* * * *  cbt *} {$qrc {              cbt  cbest_T     cbest_T_CCBest      cbest_CCbest_T      cbest/Tech/cbest_CCbest_T}}
        -views {* * * *   cw *} {$qrc {CMAX     wc   cw   cworst      cworst_CCWorst                          cworst/Tech/cworst_CCworst}}
        -views {* * * *  cwt *} {$qrc {              cwt  cworst_T    cworst_T_CCworst    cworst_CCworst_T    cworst/Tech/cworst_CCworst_T}}
        -views {* * * *  rcb *} {$qrc {RCMIN         rcb  rcbest      rcbest_CCBest                           rcbest/Tech/rcbest_CCbest}}
        -views {* * * * rcbt *} {$qrc {              rcbt rcbest_T    rcbest_T_CCBest     rcbest_CCbest_T     rcbest/Tech/rcbest_CCbest_T}}
        -views {* * * *  rcw *} {$qrc {RCMAX         rcw  rcworst     rcworst_CCWorst                         rcworst/Tech/rcworst_CCworst}}
        -views {* * * * rcwt *} {$qrc {              rcwt rcworst_T   rcworst_T_CCWorst   rcworst_CCworst_T   rcworst/Tech/rcworst_CCworst_T}}
        -views {* * * *   ct *} {$qrc {RCTYP    nom  ct   typical     Typical             typical/Tech/typical}}
        
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

    # On Chip Variation
    `@gconfig_ocv_settings`
'
