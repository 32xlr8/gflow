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
# Filename: templates/project_template.2023/blocks/block_template/voltus.rail.gf
# Purpose:  Batch power and rail analysis flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source "../../project.common.gf"
gf_source "../../project.voltus.gf"
gf_source "../../project.quantus.gf"
gf_source "../../project.innovus.gf"
gf_source "./block.common.gf"
gf_source "./block.files.gf"
gf_source "./block.voltus.gf"
gf_source "./block.quantus.gf"
gf_source "./block.innovus.gf"

########################################
# Innovus data out
########################################

gf_create_task -name Init
gf_use_innovus

# Select Innovus database to analyze from latest available if $DATABASE is empty
gf_spacer
gf_choose_file_dir_task -variable DATABASE -keep -prompt "Please select database or active task:" -dirs '
    ../work_*/*/out/Route*.innovus.db
    ../work_*/*/out/Assemble*.innovus.db
    ../work_*/*/out/ECO*.innovus.db
    ../work_*/*/out/*.innovus.db
' -want -active -task_to_file '$RUN/out/$TASK.innovus.db' -tasks '
    ../work_*/*/tasks/Route*
    ../work_*/*/tasks/ECO*
    ../work_*/*/tasks/Assemble*
' 

gf_info "Innovus database \e[32m$DATABASE\e[0m selected"

