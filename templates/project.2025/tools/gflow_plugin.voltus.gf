################################################################################
# Generic Flow v5.5.3 (October 2025)
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
# Filename: templates/project.2025/tools/gflow_plugin.voltus.gf
# Purpose:  Generic Flow Voltus plugin
################################################################################

gf_info "Loading Voltus plugin ..."

##################################################
gf_help_section "Voltus Common UI plugin"
##################################################

##################################################
# Voltus in interactive mode preset
##################################################
gf_help_command '
    {gf_use_voltus}
    Voltus with GUI task preset (common UI).
'
function gf_use_voltus {
    gf_check_task_name

    # Shell commands to run
    gf_set_task_command "bash run.bash"
    gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
        `@init_shell_environment`
        `@init_voltus_environment`
        
        # Dump environment variables
        env > ./reports/`$TASK_NAME`.env

        # Run the tool
        voltus -stylus -files ./scripts/`$TASK_NAME`.tcl
    '

    # TCL script initialization
    gf_add_tool_commands -comment '#' -file "./scripts/$TASK_NAME.tcl" '
        # Current task variables
        set RUN_INDEX {`$GF_RUN_INDEX`}
        set MOTHER_TASK_NAME {`$MOTHER_TASK_NAME -optional`}
        set TASK_NAME {`$TASK_NAME`}
        
        # Generic Flow directories
        set GF_ROOT {`$GF_ROOT`}
        set GF_SCRIPT_DIR {`$GF_SCRIPT_DIR`}
        
        # Interactive aliases
        alias man {exec /usr/bin/man > /dev/tty}
        alias less {exec /usr/bin/less > /dev/tty}
        alias vi {exec /usr/bin/vim > /dev/tty}
    '

    # Multi-CPU mode
    if [ -n "$GF_TASK_CPU" ]; then
        gf_add_tool_commands '
            # set_distribute_host -local
            set_multi_cpu_usage -local_cpu `$GF_TASK_CPU`
        '
    fi

    # Status marks
    gf_add_status_marks -1 -from 'Annotated \(%\)' -to '^\+\-+\+$'
    gf_add_status_marks '^Run directory:' '^Analysis view:' '^RC corner:' '^SPEF file:'
    gf_add_status_marks 'Voltage Source.*%' 'Current Tap.*%'
    gf_add_status_marks 'Total annotation coverage' 'Names in file' 'Unique nets'
    gf_add_status_marks 'annotated' 'disconnected nodes'
    gf_add_status_marks 'Total.*Power:' 'Total .* coverage:' 'Num Violations:' 'Instance.* IR Drop:'
    gf_add_success_marks 'Exiting Voltus' 'Ending.*Voltus'
    gf_add_failed_marks ' pstack ' 'terminated by user interrupt'
}

##################################################
# Voltus in batch mode preset
##################################################
gf_help_command '
    {gf_use_voltus_batch}
    Voltus in batch mode task preset (common UI).
'
function gf_use_voltus_batch {
    gf_check_task_name

    # Shell commands to run
    gf_set_task_command "bash run.bash"
    gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
        `@init_shell_environment`
        `@init_voltus_environment`
        
        # Dump environment variables
        env > ./reports/`$TASK_NAME`.env

        # Run the tool
        voltus -stylus -batch -no_gui -files ./scripts/`$TASK_NAME`.tcl
    '

    # TCL script initialization
    gf_add_tool_commands -comment '#' -file "./scripts/$TASK_NAME.tcl" '
        # Current task variables
        set RUN_INDEX {`$GF_RUN_INDEX`}
        set MOTHER_TASK_NAME {`$MOTHER_TASK_NAME -optional`}
        set TASK_NAME {`$TASK_NAME`}
        
        # Generic Flow directories
        set GF_ROOT {`$GF_ROOT`}
        set GF_SCRIPT_DIR {`$GF_SCRIPT_DIR`}
        
        # Interactive aliases
        alias man {exec /usr/bin/man > /dev/tty}
        alias less {exec /usr/bin/less > /dev/tty}
        alias vi {exec /usr/bin/vim > /dev/tty}
    '

    # Multi-CPU mode
    if [ -n "$GF_TASK_CPU" ]; then
        gf_add_tool_commands '
            # set_distribute_host -local
            set_multi_cpu_usage -local_cpu `$GF_TASK_CPU`
        '
    fi

    # Status marks
    gf_add_status_marks 'Names in file' 'Unique nets'
    gf_add_status_marks -1 -from 'Annotated \(%\)' -to '^\+\-+\+$'
    gf_add_status_marks 'Run directory:' 'SPEF file:' 'QRC file:' 'MMMC file:'
    gf_add_status_marks 'Voltage Source.*%' 'Current Tap.*%'
    gf_add_status_marks 'Total annotation coverage' 'Names in file' 'Unique nets'
    gf_add_status_marks 'annotated' 'disconnected nodes'
    gf_add_status_marks 'Total.*Power:' 'Total .* coverage:' 'Num Violations:' 'Instance.* IR Drop:'
    gf_add_success_marks 'Exiting Voltus' 'Ending.*Voltus'
    gf_add_failed_marks ' pstack ' 'terminated by user interrupt'

    # Failed mark
    gf_add_failed_marks 'invalid command name' 'errors out'
}
