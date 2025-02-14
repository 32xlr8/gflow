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
# Filename: templates/project.2025/blocks/template/innovus.fp.gf
# Purpose:  Interactive floorplan creation flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.innovus.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.innovus.gf"

# Close main window when done and avoid rewrite
gf_set_flow_options -auto_close -hide -continue

########################################
# Interactive floorplan task
########################################

gf_create_task -name Floorplan
gf_use_innovus

# Netlist to implement
gf_choose_file_dir_task -variable INNOVUS_NETLIST_FILES -keep -prompt "Choose netlist:" -files '
    ../data/*.v.gz
    ../data/*.v
    ../data/*/*.v.gz
    ../data/*/*.v
    ../work_*/*/out/SynMap*.v
    ../work_*/*/out/SynOpt*.v
'

# Innovus floorplan
gf_choose_file_dir_task -variable INNOVUS_FLOORPLAN_FILE -prompt "Choose floorplan (optional):" -files '
    `$INNOVUS_FLOORPLAN_FILE`
    ../data/*.fp
    ../data/*.fp.gz
    ../data/*/*.fp
    ../data/*/*.fp.gz
    ./*/out/*.fp
'

# Ask user if need to load timing information
gf_spacer
gf_choose -variable TIMING_MODE -keys YN -time 30 -default N -prompt "Initialize timing information (Y/N)?"
gf_spacer

# Innovus TCL commands as is (commands in SINGLE quotes will not substitute GF shell variables)
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES` `$PARTITIONS_LEF_FILES -optional`}
    set NETLIST_FILES {`$INNOVUS_NETLIST_FILES`}
    set SCANDEF_FILE {`$INNOVUS_SCANDEF_FILE -optional`}
    set CPF_FILE {`$CPF_FILE -optional`}
    set UPF_FILE {`$UPF_FILE -optional`}
    set FLOORPLAN_FILE {`$INNOVUS_FLOORPLAN_FILE`}
    set DESIGN_NAME {`$DESIGN_NAME`}
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}
    set TIMING_MODE {`$TIMING_MODE`}

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Procedure to read last floorplan
    set FLOORPLAN_FILE_LAST $FLOORPLAN_FILE
    proc gf_read_floorplan_last {} {
        puts "\033\[42m \033\[0m Reading floorplan $::FLOORPLAN_FILE_LAST ..."
        read_floorplan $::FLOORPLAN_FILE_LAST
    }
    
    # Procedure to overwrite last floorplan
    proc gf_write_floorplan_last {} {
        puts "\033\[42m \033\[0m Writing floorplan $::FLOORPLAN_FILE_LAST ..."
        write_floorplan $::FLOORPLAN_FILE_LAST
    }
    
    # Procedure to save new floorplan into block data directory
    proc gf_write_floorplan_global {{tag {}}} {
        upvar gf_fp_date gf_fp_date
        upvar gf_fp_index gf_fp_index
        set base "../../../../data/[exec date +%y%m%d]"
        set auto_tag "[expr int(0.5+[get_db current_design .bbox.ur.x]-[get_db current_design .bbox.ll.x])]x[expr int(0.5+[get_db current_design .bbox.ur.y]-[get_db current_design .bbox.ll.y])]"
        if {$tag == ""} {
            set tag $auto_tag
        } elseif {[regexp {^\+} $tag]} {
            set tag "$auto_tag.[regsub {^\+} $tag {}]"
        }
        puts "\033\[42m \033\[0m Writing floorplan $base.$tag.fp ..."
        set ::FLOORPLAN_FILE_LAST $base.$tag.fp
        write_floorplan $base.$tag.fp
    }
    
    # Procedure to save new floorplan into block data directory
    proc gf_write_floorplan_def_global {{tag {}}} {
        upvar gf_fp_date gf_fp_date
        upvar gf_fp_index gf_fp_index
        set base "../../../../data/[exec date +%y%m%d]"
        set auto_tag "[expr int(0.5+[get_db current_design .bbox.ur.x]-[get_db current_design .bbox.ll.x])]x[expr int(0.5+[get_db current_design .bbox.ur.y]-[get_db current_design .bbox.ll.y])]"
        if {$tag == ""} {
            set tag $auto_tag
        } elseif {[regexp {^\+} $tag]} {
            set tag "$auto_tag.[regsub {^\+} $tag {}]"
        }
        puts "\033\[42m \033\[0m Writing DEF $base.$tag.fp.def.gz ..."
        write_def -floorplan -io_row -routing $base.$tag.fp.def.gz
    }
    
    # Generate and read MMMC and OCV files 
    if {$TIMING_MODE == "Y"} {
        source ./scripts/$TASK_NAME.gconfig.tcl
        read_mmmc ./in/$TASK_NAME.mmmc.tcl
    }

    # Initialize power and ground nets
    set_db init_power_nets [join $POWER_NETS]
    set_db init_ground_nets [join $GROUND_NETS]

    # Read physical information defined in project config
    read_physical -lefs [join $LEF_FILES]

    # Read netlist for current design
    read_netlist [join $NETLIST_FILES] -top $DESIGN_NAME
    puts "Netlist files: [join $NETLIST_FILES]"

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
        write_floorplan ./in/$TASK_NAME.fp.gz
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
    
    # Load common tool procedures
    source ./scripts/$TASK_NAME.procs.tcl

    # Stage-specific options    
    if {$TIMING_MODE == "Y"} {
        `@innovus_post_init_design`

        # Load OCV configuration
        redirect -tee ./reports/$TASK_NAME.ocv.rpt {
            reset_timing_derate
            source ./in/$TASK_NAME.ocv.tcl
        }
        
    # Physical only mode
    } else {
        `@innovus_post_init_design_physical_mode`
    }

    # Stage-specific options    
    `@innovus_pre_floorplan`

    # Check cells with missing LEF files
    `@innovus_check_missing_cells`

    # Show available scripts
    gf_show_scripts

    # Enable rectilinear floorplanning
    set_preference EnableRectilinearDesign 1

    gui_show
    gui_fit
    gui_set_draw_view fplan
'

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands '
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@innovus_gconfig_design_settings`
    
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
    `@innovus_procs_common`
    `@innovus_procs_interactive_design`
    `@innovus_procs_eco_design`
'

# Run task
gf_submit_task