# Check if input database exists
gf_check_file "$DATABASE"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set DATABASE {`$DATABASE`}
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set SPEF_VIEWS {`$POWER_SPEF_CORNER` `$SIGNAL_SPEF_CORNER`}
    set NETLIST_EXCLUDE_CELLS {`$PROJECT_NETLIST_EXCLUDE_CELLS` `$BLOCK_NETLIST_EXCLUDE_CELLS`}

    # Read input Innovus database
    read_db -no_timing $DATABASE

    # Remember database
    exec ln -nsf $DATABASE ./in/$TASK_NAME.innovus.db

    # Top level design name
    set DESIGN_NAME [get_db current_design .name]

    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Get qrc/extract corners from signoff views list
    set unique_qrc_corners {}
    set extract_corners {}
    set qrc_temperatures {}
    set qrc_corners {}
    set spef_files {}
    foreach view $SPEF_VIEWS {
        set qrc_corner [lindex $view 4]
        set extract_corner [gconfig::get extract_corner_name -view $view]

        # Add qrc corner once
        if {[lsearch -exact $unique_qrc_corners $qrc_corner] == -1} {
            lappend unique_qrc_corners $qrc_corner
        }

        # Add extraction corner once
        if {[lsearch -exact $extract_corners $extract_corner] == -1} {
            lappend extract_corners $extract_corner
            lappend qrc_temperatures [gconfig::get temperature -view $view]
            lappend qrc_corners [lindex $view 4]
            lappend spef_files [gconfig::get extract_corner_name -view $view].spef
        }
    }

    # Create corner definition file for Standalone Quantus
    set FH [open "./out/$TASK_NAME.corner.defs" w]
        foreach corner $unique_qrc_corners {
            puts $FH "DEFINE $corner [file dirname [gconfig::get_files qrc -view [list * * * * $corner *]]]"
        }
    close $FH

    # Create library definition file for Standalone Quantus
    set FH [open "./out/$TASK_NAME.lib.defs" w]
        puts $FH "DEFINE qrc_tech_lib ."
    close $FH

    # Create input file commands for Standalone Quantus
    set FH [open "./out/$TASK_NAME.init_quantus.ccl" w]

        # Commands to read in LEF files
        puts $FH "input_db -type def -lef_file_list \\\n    [join $LEF_FILES " \\\n    "]\n"

        # Design DEF file
        puts $FH "input_db -type def -design_file \\\n    ./out/$TASK_NAME.full.def.gz\n"

        # Global nets
        puts $FH "global_nets -nets [regsub -all {([\[\]])} [concat [get_db init_power_nets] [get_db init_ground_nets]] {\\\1}]\n"    

        # Corners to extract
        puts $FH "process_technology \\\n    -technology_library_file ./lib.defs \\\n    -technology_name qrc_tech_lib \\"
        puts $FH "    -technology_corner \\\n        [join $qrc_corners " \\\n        "] \\"
        puts $FH "    -temperature \\\n        [join $qrc_temperatures " \\\n        "]\n"

        # Output file names
        puts $FH "output_db \\\n    -type spef \\\n    -hierarchy_delimiter \"/\" \\\n    -output_incomplete_nets true \\\n    -output_unrouted_nets true \\\n    -subtype \"starN\" \\\n    -user_defined_file_name \\\n        [join $spef_files " \\\n        "]\n"

    close $FH

    # Write out PP file based on bumps, ports or stripes location
    foreach net [concat [get_db init_power_nets] [get_db init_ground_nets]] {
        set count 0
        set FH [open "./out/$TASK_NAME.$net.pp" w]
        
        # Bumps - 1st priority
        foreach bump [get_db bumps -if .net.name==$net] {
            incr count
            puts $FH "[get_db $bump .name] [get_db $bump .center.x] [get_db $bump .center.y] [get_db $bump .bump_pins.layer.name]"
        }
        
        # Pads - 2nd priority
        if {$count < 1} {
            set route_index -1
            set top_layer {}
            set pg_pins [get_db -u pg_pins -if .inst.base_cell.class==pad&&.net.name==$net]
            foreach check_layer [get_db [get_db -u $pg_pins .pg_base_pin.physical_pins.layer_shapes -if .shapes.type==rect] .layer -u] {
                set check_index [get_db $check_layer .route_index]
                if {$check_index > $route_index} {
                    set route_index $check_index
                    set top_layer $check_layer
                }
            }
            if {$top_layer != {}} {
                foreach pg_pin $pg_pins {
                    foreach shape [get_db -u [get_db -u $pg_pin .pg_base_pin.physical_pins.layer_shapes -if .layer==$top_layer] .shapes -if .type==rect] {
                        incr count
                        set xy [list [expr ([get_db $shape .rect.ll.x]+[get_db $shape .rect.ur.x])/2.0] [expr ([get_db $shape .rect.ll.y]+[get_db $shape .rect.ur.y])/2.0]]
                        puts $FH "[get_db $top_layer .name]_$count [get_transform_shapes -cell [get_db $pg_pin .inst.base_cell.name] -pt [get_db $pg_pin .inst.location] -orient [get_db $pg_pin .inst.orient] -local_pt $xy] [get_db $top_layer .name]"
                        set is_pp_found 1
                    }
                }
            }
        }

        # Ports - 3rd priority
        if {$count < 1} {
            foreach shape [get_db port_shapes -if .port.net.name==$net] {
                incr count
                puts $FH "[get_db $shape .layer.name]_$count [expr ([get_db $shape .rect.ll.x]+[get_db $shape .rect.ur.x])/2] [expr ([get_db $shape .rect.ll.y]+[get_db $shape .rect.ur.y])/2] [get_db $shape .layer.name]"
                set is_pp_found 1
            }
        }

        # Stripes - 4th priority
        if {$count < 1} {
            set route_index -1
            set top_layer {}
            set shapes [get_db [get_db nets $net] .special_wires -if .shape==stripe]
            foreach check_layer [get_db $shapes .layer -u] {
                set check_index [get_db $check_layer .route_index]
                if {$check_index > $route_index} {
                    set route_index $check_index
                    set top_layer $check_layer
                }
            }
            if {$top_layer != {}} {
                foreach shape [get_db [get_db nets $net] .special_wires -if .layer==$top_layer] {
                    incr count
                    puts $FH "[get_db $top_layer .name]_$count [get_db $shape .rect.ll.x] [get_db $shape .rect.ll.y] [get_db $top_layer .name]"
                    incr count
                    puts $FH "[get_db $top_layer .name]_$count [get_db $shape .rect.ur.x] [get_db $shape .rect.ur.y] [get_db $top_layer .name]"
                    set is_pp_found 1
                }
            }
        }
        close $FH
    }

    # Write design in DEF format
    write_def -scan_chain -netlist -floorplan -io_row -routing -with_shield -all_layers ./out/$TASK_NAME.full.def.gz
    write_def -netlist ./out/$TASK_NAME.lite.def.gz

    # Write netlist for power analysis
    if {$NETLIST_EXCLUDE_CELLS != ""} {
        write_netlist -exclude_insts_of_cells [get_db [get_db base_cells $NETLIST_EXCLUDE_CELLS] .name] -top_module_first -top_module $DESIGN_NAME ./out/$TASK_NAME.v.gz
    } else {
        write_netlist -top_module_first -top_module $DESIGN_NAME ./out/$TASK_NAME.v.gz
    }
