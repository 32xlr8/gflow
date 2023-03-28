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
# Filename: templates/project_template.2023/blocks/block_template/config.out.gf
# Purpose:  Check input data flow
################################################################################

########################################
# Main options
########################################

# Tool initialization scripts
gf_source "../../project.common.gf"
gf_source "./block.common.gf"
gf_source "./block.files.gf"

########################################
# Flow steps
########################################

# Generate MMMC and OCV configuration
gf_create_step -name gconfig_procs_generate_files '

    # Write corner section
    proc gf_write_corners_config {FH analysis_views} {
        
        # Get qrc corners from signoff views list
        set index {}
        puts $FH "# Each line contains: qrc_corner qrc_tech_file"
        puts $FH "set QRC_CORNERS {"
        foreach view $analysis_views {
            set name [lindex $view 4]
                        
            # Add qrc corner once
            if {[lsearch -exact $index $name] == -1} {
                lappend index $name
                puts $FH "    {$name} {[gconfig::get_files qrc -view [list * * * * $name *]]}"
            }
        }
        puts $FH "}\n"
        
        # Get extraction corners from signoff views list
        set index {}
        puts $FH "# Each line contains: extraction_corner qrc_corner temperature"
        puts $FH "set EXTRACTION_CORNERS {"
        foreach view $analysis_views {
            set name [gconfig::get extract_corner_name -view $view]
                        
            # Add extraction corner once
            if {[lsearch -exact $index $name] == -1} {
                lappend index $name
                puts $FH "    {[gconfig::get extract_corner_name -view $view]} {[lindex $view 4]} {[gconfig::get temperature -view $view]}"
            }
        }
        puts $FH "}\n"
    }

    # Timing config files
    proc gf_write_timing_configs {timing_sets} {
        upvar TASK_NAME TASK_NAME
        set is_ok 1
        try {
            foreach {tag analysis_views} $timing_sets {
                exec rm -f ./out/$TASK_NAME.$tag.timing.ocv.tcl ./out/$TASK_NAME.$tag.timing.mmmc.tcl
                gconfig::get_ocv_commands -views $analysis_views -dump_to_file ./out/$TASK_NAME.$tag.timing.ocv.tcl
                gconfig::get_mmmc_commands -views $analysis_views -dump_to_file ./out/$TASK_NAME.$tag.timing.mmmc.tcl

                set FH [open "./out/$TASK_NAME.$tag.timing.tcl" w]
                puts $FH ""
                puts $FH "set CONFIG_DIR \"\[file dirname \[info script\]\]\""
                puts $FH ""
                puts $FH "set MMMC_FILE \"\$CONFIG_DIR/$TASK_NAME.$tag.timing.mmmc.tcl\""
                puts $FH "set OCV_FILE \"\$CONFIG_DIR/$TASK_NAME.$tag.timing.ocv.tcl\""
                puts $FH ""
                gf_write_corners_config $FH $analysis_views

                close $FH
            }
        } on error {result options} {
            set is_ok 0
            puts "\033\[41;31m \033\[0m $result"
        }
        if {!$is_ok} {
            puts "\nTiming config files generation failed"
        } else {
            puts "\nTiming config files generated successfully"
        }
        return $is_ok
    }
    
    # Power config files
    proc gf_write_power_configs {power_sets} {
        upvar TASK_NAME TASK_NAME
        set is_ok 1
        try {
            foreach {tag power_set} $power_sets {
                set FH [open "./out/$TASK_NAME.$tag.power.tcl" w]
                puts $FH "set CONFIG_DIR \"\[file dirname \[info script\]\]\""
                puts $FH ""

                # Analysis views
                set analysis_views_index {}
                set analysis_views {}
                foreach {var view} $power_set {
                    try {
                        
                        # RC variables only
                        if {[lsearch -exact {PGV_RC_CORNER} $var] >= 0} {
                            puts $FH "set ${var}_QRC_FILE {[gconfig::get_files qrc -view $view]}"
                            puts $FH "set ${var}_TEMPERATURE {[gconfig::get temperature -view $view]}"
                            puts $FH ""

                        # Extraction corners
                        } elseif {[lsearch -exact {SIGNAL_SPEF_CORNER POWER_SPEF_CORNER} $var] >= 0} {
                            puts $FH "set ${var} {[gconfig::get extract_corner_name -view $view]}"
                            puts $FH ""
                            lappend analysis_views $view

                        # MMMC views
                        } elseif {[lsearch -exact {STATIC_POWER_VIEW DYNAMIC_POWER_VIEW SIGNAL_EM_VIEW} $var] >= 0} {
                            set name [gconfig::get analysis_view_name -view $view]
                            puts $FH "set ${var}_MMMC_FILE \"\$CONFIG_DIR/$TASK_NAME.$tag.power.mmmc.$name.tcl\""
                            puts $FH "set ${var}_OCV_FILE \"\$CONFIG_DIR/$TASK_NAME.$tag.power.ocv.$name.tcl\""
                            puts $FH ""

                            if {[lsearch -exact $analysis_views_index $name] < 0} {
                                lappend analysis_views_index $name
                                gconfig::get_ocv_commands -views [list $view] -dump_to_file ./out/$TASK_NAME.$tag.power.ocv.$name.tcl
                                gconfig::get_mmmc_commands -views [list $view] -dump_to_file ./out/$TASK_NAME.$tag.power.mmmc.$name.tcl
                            }
                            lappend analysis_views $view
                            
                        # MMMC views and RC variables
                        } elseif {[lsearch -exact {STATIC_RAIL_VIEW DYNAMIC_RAIL_VIEW} $var] >= 0} {
                            set name [gconfig::get analysis_view_name -view $view]
                            puts $FH "set ${var}_QRC_FILE {[gconfig::get_files qrc -view $view]}"
                            puts $FH "set ${var}_TEMPERATURE {[gconfig::get temperature -view $view]}"
                            puts $FH "set ${var}_MMMC_FILE \"\$CONFIG_DIR/$TASK_NAME.$tag.power.mmmc.$name.tcl\""
                            puts $FH "set ${var}_OCV_FILE \"\$CONFIG_DIR/$TASK_NAME.$tag.power.ocv.$name.tcl\""
                            puts $FH ""

                            if {[lsearch -exact $analysis_views_index $name] < 0} {
                                lappend analysis_views_index $name
                                gconfig::get_ocv_commands -views [list $view] -dump_to_file ./out/$TASK_NAME.$tag.power.ocv.$name.tcl
                                gconfig::get_mmmc_commands -views [list $view] -dump_to_file ./out/$TASK_NAME.$tag.power.mmmc.$name.tcl
                            }
                            lappend analysis_views $view
                            
                        # Unknown type
                        } else {
                            puts "\033\[41;31m \033\[0m Unknown $var corner/view type"
                            set is_ok 0
                        }
                        
                    } on error {result options} {
                        set is_ok 0
                        puts "\033\[41;31m \033\[0m $result"
                    }
                }

                puts $FH ""
                gf_write_corners_config $FH $analysis_views

                close $FH
            }
        } on error {result options} {
            set is_ok 0
            puts "\033\[41;31m \033\[0m $result"
        }
        if {!$is_ok} {
            puts "\nPower config files generation failed"
        } else {
            puts "\nPower config files generated successfully"
        }
        return $is_ok
    }
