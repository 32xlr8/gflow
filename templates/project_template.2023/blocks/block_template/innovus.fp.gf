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
# Filename: templates/project_template.2023/blocks/block_template/innovus.fp.gf
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

# Choose netlist if not chosen
gf_choose_file_dir_task -variable NETLIST_FILES -keep -prompt "Please select netlist:" -files '
    ../data/*.v.gz
    ../data/*.v
    ../data/*/*.v.gz
    ../data/*/*.v
    ../work_*/*/out/SynMap*.v
    ../work_*/*/out/SynOpt*.v
'

# Choose floorplan if not chosen
gf_choose_file_dir_task -variable FLOORPLAN_FILE -keep -prompt "Please select floorplan (optional):" -files '
    ../data/*.fp
    ../data/*.fp.gz
    ../data/*/*.fp
    ../data/*/*.fp.gz
    ../work_*/*/out/*.fp
'

# Ask user if need to load timing information
gf_spacer
gf_choose -variable TIMING_MODE -keys YN -time 30 -default N -prompt "Do you want to initialize timing information (Y/N)?"
gf_spacer

# Choose MMMC file
if [ "$TIMING_MODE" == "Y" ]; then
    gf_choose_file_dir_task -variable MMMC_FILE -keep -prompt "Please select MMMC file:" -files '
        ../data/*.mmmc.tcl
        ../data/*/*.mmmc.tcl
        ../work_*/*/out/BackendMMMC*.mmmc.tcl
    '
else
    MMMC_FILE=""
fi

# Create floorplan files copy in the run directory
[[ -n "$FLOORPLAN_FILE" ]] && gf_save_files -copy $(dirname $FLOORPLAN_FILE)/$(basename $FLOORPLAN_FILE .gz)*

# Innovus TCL commands as is (commands in SINGLE quotes will not substitute GF shell variables)
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set NETLIST_FILES {`$NETLIST_FILES`}
    set SCANDEF_FILE {`$SCANDEF_FILE -optional`}
    set CPF_FILE {`$CPF_FILE -optional`}
    set UPF_FILE {`$UPF_FILE -optional`}
    set FLOORPLAN_FILE {`$FLOORPLAN_FILE`}
    set DESIGN_NAME {`$DESIGN_NAME`}
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}
    set TIMING_MODE {`$TIMING_MODE`}
    set MMMC_FILE {`$MMMC_FILE -optional`}
    set OCV_FILE "[regsub {\.mmmc\.tcl$} $MMMC_FILE {}].ocv.tcl"

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Procedure to save new floorplan into block data directory
    proc gf_write_floorplan_global {{tag {}}} {
        upvar gf_fp_date gf_fp_date
        upvar gf_fp_index gf_fp_index
        set base "../../../../data/[exec date +%y%m%d]"
        if {$tag != {}} {
            set base "$base.$tag"
        }
        puts "\033\[42m \033\[0m Writing floorplan $base.fp ..."
        write_floorplan $base.fp
        write_def -floorplan -io_row -routing $base.fp.def.gz
    }
    
    # Generate and read MMMC and OCV files 
    if {$TIMING_MODE == "Y"} {
        read_mmmc $MMMC_FILE
    }

    # Initialize power and ground nets
    set_db init_power_nets [join $POWER_NETS]
    set_db init_ground_nets [join $GROUND_NETS]

    # Read physical information defined in project config
    read_physical -lefs [join $LEF_FILES]

    # Read netlist for current design
    read_netlist [join $NETLIST_FILES] -top $DESIGN_NAME

    # Initialize library and design information
    init_design

    # Read CPF power intent information
    if {[file exists $CPF_FILE]} {
        read_power_intent -cpf $CPF_FILE
    }

    # Read 1801 power intent information
    if {[file exists $UPF_FILE]} {
        read_power_intent -1801 $UPF_FILE
    }

    # Apply power intent
    if {[file exists $CPF_FILE] || [file exists $UPF_FILE]} {
        commit_power_intent
        foreach delay_corner [get_db delay_corners] {
            set timing_condition [get_db $delay_corner .late_timing_condition.name]
            foreach power_domain [get_db power_domains] {
                append timing_condition " [get_db $power_domain .name]@[get_db $delay_corner .late_timing_condition.name]"
            }
            update_delay_corner -name [get_db $delay_corner .name] -timing_condition $timing_condition
        }
        
    # Error if CPF is incorrect
    } elseif {$CPF_FILE != {}} {
        puts "\033\[41;31m \033\[0m CPF $CPF_FILE not found"
        suspend
    
    # Error if UPF is incorrect
    } elseif {$UPF_FILE != {}} {
        puts "\033\[41;31m \033\[0m UPF $UPF_FILE not found"
        suspend
    }
    
    # Read initial floorplan if exists
    if {[file exists $FLOORPLAN_FILE]} {
        read_floorplan $FLOORPLAN_FILE
        check_floorplan
    } else {
        puts "\033\[43m \033\[0m Floorplan $FLOORPLAN_FILE not found"
    }

    # Read scan chain info
    if {[file exists $SCANDEF_FILE]} {
        read_def $SCANDEF_FILE
        
    # Continue even if scan chains are empty
    } else {
        if {$SCANDEF_FILE == ""} {
            puts "\033\[43m \033\[0m Scan definition file is empty"
        } else {
            puts "\033\[43m \033\[0m Scan definition $SCANDEF_FILE not found"
        }
        set_db place_global_ignore_scan false
    }
    
    # Common tool procedures
    `@innovus_procs_common`
    `@innovus_procs_interactive_design`
    `@innovus_procs_eco_design`

    # Stage-specific options    
    if {$TIMING_MODE == "Y"} {
        `@innovus_post_init_design`

        # Load OCV configuration
        reset_timing_derate
        source $OCV_FILE
        
    # Physical only mode
    } else {
        `@innovus_post_init_design_physical_mode`
    }

    # Stage-specific options    
    `@innovus_pre_floorplan`

    # Check cells with missing LEF files
    `@innovus_check_missing_cells`
    
    gui_show
    gui_fit
    gui_set_draw_view fplan
'

# Run task
gf_submit_task