write_netlist -exclude_insts_of_cells [get_db [get_db base_cells $NETLIST_EXCLUDE_CELLS] .name] -top_module_first -top_module $DESIGN_NAME ./out/$TASK_NAME.v.gz

    # Exit interactive session
    exit
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_settings_common`

    `@gconfig_cadence_mmmc_files`
'

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
# Static power calculation
########################################

gf_create_task -name StaticPower -mother Init
gf_use_voltus

# Want for extraction to complete
gf_want_tasks Extraction -variable SPEF_TASK

# Select scenario to calculate power
gf_choose -keep -variable POWER_SCENARIO -message "Which power scenario to run?" -variants "$(echo "$POWER_SCENARIOS" | sed -e 's|^\s\+||g; s|\s\+$||g;')" -count 25

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}

    set SPEF_TASK {`$SPEF_TASK`}
    set SPEF_VIEW [lindex {`$POWER_SPEF_CORNER`} 0]
    
    set ANALYSIS_VIEW [lindex {`$STATIC_POWER_VIEW`} 0]

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_NETS {`$VOLTUS_POWER_NETS`}
    set GROUND_NETS {`$VOLTUS_GROUND_NETS`}

    set VOLTUS_ICT_EM_RULE {`$VOLTUS_ICT_EM_RULE`}
    
    set POWER_SCENARIO {`$POWER_SCENARIO`}

    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl
    
    # Load MMMC configuration
    read_mmmc ./scripts/$TASK_NAME.mmmc.tcl
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist ./out/$MOTHER_TASK_NAME.v.gz -top $DESIGN_NAME
    read_def ./out/$MOTHER_TASK_NAME.full.def.gz -skip_signal_nets 

    # Design initialization
    init_design -top $DESIGN_NAME
    `@voltus_post_init_design_technology`

    # Print info
    puts "Extraction view: $SPEF_VIEW"
    puts "Power analysis view: $ANALYSIS_VIEW"
    
    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
    # Read parasitics    
    read_spef ./out/$SPEF_TASK.[gconfig::get extract_corner_name -view $SPEF_VIEW].spef.gz
    
    # Run analysis
    `@voltus_run_report_power_static`

    # Close interactive session
    exit
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_settings_common`

    `@gconfig_cadence_mmmc_files`
    
    # Generate MMMC configuration
    gconfig::get_mmmc_commands -views [list $ANALYSIS_VIEW] -dump_to_file ./scripts/$TASK_NAME.mmmc.tcl
'

# Run task
gf_add_status_marks '\(.*MHz\)'
gf_add_success_marks 'Voltus Power Analysis exited successfully'
gf_submit_task

########################################
# Dynamic power calculation
########################################

gf_create_task -name DynamicPower -mother Init
gf_use_voltus

# Want for extraction to complete
gf_want_tasks Extraction -variable SPEF_TASK