'

########################################
# Frontend configuration
########################################

gf_create_task -name ConfigFrontend
gf_set_task_command "tclsh ./scripts/$TASK_NAME.tcl"

# TCL commands
gf_add_tool_commands -comment '#' -file "./scripts/$TASK_NAME.tcl" '
    set TASK_NAME {`$TASK_NAME`}

    # Configuration
    `@init_gconfig`
    `@gconfig_technology_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`

    # Analysis views to generate
    `@gconfig_settings_frontend`
    
    # Print out variables summary
    gconfig::show_variables

    # Show all defined and active switches
    gconfig::show_switches

    # Generation procs
    `@gconfig_procs_generate_files`

    # Error flag
    set is_ok 1

    # Generate timing configuration
    if {[info vars TIMING_SETS] != ""} {
        if {![gf_write_timing_configs $TIMING_SETS]} { set is_ok 0 }
    }
    
    # Generate power configuration
    if {[info vars POWER_SETS] != ""} {
        if {![gf_write_power_configs $POWER_SETS]} { set is_ok 0 }
    }

    # Browse log on error
    if {!$is_ok} {
        exec less +G -R ./logs/$TASK_NAME.log > /dev/tty
    }
'

# Dump the result to the main log
gf_add_status_marks 'ERROR:' 'WARNING:' 'no such file' 'cannot access' '^invalid' 'mNo file'

