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
# Filename: templates/project_template.2023/blocks/block_template/gconfig.mmmc.gf
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
gf_create_step -name generate_mmmc_files '
    try {
        foreach {TAG ANALYSIS_VIEWS} $MMMC_SETS {
            exec rm -f ./out/$TASK_NAME.$TAG.ocv.tcl ./out/$TASK_NAME.$TAG.mmmc.tcl
            gconfig::get_ocv_commands -views $ANALYSIS_VIEWS -dump_to_file ./out/$TASK_NAME.$TAG.ocv.tcl
            gconfig::get_mmmc_commands -views $ANALYSIS_VIEWS -dump_to_file ./out/$TASK_NAME.$TAG.mmmc.tcl
        }
        puts "\nMMMC generated successfully"

    } on error {result options} {
        puts "\nMMMC generation failed"
        exec less +G -R ./logs/$TASK_NAME.log > /dev/tty
    }
'

# Generate MMMC and OCV configuration
gf_create_step -name generate_quantus_files '
    try {
        foreach {TAG ANALYSIS_VIEWS} $MMMC_SETS {
        
            # Get qrc/extract corners from signoff views list
            set unique_qrc_corners {}
            set extract_corners {}
            set qrc_temperatures {}
            set qrc_corners {}
            set spef_files {}
            foreach view $ANALYSIS_VIEWS {
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
            
            exec rm -f ./out/$TASK_NAME.$TAG.corner.defs ./out/$TASK_NAME.$TAG.lib.defs

            # Create corner definition file for Standalone Quantus
            set FH [open "./out/$TASK_NAME.$TAG.corner.defs" w]
                foreach corner $unique_qrc_corners {
                    puts $FH "DEFINE $corner [file dirname [gconfig::get_files qrc -view [list * * * * $corner *]]]"
                }
            close $FH
            
            # Create library definition file for Standalone Quantus
            set FH [open "./out/$TASK_NAME.$TAG.lib.defs" w]
                puts $FH "DEFINE qrc_tech_lib ."
            close $FH
        }

        puts "\nMMMC generated successfully"

    } on error {result options} {
        puts "\nMMMC generation failed"
        exec less +G -R ./logs/$TASK_NAME.log > /dev/tty
    }
'

########################################
# Frontend MMMC generation
########################################

gf_create_task -name FrontendMMMC
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

    # Generate MMMC and OCV configuration
    `@generate_mmmc_files`
'

# Dump the result to the main log
gf_add_status_marks 'ERROR:' 'WARNING:' 'no such file' 'cannot access' '^invalid' 'mNo file'

# Failed marks processing
gf_add_success_marks 'MMMC generated successfully'

# Run task
gf_submit_task

########################################
# Backend MMMC generation
########################################

gf_create_task -name BackendMMMC
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

    # Generate MMMC and OCV configuration
    `@generate_mmmc_files`
'

# Dump the result to the main log
gf_add_status_marks 'ERROR:' 'WARNING:' 'no such file' 'cannot access' '^invalid' 'mNo file'

# Failed marks processing
gf_add_success_marks 'MMMC generated successfully'

# Run task
gf_submit_task

########################################
# Signoff MMMC generation
########################################

gf_create_task -name SignoffMMMC
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

    # Generate MMMC and OCV configuration
    `@generate_mmmc_files`
    
    # Generate additional signoff tools files
    `@generate_quantus_files`
'

# Dump the result to the main log
gf_add_status_marks 'ERROR:' 'WARNING:' 'no such file' 'cannot access' '^invalid' 'mNo file'

# Failed marks processing
gf_add_success_marks 'MMMC generated successfully'

# Run task
gf_submit_task