# Select scenario to calculate power
gf_choose -keep -variable POWER_SCENARIO -message "Which power scenario to run?" -variants "$(echo "$POWER_SCENARIOS" | sed -e 's|^\s\+||g; s|\s\+$||g;')" -count 25

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}

    set SPEF_TASK {`$SPEF_TASK`}
    set SPEF_VIEW [lindex {`$POWER_SPEF_CORNER`} 0]
    set ANALYSIS_VIEW [lindex {`$DINAMIC_POWER_VIEW`} 0]

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_NETS {`$VOLTUS_POWER_NETS`}
    set GROUND_NETS {`$VOLTUS_GROUND_NETS`}

    set VOLTUS_ICT_EM_RULE {`$VOLTUS_ICT_EM_RULE`}
    
    set POWER_SCENARIO {`$POWER_SCENARIO`}

    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl
    
    # Print info
    puts "Extraction view: $SPEF_VIEW"
    puts "Power analysis view: $ANALYSIS_VIEW"
    
    # Load MMMC configuration
    read_mmmc ./scripts/$TASK_NAME.mmmc.tcl
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist ./out/$MOTHER_TASK_NAME.v.gz -top $DESIGN_NAME
    read_def ./out/$MOTHER_TASK_NAME.full.def.gz -skip_signal_nets 

    # Design initialization
    init_design -top $DESIGN_NAME
    `@voltus_post_init_design_technology`
    
    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
    # Read parasitics    
    read_spef ./out/$SPEF_TASK.[gconfig::get extract_corner_name -view $SPEF_VIEW].spef.gz
    
    # Run analysis
    `@voltus_run_report_power_dynamic`

    # Close interactive session
    exit
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_settings_common`

    `@gconfig_cadence_mmmc_files`
    
    # Generate MMMC configuration
    gconfig::get_mmmc_commands -views [list $ANALYSIS_VIEW] -dump_to_file ./scripts/$TASK_NAME.mmmc.tcl
'

# Run task
gf_add_success_marks 'Voltus Power Analysis exited successfully'
gf_submit_task

########################################
# Static IR-drop calculation
########################################

gf_create_task -name StaticIR -mother Init
gf_use_voltus

# Want for extraction and power analysis to complete
gf_want_tasks StaticPower -variable STATIC_POWER_TASK

# Select PGV to analyze if empty
gf_choose_file_dir_task -variable VOLTUS_PGV_LIBS -keep -prompt "Please select PGV libraries:" -dirs '
    ../work_*/*/out/Tech*.cl
'
gf_info "Selected PGV libraries: \e[32m$VOLTUS_PGV_LIBS\e[0m selected"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}

    set POWER_TASK {`$STATIC_POWER_TASK`}
    set ANALYSIS_VIEW [lindex {`$STATIC_POWER_VIEW`} 0]

    set SPEF_VIEW [lindex {`$STATIC_RAIL_VIEW`} 0]

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_NETS {`$VOLTUS_POWER_NETS`}
    set GROUND_NETS {`$VOLTUS_GROUND_NETS`}

    set VOLTUS_PGV_LIBS [eval glob [join {'"$(for dir in $VOLTUS_PGV_LIBS; do echo $dir/*.cl; done)"'}]]
    set VOLTUS_ICT_EM_RULE {`$VOLTUS_ICT_EM_RULE`}

    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl
    
    # Load MMMC configuration
    read_mmmc ./scripts/$TASK_NAME.mmmc.tcl
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist ./out/$MOTHER_TASK_NAME.v.gz -top $DESIGN_NAME
    read_def ./out/$MOTHER_TASK_NAME.full.def.gz -skip_signal_nets 

    # Design initialization
    init_design -top $DESIGN_NAME
    `@voltus_post_init_design_technology`
    
    # Print info
    puts "Extraction view: $SPEF_VIEW"
    puts "Power analysis view: $ANALYSIS_VIEW"
    
    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]
    
    # Internal variables
    set QRC_TECH_FILE [gconfig::get_files qrc -view $SPEF_VIEW]

    # Run analysis
    `@voltus_run_report_rail_static`
   
    # Leave session open for debug
    gui_show
    gui_set_power_rail_display -plot ivdd
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_settings_common`

    `@gconfig_cadence_mmmc_files`
    
    # Generate MMMC configuration
    gconfig::get_mmmc_commands -views [list $ANALYSIS_VIEW] -dump_to_file ./scripts/$TASK_NAME.mmmc.tcl
'

# Run task
gf_submit_task

########################################
# Dynamic IR-drop calculation
########################################

gf_create_task -name DynamicIR -mother Init
gf_use_voltus

# Want for extraction and power analysis to complete
gf_want_tasks DynamicPower -variable DYNAMIC_POWER_TASK

