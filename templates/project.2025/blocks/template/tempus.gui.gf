#!../../gflow/bin/gflow

################################################################################
# Generic Flow v5.5.2 (February 2025)
################################################################################
#
# Copyright 2011-2025 Gennady Kirpichev (https://github.com/32xlr8/gflow.git)
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
# Filename: templates/project.2025/blocks/template/tempus.gui.gf
# Purpose:  Interactive Tempus debug flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.tempus.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.tempus.gf"

# Basic flow script options
gf_set_flow_options -continue -incr -auto_close -hide

########################################
# Tempus STA
########################################

gf_create_task -name DebugTempus
gf_use_tempus

# Design data directory
gf_choose_file_dir_task -variable DATA_OUT_DIR -keep -prompt "Choose design data directory:" -dirs '
    ../work_*/*/out/InnovusOut*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/InnovusOut*
'

# SPEF directory
gf_choose_file_dir_task -variable SPEF_OUT_DIR -keep -prompt "Choose SPEF directory:" -dirs '
    ../work_*/*/out/QuantusOut*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/QuantusOut*
'

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES` `$PARTITIONS_LEF_FILES -optional`}

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}

    set DATA_OUT_DIR {`$DATA_OUT_DIR`}
    set SPEF_OUT_DIR {`$SPEF_OUT_DIR`}
    set PARTITIONS_NETLIST_FILES {`$PARTITIONS_NETLIST_FILES -optional`}

    # Use separate Generic Config script
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Load common tool procedures
    source ./scripts/$TASK_NAME.procs.tcl

    # Pre-load settings
    `@tempus_pre_read_libs`
    
    # Initialize power and ground nets
    set_db init_power_nets [join $POWER_NETS]
    set_db init_ground_nets [join $GROUND_NETS]

    # Load MMMC configuration
    read_mmmc ./in/$TASK_NAME.mmmc.tcl

    # Read physical information defined in project config
    read_physical -lefs [join $LEF_FILES]
    
    # Read netlist files
    set files $DATA_OUT_DIR/$DESIGN_NAME.v.gz
    foreach file $PARTITIONS_NETLIST_FILES {lappend files $file}
    foreach file $files {
        if {[file exists $file]} {
            puts "Netlist file: $file"
            lappend files $file
        } else {
            puts "\033\[41m \033\[0m Netlist file $file not found"
            suspend
        }
    }
    read_netlist $files -top $DESIGN_NAME
    
    # Initialize design with MMMC configuration
    init_design
    
    # Load OCV configuration
    redirect -tee ./reports/$TASK_NAME.ocv.rpt {
    reset_timing_derate
        source ./in/$TASK_NAME.ocv.tcl
    }
    redirect ./reports/$TASK_NAME.derate.rpt {report_timing_derate}
    
    # Initialize tool environment
    `@tempus_post_init_design_project`
    `@tempus_post_init_design`
    `@procs_tempus_reports`
    
    # Read design parasitics files
    set processed {}; set missing 0
    foreach view $MMMC_VIEWS {
        set rc_corner [gconfig::get extract_corner_name -view $view]
        if {[lsearch -exact $processed $rc_corner] < 0} {
            lappend processed $rc_corner
            set files $SPEF_OUT_DIR/$DESIGN_NAME.$rc_corner.spef.gz
            foreach file [gconfig::get_files spef -view $view] {lappend files $file}
            foreach file $files {
                if {[file exists $file]} {
                    puts "SPEF file: $file"
                } else {
                    puts "\033\[41m \033\[0m SPEF file $file not found"
                    incr missing
                }
            }
            if {$missing == 0} {
                read_spef -rc_corner $rc_corner $files
            }
        }
    }
    if {$missing > 0} {
        puts "\033\[41m \033\[0m SPEF files not found for some RC corners"
        suspend
    }
    report_annotated_parasitics > ./reports/$TASK_NAME.annotation.rpt
    puts [exec cat ./reports/$TASK_NAME.annotation.rpt]

    # Path groups for analysis
    if {[catch create_basic_path_groups]} {
        set registers [all_registers]
        group_path -name reg2reg -from $registers -to $registers
    }

    # Switch to propagated clocks mode
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    reset_propagated_clock [get_clocks *] 
    set_propagated_clock [get_clocks *] 
    set_interactive_constraint_mode {}

'

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands '
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@tempus_gconfig_design_settings`
    
    # Print out summary
    gconfig::show_variables
    gconfig::show_switches

    # Generate timing configuration
    try {
        gconfig::get_ocv_commands -views $MMMC_VIEWS -dump_to_file ./in/$TASK_NAME.ocv.tcl
        gconfig::get_mmmc_commands -views $MMMC_VIEWS -dump_to_file ./in/$TASK_NAME.mmmc.tcl

    # Suspend on error
    } on error {result options} {
        exec rm -f ./in/$TASK_NAME.ocv.tcl ./in/$TASK_NAME.mmmc.tcl
        puts "\033\[41;31m \033\[0m $result"
        suspend
    }
'

# Common tool procedures
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.procs.tcl '
    `@tempus_procs_common`
    `@procs_tempus_read_data`
'

# Run task
gf_submit_task
