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
# Filename: templates/tools_template.2023/tool_steps.stylus.gf
# Purpose:  Stylus steps to use in the Generic Flow
################################################################################

gf_info "Loading Stylus steps ..."

################################################################################
# Stylus metrics
################################################################################

# Start new metric section
gf_create_step -name collect_metrics '
    catch {push_snapshot_stack}
'

# Finish new metric section
gf_create_step -name report_metrics '
    catch {
        set_metric -name flow.step.tcl -value [info script]
        pop_snapshot_stack
        create_snapshot -name $TASK_NAME
        report_metric -format html -file ./reports/$TASK_NAME.metric.html
        write_metric -format json -file ./out/$TASK_NAME.metric.json
    }
'

# Finish new metric section
gf_create_step -name procs_stylus_metrics '
    proc gf_include_metrics {tasks} {
        foreach task $tasks {
            read_metric -id $task ./out/$task.metric.json
            catch {
                push_snapshot_stack
                dict for {name value} [get_metric -id $task] {
                     set_metric -name $name -value $value
                }
                pop_snapshot_stack
                create_snapshot -name $task
            }
        }
    }
'

################################################################################
# Database steps
################################################################################

# Start new metric section
gf_create_step -name procs_stylus_db '

    # Filter instances by pattern
    proc gf_get_insts {pattern} {
        set results [get_db insts $pattern]
        if {[llength $results] == 0} {
            puts "\033\[41m \033\[0m No insts matching pattern $pattern found."
            suspend
        } else {
            puts "\033\[42m \033\[0m Total [llength $results] $pattern insts matching pattern $pattern found."
        }
        return $results
    }

    # Filter modules by pattern
    proc gf_get_hinsts {pattern} {
        set results [get_db hinsts $pattern]
        if {[llength $results] == 0} {
            puts "\033\[41m \033\[0m No hinsts matching pattern $pattern found."
            suspend
        } else {
            puts "\033\[42m \033\[0m Total [llength $results] $pattern hinsts matching pattern $pattern found."
        }
        return $results
    }

    # Print evaluated legacy script content
    proc gf_verbose_legacy_script {script} {
        eval_legacy "
            foreach gf_line \[split {$script} \\n\] {
                if {\[regexp {^\\s*set\\s} \$gf_line\]} {
                    catch {eval_legacy \$gf_line}
                }
                if {[catch {puts \[subst \$gf_line\]}]} {
                    puts \$gf_line
                }
            }
        "
    }
'

################################################################################
# Interactive steps
################################################################################

# Suspend commands and show interactive session
gf_create_step -name suspend '
    exec xterm -e less ./scripts/$TASK_NAME.tcl &
    gui_show
    suspend
    gui_hide
'
