################################################################################
# Generic Flow v5.5.4 (December 2025)
################################################################################
#
# Copyright 2011-2025 Gennady Kirpichev
#
#    https://github.com/32xlr8/gflow.git
#    https://gitflic.ru/project/32xlr8/gflow
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
# Filename: templates/project.2025/tools/gflow_plugin.genus.gf
# Purpose:  Generic Flow Genus plugin
################################################################################

gf_info "Loading Genus plugin ..."

##################################################
gf_help_section "Genus Common UI plugin"
##################################################

##################################################
# Genus in interactive mode preset
##################################################
gf_help_command '
    {gf_use_genus}
    Genus with GUI task preset.
'
function gf_use_genus {
    gf_check_task_name

    # Shell commands to run
    gf_set_task_command "bash run.bash"
    gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
        `@init_shell_environment`
        `@init_genus_environment`
        `@init_modus_environment -optional`
        `@init_innovus_environment -optional`
        
        # Dump environment variables
        env > ./reports/`$TASK_NAME`.env

        # Run the tool
        genus -files ./scripts/`$TASK_NAME`.tcl
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
            set_db / .max_cpus_per_server `$GF_TASK_CPU`
        '
    fi

    # Success marks
    gf_add_success_marks 'Normal exit'

    # Failed marks
    gf_add_failed_marks 'Stack trace' 'terminated by user' 'FATAL ERROR' 'Abnormal exit'
    gf_add_failed_marks 'No valid licenses'
}

##################################################
# Genus in batch mode preset
##################################################
gf_help_command '
    {gf_use_genus_batch}
    Genus in batch mode task preset.
'
function gf_use_genus_batch {
    gf_check_task_name

    # Shell commands to run
    gf_set_task_command "bash run.bash"
    gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
        `@init_shell_environment`
        `@init_genus_environment`
        `@init_modus_environment -optional`
        `@init_innovus_environment -optional`
        
        # Dump environment variables
        env > ./reports/`$TASK_NAME`.env

        # Run the tool
        genus -batch -no_gui -files ./scripts/`$TASK_NAME`.tcl
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
            set_db / .max_cpus_per_server `$GF_TASK_CPU`
        '
    fi

    # Success marks
    gf_add_success_marks 'Normal exit'

    # Failed marks
    gf_add_failed_marks 'Stack trace' 'terminated by user' 'FATAL ERROR' 'Abnormal exit'
    gf_add_failed_marks 'No valid licenses'
    gf_add_failed_marks 'Invalid return code' 'Encountered problems'
}
