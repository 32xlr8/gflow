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
# Filename: templates/tools_template.cadence.2022/gflow_plugin.innovus.gf
# Purpose:  Generic Flow Innovus plugin
################################################################################

gf_info "Loading Innovus plugin ..."

##################################################
gf_help_section "Innovus Common UI plugin v5.0"
##################################################

##################################################
# Innovus in interactive mode preset
##################################################
gf_help_command '
    {gf_use_innovus}
    Innovus with GUI task preset (common UI).
'
function gf_use_innovus {
    gf_check_task_name

    # Shell commands to run
    gf_set_task_command "bash run.bash"
    gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
        `@init_shell_environment`
        `@init_innovus_environment`
        `@init_quantus_environment -optional`
        `@init_genus_environment -optional`
        
        # Run the tool
        innovus -stylus -files ./scripts/`$TASK_NAME`.tcl
    '

    # TCL script initialization
    gf_add_tool_commands -comment '#' -file "./scripts/$TASK_NAME.tcl" '
        # Current task variables
        set RUN_INDEX {`$GF_RUN_INDEX`}
        set MOTHER_TASK_NAME {`$MOTHER_TASK_NAME`}
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
            set_multi_cpu_usage -local_cpu `$GF_TASK_CPU`
        '
    fi

    # Status marks
    gf_add_success_marks 'Ending.*Innovus'
    gf_add_failed_marks 'Stack trace' 'terminated by user' 'FATAL ERROR'
    gf_add_failed_marks 'No valid licenses' 'Fail to find any innovus license'
    gf_add_status_marks Flattening

    # Placement statistic
    gf_add_status_marks 'Detail placement moves [1-9]'
    
    # Routing statistic
    gf_add_status_marks 'DRC violations = [1-9]' 
    gf_add_status_marks 'violated process antenna rule = [1-9]' 
    gf_add_status_marks 'required routing'
    gf_add_status_marks 'Density:'

    # Optimization statistic
    gf_add_status_marks 'glitch violations: [1-9]'
    gf_add_status_marks '^\*info:.*Total [1-9].*violated'

    # Message summary
    gf_add_status_marks 'Message Summary:'
    gf_add_status_marks -from 'Summary of all messages' '^ERROR' -to 'Message Summary:'
}

gf_help_command '
    {gf_use_innovus_legacy}
    Innovus with GUI task preset (legacy UI).
'
function gf_use_innovus_legacy {
    gf_check_task_name

    # Shell commands to run
    gf_set_task_command "bash run.bash"
    gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
        `@init_shell_environment`
        `@init_innovus_environment`
        `@init_quantus_environment -optional`
        `@init_genus_environment -optional`
        
        # Run the tool
        innovus -files ./scripts/`$TASK_NAME`.tcl
    '

    # TCL script initialization
    gf_add_tool_commands -comment '#' -file "./scripts/$TASK_NAME.tcl" '
        # Current task variables
        set RUN_INDEX {`$GF_RUN_INDEX`}
        set MOTHER_TASK_NAME {`$MOTHER_TASK_NAME`}
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
            setMultiCpuUsage -local `$GF_TASK_CPU`
        '
    fi

    # Success marks
    gf_add_success_marks 'Ending.*Innovus'

    # Failed mark
    gf_add_failed_marks 'Stack trace' 'terminated by user' 'FATAL ERROR'
    gf_add_failed_marks 'No valid licenses' 'Fail to find any innovus license'
}

##################################################
# Innovus in batch mode preset
##################################################
gf_help_command '
    {gf_use_innovus_batch}
    Innovus in batch mode task preset (common UI).
'
function gf_use_innovus_batch {
    gf_check_task_name

    # Shell commands to run
    gf_set_task_command "bash run.bash"
    gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
        `@init_shell_environment`
        `@init_innovus_environment`
        `@init_quantus_environment -optional`
        `@init_genus_environment -optional`
        
        # Run the tool
        innovus -stylus -batch -no_gui -files ./scripts/`$TASK_NAME`.tcl
    '

    # TCL script initialization
    gf_add_tool_commands -comment '#' -file "./scripts/$TASK_NAME.tcl" '
        # Current task variables
        set RUN_INDEX {`$GF_RUN_INDEX`}
        set MOTHER_TASK_NAME {`$MOTHER_TASK_NAME`}
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
            set_multi_cpu_usage -local_cpu `$GF_TASK_CPU`
        '
    fi

    # Status marks
    gf_add_success_marks 'Ending.*Innovus'
    gf_add_failed_marks 'Stack trace' 'terminated by user' 'FATAL ERROR'
    gf_add_failed_marks 'No valid licenses' 'Fail to find any innovus license'
    gf_add_status_marks Flattening

    # Placement statistic
    gf_add_status_marks 'Detail placement moves [1-9]'
    
    # Routing statistic
    gf_add_status_marks 'DRC violations = [1-9]' 
    gf_add_status_marks 'violated process antenna rule = [1-9]' 
    gf_add_status_marks 'required routing'
    gf_add_status_marks 'Density:'

    # Optimization statistic
    gf_add_status_marks 'glitch violations: [1-9]'
    gf_add_status_marks '^\*info:.*Total [1-9].*violated'

    # Message summary
    gf_add_status_marks 'Message Summary:'
    gf_add_status_marks -from 'Summary of all messages' '^ERROR' -to 'Message Summary:'

    # Failed mark
    gf_add_failed_marks 'Invalid return code'
}
