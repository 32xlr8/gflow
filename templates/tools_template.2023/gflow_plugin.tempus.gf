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
# Filename: templates/tools_template.2023/gflow_plugin.tempus.gf
# Purpose:  Generic Flow Tempus plugin
################################################################################

gf_info "Loading Tempus plugin ..."

##################################################
gf_help_section "Tempus Common UI plugin v5.0"
##################################################

##################################################
# Tempus in interactive mode preset
##################################################
gf_help_command '
    {gf_use_tempus}
    Tempus with GUI task preset (common UI).
'
function gf_use_tempus {
    gf_check_task_name

    # Shell commands to run
    gf_set_task_command "bash run.bash"
    gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
        `@init_shell_environment`
        `@init_tempus_environment`
        
        # Run the tool
        tempus -stylus -files ./scripts/`$TASK_NAME`.tcl
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

    # Success marks
    gf_add_success_marks 'Ending.*Tempus'

    # Failed mark
    gf_add_failed_marks '^\s*pstack\s*$' 'terminated by user interrupt' 'Stack trace'

    # Parasitics statistic
    gf_add_status_marks -1 -from 'Annotated \(%\)' -to '^\+\-+\+$'
        
    # Violations statistic
    gf_add_status_marks '^\*info: Total' '^\*info:.*[Tt]otal.*(inst|cell)' '^\*info:.*Could'
    gf_add_status_marks '^[^\"]*WNS .* AVG .* of .* violated'
    gf_add_status_marks '^[^\"]*Slack = .* \@' '^[^\"]*BA .* constraint violations:'
    gf_add_status_marks '^[^\"]*Glitch summary:' '^[^\"]*nets with violations \@'
    
    # Message summary
    gf_add_status_marks 'Message Summary:'
    gf_add_status_marks -from 'Summary of all messages' '^ERROR' -to 'Message Summary:'
}

##################################################
# Tempus in batch mode preset
##################################################
gf_help_command '
    {gf_use_tempus_batch}
    Tempus in batch mode task preset (common UI).
'
function gf_use_tempus_batch {
    gf_check_task_name

    # Shell commands to run
    gf_set_task_command "bash run.bash"
    gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
        `@init_shell_environment`
        `@init_tempus_environment`
        
        # Run the tool
        tempus -stylus -batch -no_gui -files ./scripts/`$TASK_NAME`.tcl
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

    # Success marks
    gf_add_success_marks 'Ending.*Tempus'

    # Failed mark
    gf_add_failed_marks '^\s*pstack\s*$' 'terminated by user interrupt' 'Stack trace'

    # Parasitics statistic
    gf_add_status_marks -1 -from 'Annotated \(%\)' -to '^\+\-+\+$'
        
    # Violations statistic
    gf_add_status_marks '^\*info: Total' '^\*info:.*[Tt]otal.*(inst|cell)' '^\*info:.*Could'
    gf_add_status_marks 'WNS .* AVG .* of .* violated'
    gf_add_status_marks 'Slack = .* \@' 'BA .* constraint violations:'
    gf_add_status_marks 'Glitch summary:' 'nets with violations \@'
    
    # Message summary
    gf_add_status_marks 'Message Summary:'
    gf_add_status_marks -from 'Summary of all messages' '^ERROR' -to 'Message Summary:'

    # Failed mark
    gf_add_failed_marks 'invalid command name' 'errors out'
}
