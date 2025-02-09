################################################################################
# Generic Flow v5.1 (May 2023)
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
# Filename: templates/tools_template.2023/gflow_plugin.quantus.gf
# Purpose:  Generic Flow Quantus plugin
################################################################################

gf_info "Loading Quantus plugin ..."

##################################################
gf_help_section "Quantus plugin v5.1"
##################################################

##################################################
# Quantus in batch mode preset
##################################################
gf_help_command '
    {gf_use_quantus_batch}
    Quantus in batch mode task preset.
'
function gf_use_quantus_batch {
    gf_check_task_name

    # Shell commands to run
    gf_set_task_command "bash run.bash"
    gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
        `@init_shell_environment`
        `@init_quantus_environment`
        
        # Dump environment variables
        env > ./reports/`$TASK_NAME`.env

        # Run the tool
        quantus -cmd ./scripts/`$TASK_NAME`.ccl
    '

    # Multi-CPU mode
    [[ -z "$GF_TASK_CPU" ]] && GF_TASK_CPU=1
    gf_add_tool_commands -comment '#' -file "./scripts/$TASK_NAME.ccl" '
        distributed_processing -multi_cpu `$GF_TASK_CPU`
    '

    # Task status marks
    gf_add_success_marks 'QRC Extraction completed successfully' 'Quantus Extraction completed successfully'
    gf_add_status_marks 'messages:' 'Metal FILL shapes:' 'unrouted nets' 'incomplete nets'
}