# Select PGV to analyze from latest available if empty
gf_choose_file_dir_task -variable VOLTUS_PGV_LIBS -keep -prompt "Please select PGV libraries:" -dirs '
    ../work_*/*/out/Tech*.cl
'
gf_info "PGV libraries \e[32m$VOLTUS_PGV_LIBS\e[0m selected"

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}

    set POWER_TASK {`$DYNAMIC_POWER_TASK`}
    set ANALYSIS_VIEW [lindex {`$DINAMIC_POWER_VIEW`} 0]

    set SPEF_VIEW [lindex {`$DINAMIC_RAIL_VIEW`} 0]

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set POWER_NETS {`$VOLTUS_POWER_NETS`}
    set GROUND_NETS {`$VOLTUS_GROUND_NETS`}

    set VOLTUS_PGV_LIBS [eval glob [join {'"$(for dir in $VOLTUS_PGV_LIBS; do echo $dir/*.cl; done)"'}]]

    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl
    
    # Load MMMC configuration
    read_mmmc ./scripts/$TASK_NAME.mmmc.tcl
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist ./out/$MOTHER_TASK_NAME.v.gz -top $DESIGN_NAME
    read_def ./out/$MOTHER_TASK_NAME.full.def.gz -skip_signal_nets 

    # Design initialization
    init_design -top $DESIGN_NAME
    `@voltus_post_init_design_technology`
    
    # Print info
    puts "Extraction view: $SPEF_VIEW"
    puts "Power analysis view: $ANALYSIS_VIEW"
    
    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]

    # Internal variables
    set QRC_TECH_FILE [gconfig::get_files qrc -view $SPEF_VIEW]

    # Run analysis
    `@voltus_run_report_rail_dynamic`

    # Leave session open for debug
    gui_show
    gui_set_power_rail_display -plot ivdd
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_settings_common`

    `@gconfig_cadence_mmmc_files`
    
    # Generate MMMC configuration
    gconfig::get_mmmc_commands -views [list $ANALYSIS_VIEW] -dump_to_file ./scripts/$TASK_NAME.mmmc.tcl
'

# Run task
gf_submit_task

########################################
# EM calculation
########################################

gf_create_task -name SignalEM -mother Init
gf_use_voltus

# Want for extraction and power analysis to complete
gf_want_tasks Extraction -variable SPEF_TASK

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}

    set SPEF_TASK {`$SPEF_TASK`}
    set SPEF_VIEW [lindex {`$SIGNAL_SPEF_CORNER`} 0]

    set ANALYSIS_VIEW [lindex {`$SIGNAL_EM_VIEW`} 0]
    
    set QRC_TECH_EM {`$QRC_TECH_EM`}
    set VOLTUS_ICT_EM_RULE {`$VOLTUS_ICT_EM_RULE`}

    set DESIGN_NAME {`$DESIGN_NAME`} 

    # Initialize Generic Config environment
    source ./scripts/$TASK_NAME.gconfig.tcl
    
    # Load MMMC configuration
    read_mmmc ./scripts/$TASK_NAME.mmmc.tcl
    
    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist ./out/$MOTHER_TASK_NAME.v.gz -top $DESIGN_NAME
    read_def ./out/$MOTHER_TASK_NAME.full.def.gz -skip_signal_nets 

    # Design initialization
    init_design -top $DESIGN_NAME
    `@voltus_post_init_design_technology`
    
    # Print info
    puts "Extraction view: $SPEF_VIEW"
    puts "Power analysis view: $ANALYSIS_VIEW"
    
    # Switch to propagated mode    
    set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
    set_propagated_clock [get_clocks *]

    # Read parasitics    
    read_spef ./out/$SPEF_TASK.[gconfig::get extract_corner_name -view $SPEF_VIEW].spef.gz
    
    # Check EM violations
    `@voltus_run_signal_em`

    # Leave session open for debug
    gui_show
'

# Separate Generic Config initialization script
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.gconfig.tcl '
    `@init_gconfig`

    `@gconfig_technology_settings`
    `@gconfig_settings_common`

    `@gconfig_cadence_mmmc_files`
    
    # Generate MMMC configuration
    gconfig::get_mmmc_commands -views [list $ANALYSIS_VIEW] -dump_to_file ./scripts/$TASK_NAME.mmmc.tcl
'

# Run task
gf_submit_task
