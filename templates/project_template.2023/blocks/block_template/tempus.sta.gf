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
# Filename: templates/project_template.2023/blocks/block_template/tempus.sta.gf
# Purpose:  Batch signoff STA flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source "../../project.common.gf"
gf_source "../../project.tempus.gf"
gf_source "../../project.innovus.gf"
gf_source "../../project.quantus.gf"
gf_source "./block.common.gf"
gf_source "./block.files.gf"
gf_source "./block.tempus.gf"
gf_source "./block.innovus.gf"
gf_source "./block.quantus.gf"

########################################
# Innovus data out
########################################

# Write out reference data
gf_create_task -name Init
gf_use_innovus

# Select Innovus database to analyze from latest available if $DATABASE is empty
gf_spacer
gf_choose_file_dir_task -variable DATABASE -prompt "Please select database or active task:" -keep -dirs '
    ../work_*/*/out/Route*.innovus.db
    ../work_*/*/out/Assemble*.innovus.db
    ../work_*/*/out/ECO*.innovus.db
' -want -active -task_to_file '$RUN/out/$TASK.innovus.db' -tasks '
    ../work_*/*/tasks/Route*
    ../work_*/*/tasks/ECO*
    ../work_*/*/tasks/Assemble*
'

gf_info "Innovus database \e[32m$DATABASE\e[0m selected"

# Select dummy fill to use when empty
if [ -n "$QUANTUS_DUMMY_TOP" -a -z "$QUANTUS_DUMMY_GDS" ]; then
    gf_spacer
    gf_choose -variable USE_DUMMY_GDS -keep -keys YN -time 30 -default Y -prompt "Do you want to use dummy fill GDS (Y/N)?"

    # Select dummy fill to use when required
    if [ "$USE_DUMMY_GDS" == "Y" ]; then
        gf_spacer
        gf_choose_file_dir_task -variable QUANTUS_DUMMY_GDS -keep -prompt "Please select dummy fill to use:" -files '
            ../work_*/*/out/Fill*.gds
        ' -want -active -task_to_file '$RUN/out/$TASK.gds' -tasks '
            ../work_*/*/tasks/Fill*
        '
        gf_info "Metal fill GDS \e[32m$QUANTUS_DUMMY_GDS\e[0m selected"
    fi
fi
[[ "$USE_DUMMY_GDS" != "Y" ]] && QUANTUS_DUMMY_GDS=""

