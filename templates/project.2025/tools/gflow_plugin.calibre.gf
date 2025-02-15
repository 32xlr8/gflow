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
# Filename: templates/project.2025/tools/gflow_plugin.calibre.gf
# Purpose:  Generic Flow Calibre plugin
################################################################################

gf_info "Loading Calibre plugin ..."

##################################################
gf_help_section "Calibre plugin v5.5.1"
##################################################

gf_help_command '
    {gf_use_calibre_env}
    Calibre environment task preset.
'
function gf_use_calibre_env {
    gf_check_task_name

    # Shell commands to run
    gf_set_task_command "bash run.bash"
    gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
        `@init_shell_environment`
        `@init_calibre_environment`
        
        # Dump environment variables
        env > ./reports/`$TASK_NAME`.env
    '

    # Task status marks
    gf_add_status_marks 'TOTAL RESULTS' 'TOTAL RULECHECKS' 'Number of Results = [1-9]' '^ *Error:' '^ERROR:'
}

gf_help_command '
    {gf_use_calibre_drc_batch}
    Calibre DRC in batch mode task preset.
'
function gf_use_calibre_drc_batch {
    gf_check_task_name

    # Shell commands to run
    gf_set_task_command "bash run.bash"
    gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
        `@init_shell_environment`
        `@init_calibre_environment`
        
        # Dump environment variables
        env > ./reports/`$TASK_NAME`.env
        
        # Run the tool
        calibre -gui -drc -batch -runset ./scripts/`$TASK_NAME`.runset
    '

    # Default customization
    gf_add_tool_commands -comment '' -file "./scripts/$TASK_NAME.runset" '
        *drcRunDir: .
        *drcCellName: 0
        *drcStartRVE: 0
        *drcViewSummary: 0
        *drcSummaryFile: `$TASK_NAME`.sum
    '

    # Multi-CPU mode
    if [ -n "$GF_TASK_CPU" ]; then
        gf_add_tool_commands '
            *cmnNumTurbo: `$GF_TASK_CPU`
            *cmnRunMT: 1
        '
    fi
    
    # Task status marks
    gf_add_success_marks 'DRC-H COMPLETED'
    # gf_add_log_filters 'DRC-H' 'group' 'error(s)' 'ERROR' 'Total' 'TOTAL RESULTS' 'Number of Results' '^LAYOUT' '^INCLUDE' '^GDS' 
    gf_add_status_marks 'TOTAL RESULTS' 'TOTAL RULECHECKS' 'Number of Results = [1-9]' '^ *Error:' '^ERROR:'
}

gf_help_command '
    {gf_use_calibre_lvs}
    Calibre LVS in interactive mode task preset.
'
function gf_use_calibre_lvs {
    gf_check_task_name

    # Shell commands to run
    gf_set_task_command "bash run.bash"
    gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
        `@init_shell_environment`
        `@init_calibre_environment`
        
        # Dump environment variables
        env > ./reports/`$TASK_NAME`.env

        # Data preparation commands
        `@calibre_pre_lvs_bash`

        # Run the tool
        calibre -gui -lvs -runset ./scripts/`$TASK_NAME`.runset
    '

    # Default customization
    gf_add_tool_commands -comment '' -file "./scripts/$TASK_NAME.runset" '
        *lvsRunDir: .
        *lvsReportFile: ./reports/`$TASK_NAME`.report
        *lvsMaskDBFile: ./out/`$TASK_NAME`.maskdb
        *lvsSVDBDir: ./out/`$TASK_NAME`.svdb
        *lvsERCDatabase: `$TASK_NAME`.erc.results
        *lvsERCSummaryFile: `$TASK_NAME`.erc.summary
        *lvsERCMaxResultsAll: 1
        *lvsERCMaxVertexAll: 1
        *lvsIsolateShortsByLayer: 1
        *lvsIsolateShortsByCell: 1
        *lvsIsolateShortsAccumulate: 1
        *lvsStartRVE: 0
        *lvsViewReport: 0
        *cmnVConnectReport: 1
        *cmnShowOptions: 0
    '

    # Multi-CPU mode
    if [ -n "$GF_TASK_CPU" ]; then
        gf_add_tool_commands '
            *cmnNumTurbo: `$GF_TASK_CPU`
            *cmnRunMT: 1
        '
    fi

    # Task status marks
    gf_add_success_marks 'LVS completed. CORRECT'
    gf_add_failed_marks 'NOT COMPARED' 'MISMATCH' 'INCORRECT'
    gf_add_status_marks 'TOTAL RESULTS' 'TOTAL RULECHECKS' 'Number of Results = [1-9]' '^ *Error:' '^ERROR:'
}

gf_help_command '
    {gf_use_calibre_lvs_batch}
    Calibre LVS in batch mode task preset.
'
function gf_use_calibre_lvs_batch {
    gf_check_task_name

    # Shell commands to run
    gf_set_task_command "bash run.bash"
    gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
        `@init_shell_environment`
        `@init_calibre_environment`
        
        # Dump environment variables
        env > ./reports/`$TASK_NAME`.env

        # Data preparation commands
        `@calibre_pre_lvs_bash`

        # Run the tool
        calibre -gui -lvs -runset ./scripts/`$TASK_NAME`.runset -batch
    '

    # Default customization
    gf_add_tool_commands -comment '' -file "./scripts/$TASK_NAME.runset" '
        *lvsRunDir: .
        *lvsReportFile: ./reports/`$TASK_NAME`.report
        *lvsMaskDBFile: ./out/`$TASK_NAME`.maskdb
        *lvsSVDBDir: ./out/`$TASK_NAME`.svdb
        *lvsERCDatabase: `$TASK_NAME`.erc.results
        *lvsERCSummaryFile: `$TASK_NAME`.erc.summary
        *lvsERCMaxResultsAll: 1
        *lvsERCMaxVertexAll: 1
        *lvsIsolateShortsByLayer: 1
        *lvsIsolateShortsByCell: 1
        *lvsIsolateShortsAccumulate: 1
        *lvsStartRVE: 0
        *lvsViewReport: 0
        *cmnVConnectReport: 1
        *cmnShowOptions: 0
    '

    # Multi-CPU mode
    if [ -n "$GF_TASK_CPU" ]; then
        gf_add_tool_commands '
            *cmnNumTurbo: `$GF_TASK_CPU`
            *cmnRunMT: 1
        '
    fi

    # Task status marks
    gf_add_success_marks 'LVS completed. CORRECT'
    gf_add_failed_marks 'NOT COMPARED' 'MISMATCH' 'INCORRECT'
    gf_add_status_marks 'TOTAL RESULTS' 'TOTAL RULECHECKS' 'Number of Results = [1-9]' '^ *Error:' '^ERROR:'
}
