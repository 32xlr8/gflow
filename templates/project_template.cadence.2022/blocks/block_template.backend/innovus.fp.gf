#!../../gflow/bin/gflow

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
# Filename: templates/project_template.cadence.2022/blocks/block_template.backend/innovus.fp.gf
# Purpose:  Interactive floorplan creation flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source "../../project.common.gf"
gf_source "../../project.innovus.gf"
gf_source "./block.common.gf"
gf_source "./block.files.gf"
gf_source "./block.innovus.gf"

# Close main window when done and avoid rewrite
gf_set_flow_options -auto_close -hide -continue

########################################
# Interactive floorplan task
########################################

gf_create_task -name Floorplan
gf_use_innovus

# Ask user if need to load timing information
gf_spacer
gf_choose -variable TIMING_MODE -keys YN -time 30 -default Y -prompt "Do you want to initialize timing information (Y/N)?"
gf_spacer

# Choose netlist if not chosen
gf_choose_file_dir_task -variable NETLIST -keep -prompt "Please select netlist:" -files "
    ../data/*/*.v.gz
    ../data/*/*.v
    ../work_*/*/out/SynMap*.v
    ../work_*/*/out/SynOpt*.v
"

# Choose floorplan if not chosen
gf_choose_file_dir_task -variable FLOORPLAN -keep -prompt "Please select floorplan (optional):" -files "
    ../data/*/*.fp
    ../work_*/*/out/*.fp
"

# Create floorplan files copy in the run directory
[[ -n "$FLOORPLAN" ]] && gf_save_files -copy $(dirname $FLOORPLAN)/$(basename $FLOORPLAN .gz)*

# Innovus TCL commands as is (commands in SINGLE quotes will not substitute GF shell variables)
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set NETLIST {`$NETLIST`}
    set SCANDEF {`$SCANDEF -optional`}
    set CPF {`$CPF -optional`}
    set UPF {`$UPF -optional`}
    set FLOORPLAN {`$FLOORPLAN`}
    set DESIGN_NAME {`$DESIGN_NAME`}
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_IO -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_IO -optional`}
    set TIMING_MODE {`$TIMING_MODE`}
    set IMPLEMENTATION_VIEWS {`$IMPLEMENTATION_VIEWS`}

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Initialize procs and gconfig
    source ./scripts/$TASK_NAME.procs.tcl
    
    # Generate and read MMMC and OCV files 
    if {$TIMING_MODE == "Y"} {
        gconfig::get_mmmc_commands -views $IMPLEMENTATION_VIEWS -dump_to_file ./scripts/$TASK_NAME.mmmc.tcl
        gconfig::get_ocv_commands -views $IMPLEMENTATION_VIEWS -dump_to_file ./scripts/$TASK_NAME.ocv.tcl
        read_mmmc ./scripts/$TASK_NAME.mmmc.tcl
    }

    # Initialize power and ground nets
    set_db init_power_nets [join $POWER_NETS]
    set_db init_ground_nets [join $GROUND_NETS]

    # Read physical information defined in project config
    read_physical -lefs [join $LEF_FILES]

    # Read netlist for current design
    read_netlist $NETLIST -top $DESIGN_NAME

    # Initialize library and design information
    init_design

    # Read CPF power intent information
    if {[file exists $CPF]} {
        read_power_intent -cpf $CPF
    }

    # Read 1801 power intent information
    if {[file exists $UPF]} {
        read_power_intent -1801 $UPF
    }

    # Apply power intent
    if {[file exists $CPF] || [file exists $UPF]} {
        commit_power_intent
        foreach delay_corner [get_db delay_corners] {
            set timing_condition [get_db $delay_corner .late_timing_condition.name]
            foreach power_domain [get_db power_domains] {
                append timing_condition " [get_db $power_domain .name]@[get_db $delay_corner .late_timing_condition.name]"
            }
            update_delay_corner -name [get_db $delay_corner .name] -timing_condition $timing_condition
        }
        
    # Error if CPF is incorrect
    } elseif {$CPF != {}} {
        puts "\033\[41;31m \033\[0m CPF $CPF not found"
        suspend
    
    # Error if UPF is incorrect
    } elseif {$UPF != {}} {
        puts "\033\[41;31m \033\[0m UPF $UPF not found"
        suspend
    }
    
    # Read initial floorplan if exists
    if {[file exists $FLOORPLAN]} {
        read_floorplan $FLOORPLAN
        check_floorplan
    } else {
        puts "\033\[43m \033\[0m Floorplan $FLOORPLAN not found"
    }

    # Read scan chain info
    if {[file exists $SCANDEF]} {
        read_def $SCANDEF
        
    # Continue even if scan chains are empty
    } else {
        puts "\033\[43m \033\[0m Scan definition $SCANDEF not found"
        set_db place_global_ignore_scan false
    }
    
    # Stage-specific options    
    if {$TIMING_MODE == "Y"} {
        `@innovus_post_init_design`
        reset_timing_derate
        source ./scripts/$TASK_NAME.ocv.tcl
        
    # Physical only mode
    } else {
        `@innovus_post_init_design_physical_mode`
    }
        
    # Stage-specific options    
    `@innovus_pre_floorplan`

    # Check cells with missing LEF files
    gf_innovus_check_missing_cells
    
    gui_show
    gui_fit
    gui_set_draw_view fplan
'

# Separate procs script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.procs.tcl '

    # Common tool procedures
    `@procs_innovus_common`
    `@procs_innovus_interactive_design`
    `@procs_innovus_eco_design`

    # Initialize Generic Config environment
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_design_settings`

    `@gconfig_cadence_mmmc_files`

    # Procedure to save new floorplan into block data directory
    proc gf_write_golden_floorplan {} {
        uplevel 1 {
            puts "Writing golden floorplan $FLOORPLAN ..."
            write_floorplan $FLOORPLAN
            write_def -floorplan -io_row -routing $FLOORPLAN.def
        }
    }
'

# Run task
gf_submit_task