# Check if input database exists
gf_check_file "$DATABASE"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set DATABASE {`$DATABASE`}
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set GDS_FILES {`$GDS_FILES`}
    set NETLIST_EXCLUDE_CELLS {`$NETLIST_EXCLUDE_CELLS`}
    set DUMMY_TOP {`$QUANTUS_DUMMY_TOP`}
    set DUMMY_GDS {`$QUANTUS_DUMMY_GDS`}

    # Read input Innovus database
    read_db -no_timing $DATABASE
    
    # Remember database
    exec ln -nsf $DATABASE ./in/$TASK_NAME.innovus.db

    # Top level design name
    set DESIGN_NAME [get_db current_design .name]
    
    # Create input file commands for Standalone Quantus
    set FH [open "./out/$TASK_NAME.init_quantus.ccl" w]
    
        # Commands to read in LEF files
        puts $FH "input_db -type def -lef_file_list \\\n    [join $LEF_FILES " \\\n    "]\n"
        
        # Commands to read in GDS files
        if {[llength $GDS_FILES] > 0} {
            puts $FH "input_db -type def -gds_file_list \\\n    [join $GDS_FILES " \\\n    "]\n"
        }
        
        # Design DEF file
        puts $FH "input_db -type def -design_file \\\n    ./out/$TASK_NAME.full.def.gz\n"

        # Command to read in metal fill
        if {$DUMMY_GDS != {}} {
            puts $FH "graybox -type layout"
            puts $FH "input_db -type metal_fill -metal_fill_top_cell $DUMMY_TOP -gds_file \\\n    $DUMMY_GDS\n"
            puts $FH "metal_fill -type \"floating\""
        }
        
        # Global nets
        puts $FH "global_nets -nets [regsub -all {([\[\]])} [concat [get_db init_power_nets] [get_db init_ground_nets]] {\\\1}]\n"    

        # Corners to extract
        puts $FH "process_technology \\\n    -technology_library_file ./lib.defs \\\n    -technology_name qrc_tech_lib \\"
        puts $FH "    -technology_corner \\\n        [join $qrc_corners " \\\n        "] \\"
        puts $FH "    -temperature \\\n        [join $qrc_temperatures " \\\n        "]\n"
        
        # Output file names
        puts $FH "output_db \\\n    -type spef \\\n    -hierarchy_delimiter \"/\" \\\n    -output_incomplete_nets true \\\n    -output_unrouted_nets true \\\n    -subtype \"starN\" \\\n    -user_defined_file_name \\\n        [join $spef_files " \\\n        "]\n"

    close $FH
    
    # Create input file commands for Standalone Quantus
    set FH [open "./out/$TASK_NAME.init_tempus.tcl" w]
        puts $FH "set DESIGN_NAME {$DESIGN_NAME}"
    close $FH

    # Write out LEF
    if {[catch {set top_layer [get_db route_design_top_routing_layer]}]} {set top_layer [get_db design_top_routing_layer]}
    write_lef_abstract ./out/$TASK_NAME.lef -no_cut_obs -top_layer $top_layer -stripe_pins -pg_pin_layers $top_layer

    # Write full design in DEF format
    write_def -scan_chain -netlist -floorplan -io_row -routing -with_shield -all_layers ./out/$TASK_NAME.full.def.gz

    # Write netlist for STA
    if {$NETLIST_EXCLUDE_CELLS != ""} {
        write_netlist -exclude_insts_of_cells [get_db [get_db base_cells $NETLIST_EXCLUDE_CELLS] .name] -top_module_first -top_module $DESIGN_NAME ./out/$TASK_NAME.v
    } else {
        write_netlist -top_module_first -top_module $DESIGN_NAME ./out/$TASK_NAME.v
    }
    
    # Write small design in DEF format
    write_def ./out/$TASK_NAME.lite.def.gz

    # Exit interactive session
    exit
'

# Task summary
gf_add_status_marks ^Writing

# Run task
gf_submit_task

########################################
# Quantus extraction
########################################

gf_create_task -name Extraction -mother Init
gf_use_quantus_batch

# Shell commands to initialize environment
gf_add_shell_commands -init "

    # Copy required files
    cp -f ./out/$MOTHER_TASK_NAME.lib.defs ./lib.defs
    cp -f ./out/$MOTHER_TASK_NAME.corner.defs ./corner.defs
    cp -f ./out/$MOTHER_TASK_NAME.init_quantus.ccl ./init_quantus.ccl
    
    # Clean previous results
    rm -f ./$TASK_NAME*.spef.gz
"

# Quantus CCL commands
gf_add_tool_commands '
    
    # Initialize tool environment
    `@quantus_pre_init_design_technology`
    `@quantus_pre_init_design`
    
    # Load script generated in mother task
    include ./init_quantus.ccl

    output_setup -directory_name ./ -compressed true
    log_file -dump_options true -max_warning_messages 100
'

# Move SPEF files to output directory
gf_add_shell_commands -post "bash -e ./scripts/$TASK_NAME.move.sh"
gf_add_tool_commands -ext .move.sh "
    for file in *.spef.gz; do
        mv \$file ./out/$TASK_NAME.\$file
        ln -nsf ./out/$TASK_NAME.\$file \$file
    done
"

# Run task
gf_submit_task

########################################
# Tempus STA
########################################

gf_create_task -name STA
gf_use_tempus

# Want for extraction to complete
gf_want_tasks Extraction -variable SPEF_TASKS