# Failed marks processing
gf_add_success_marks 'files generated successfully'
gf_add_failed_marks 'files generation failed'

# Run task
gf_submit_task

########################################
# Backend configuration
########################################

gf_create_task -name ConfigBackend
gf_set_task_command "tclsh ./scripts/$TASK_NAME.tcl"

# TCL commands
gf_add_tool_commands -comment '#' -file "./scripts/$TASK_NAME.tcl" '
    set TASK_NAME {`$TASK_NAME`}

    # Configuration
    `@init_gconfig`
    `@gconfig_technology_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`

    # Analysis views to generate
    `@gconfig_settings_backend`
    
    # Print out variables summary
    gconfig::show_variables

    # Show all defined and active switches
    gconfig::show_switches

    # Generation procs
    `@gconfig_procs_generate_files`

    # Error flag
    set is_ok 1

    # Generate timing configuration
    if {[info vars TIMING_SETS] != ""} {
        if {![gf_write_timing_configs $TIMING_SETS]} { set is_ok 0 }
    }
    
    # Generate power configuration
    if {[info vars POWER_SETS] != ""} {
        if {![gf_write_power_configs $POWER_SETS]} { set is_ok 0 }
    }

    # Browse log on error
    if {!$is_ok} {
        exec less +G -R ./logs/$TASK_NAME.log > /dev/tty
    }
'

# Dump the result to the main log
gf_add_status_marks 'ERROR:' 'WARNING:' 'no such file' 'cannot access' '^invalid' 'mNo file'

# Failed marks processing
gf_add_success_marks 'files generated successfully'
gf_add_failed_marks 'files generation failed'

# Run task
gf_submit_task

########################################
# Signoff configuration
########################################

gf_create_task -name ConfigSignoff
gf_set_task_command "tclsh ./scripts/$TASK_NAME.tcl"

# TCL commands
gf_add_tool_commands -comment '#' -file "./scripts/$TASK_NAME.tcl" '
    set TASK_NAME {`$TASK_NAME`}

    # Configuration
    `@init_gconfig`
    `@gconfig_technology_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`

    # Analysis views to generate
    `@gconfig_settings_signoff`
    
    # Print out variables summary
    gconfig::show_variables

    # Show all defined and active switches
    gconfig::show_switches

    # Generation procs
    `@gconfig_procs_generate_files`

    # Error flag
    set is_ok 1

    # Generate timing configuration
    if {[info vars TIMING_SETS] != ""} {
        if {![gf_write_timing_configs $TIMING_SETS]} { set is_ok 0 }
    }
    
    # Generate power configuration
    if {[info vars POWER_SETS] != ""} {
        if {![gf_write_power_configs $POWER_SETS]} { set is_ok 0 }
    }

    # Browse log on error
    if {!$is_ok} {
        exec less +G -R ./logs/$TASK_NAME.log > /dev/tty
    }
'

# Dump the result to the main log
gf_add_status_marks 'ERROR:' 'WARNING:' 'no such file' 'cannot access' '^invalid' 'mNo file'

# Failed marks processing
gf_add_success_marks 'files generated successfully'
gf_add_failed_marks 'files generation failed'

# Run task
gf_submit_task