# Choose configuration file
gf_choose_file_dir_task -variable TEMPUS_TIMING_CONFIG_FILE -keep -prompt "Please select timing configuration file:" -files '
    ../data/*.timing.tcl
    ../data/*/*.timing.tcl
    ../work_*/*/out/ConfigSignoff*.timing.tcl
'

# Choose configuration file
gf_choose_file_dir_task -variable DATA_OUT_CONFIG_FILE -keep -prompt "Please select design configuration file:" -files '
    ../data/*.design.tcl
    ../data/*/*.design.tcl
    ../work_*/*/out/DataOutPhysical*.design.tcl
'

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}
    set SPEF_TASKS {`$SPEF_TASKS`}
    set IGNORE_IO_TIMING {`$IGNORE_IO_TIMING`}
    set GCONFIG_FILE {`$GCONFIG_FILE}
    set DATA_OUT_CONFIG_FILE {`$DATA_OUT_CONFIG_FILE}
    set TIMING_CONFIG_FILE {`$TEMPUS_TIMING_CONFIG_FILE`}
    
    # Load configuration variables
    source $TIMING_CONFIG_FILE

    # Load configuration files
    source $GCONFIG_FILE
    source $DATA_OUT_CONFIG_FILE
    
    # Start metric collection
    `@collect_metrics`

    # Pre-load settings
    `@tempus_pre_read_libs`
    
    # Initialize power and ground nets
    set_db init_power_nets [join $POWER_NETS]
    set_db init_ground_nets [join $GROUND_NETS]

    # Load MMMC configuration
    read_mmmc $MMMC_FILE

    # Read physical information defined in project config
    read_physical -lefs [join $LEF_FILES]
    
    # Load netlist
    read_netlist ./out/$MOTHER_TASK_NAME.v -top $DESIGN_NAME
    
    # Initialize design with MMMC configuration
    init_design
    
    # Load OCV configuration
    redirect -tee ./reports/$TASK_NAME.ocv.rpt {
        reset_timing_derate
        source $OCV_FILE
    }
    report_timing_derate > ./reports/$TASK_NAME.derate.rpt
    
    # Initialize tool environment
    `@tempus_post_init_design_technology`
    `@tempus_post_init_design`

    # Read parasitics
    `@procs_tempus_read_data`
    gf_read_parasitics $SPEF_TASKS
    
    # Path groups for analysis
    if {[catch create_basic_path_groups]} {
        set registers [all_registers]
        group_path -name reg2reg -from $registers -to $registers
    }

    # Switch to propagated clocks mode
    if {$IGNORE_IO_TIMING == "Y"} {
        set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
        reset_propagated_clock [get_clocks *] 
        set_propagated_clock [get_clocks *] 
        set_interactive_constraint_mode {}
    } else {
        update_io_latency
    }

    # Timing analysis
    `@reports_sta_tempus`
    
    # Report collected metrics
    `@report_metrics`
        
    # Close interactive session
    exit
'

# # Postprocess timing summary file
# gf_add_shell_commands -post '
    # cat ./reports/$TASK_NAME/timing.summary | perl -e '"'"'
        # my $view = "";
        # my $type = "";
        # while (<STDIN>) {
            # if (/View:(\w+)/) {
                # $view = $1;
                # $type = "";
                # print "  | $view\n";
            # } elsif ($view ne "") {
                # if (/GroupType:(\w+)/) {
                    # $type = $1;
                # } elsif ($type ne "") {
                    # s/\s+/ /g;
                    # if (s/[-\d\.]+:[-\d\.]+:[-\d\.]+\s+[-\d\.]+:[-\d\.]+:[-\d\.]+\s+[-\d\.]+:[-\d\.]+:[-\d\.]+\s+([-\d\.]+):([-\d\.]+):([-\d\.]+)\s+[-\d\.]+:[-\d\.]+:[-\d\.]+\s+/sprintf("%7s:%-7s:%-10s", $1, $2, $3)/ge) {
                        # # print "  | ".sprintf("%-10s", $type)." $_\n";
                        # print "  | $_\n";
                    # }
                # }
            # }
        # }
    # '"'"'
# '

# Failed if some files not found
gf_add_failed_marks '^\*\*ERROR:.\+file.\+not'

# # Print summary
# gf_add_status_marks '(Group|View) : '  'Check : .*[1-9\-]' 
# gf_add_status_marks -1 +1 '^# (SETUP|HOLD|DRV)' '^  \|'

# Run task
gf_submit_task

########################################
# Tempus data out step
########################################

gf_create_task -name Data -mother Init
gf_use_tempus

# Want for extraction to complete
gf_want_tasks Extraction -variable SPEF_TASKS

# Choose configuration file
gf_choose_file_dir_task -variable TEMPUS_TIMING_CONFIG_FILE -keep -prompt "Please select timing configuration file:" -files '
    ../data/*.timing.tcl
    ../data/*/*.timing.tcl
    ../work_*/*/out/ConfigSignoff*.timing.tcl
'

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}
    set SPEF_TASKS {`$SPEF_TASKS`}
    set MMMC_FILE {`$MMMC_FILE`}
    set OCV_FILE "[regsub {\.mmmc\.tcl$} $MMMC_FILE {}].ocv.tcl"

    # Ignore IMPESI-3490
    eval_legacy {setDelayCalMode -sgs2set abortCdbMmmcFlow:false}

    # Get top level design name from Innovus database
    source ./out/$MOTHER_TASK_NAME.init_tempus.tcl

    # Initialize power and ground nets
    set_db init_power_nets [join $POWER_NETS]
    set_db init_ground_nets [join $GROUND_NETS]

    # Load MMMC configuration
    read_mmmc $MMMC_FILE

    # Read physical information defined in project config
    read_physical -lefs [join $LEF_FILES]
    
    # Load netlist
    read_netlist ./out/$MOTHER_TASK_NAME.v -top $DESIGN_NAME
    
    # Initialize design with MMMC configuration
    init_design
    
    # Load OCV configuration
    reset_timing_derate
    source $OCV_FILE
    
    # Initialize tool environment
    `@tempus_post_init_design_technology`
    `@tempus_post_init_design`

    # Read parasitics
    `@procs_tempus_read_data`
    gf_read_parasitics $SPEF_TASKS
    
    # Switch to propagated clocks mode
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    reset_propagated_clock [get_clocks *] 
    set_propagated_clock [get_clocks *] 
    set_interactive_constraint_mode {}
        
    # Write SDF file
    write_sdf ./out/$::TASK_NAME.sdf \
        -min_view <PLACEHOLDER>analysis_view_name \
        -typical_view <PLACEHOLDER>analysis_view_name \
        -max_view <PLACEHOLDER>analysis_view_name \
        -edges noedge -interconnect all -no_derate \
        -version 3.0

    # Write liberty models
    proc gf_write_timing_models {{min_transition 0.002} {min_load 0.010}} {
        set setup_views [get_db [get_db analysis_views -if .is_setup] .name]
        set hold_views [get_db [get_db analysis_views -if .is_hold] .name]
        set merged_views {}
        foreach view [concat $setup_views $hold_views] {
            if {[lsearch -exact $merged_views $view] == -1} {
                lappend merged_views $view
            }
        }
        set_analysis_view -setup $merged_views -hold $merged_views
        foreach view $merged_views {
            write_timing_model \
                -view $view \
                -include_power_ground \
                -input_transitions [list \
                    $min_transition \
                    [expr 3*$min_transition] \
                    [expr 8*$min_transition] \
                    [expr 21*$min_transition] \
                    [expr 55*$min_transition] \
                    [expr 144*$min_transition] \
                    [expr 377*$min_transition] \
                ] \
                -output_loads [list \
                    0.000 \
                    $min_load \
                    [expr 3*$min_load] \
                    [expr 8*$min_load] \
                    [expr 21*$min_load] \
                    [expr 55*$min_load] \
                    [expr 144*$min_load]\
                ] \
                ./out/$::TASK_NAME.$view.lib
        }
    }

    # Write out netlist for simulation
    proc gf_write_netlist {netlist_exclude_cells} {
        write_netlist -exclude_insts_of_cells [get_db [get_db base_cells $netlist_exclude_cells] .name] -top_module_first -top_module $::DESIGN_NAME ./out/$::TASK_NAME.v
    }

    # Save copy of the netlist
    exec cp ./out/$MOTHER_TASK_NAME.v ./out/$TASK_NAME.v
    exec gzip ./out/$TASK_NAME.v

    # Close interactive session
    exit
'

# Failed if some files not found
gf_add_failed_marks '^\*\*ERROR:.\+file.\+not'

# Print summary
gf_add_status_marks 'SDF file' '^TAMODEL'

# Run task
gf_submit_task
