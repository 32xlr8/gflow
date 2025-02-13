#!../../gflow/bin/gflow

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
# Filename: templates/project.2025/blocks/template/innovus.metric.gf
# Purpose:  Compare different runs
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.innovus.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.innovus.gf"

# Continue in existing directory and restart tasks
gf_set_flow_options -silent

########################################
# Flow tool task to compare metrics
########################################

gf_create_task -name Metric

# Shell commands to run
gf_set_task_command "bash run.bash"
gf_add_tool_commands -comment '#' -file "./tasks/$TASK_NAME/run.bash" '
    `@init_shell_environment`
    `@init_innovus_environment`

    # Run the tool
    flowtool -files ./scripts/`$TASK_NAME`.tcl
'

# TCL script initialization
gf_add_tool_commands -comment '#' -file "./scripts/$TASK_NAME.tcl" '
    set TASK_NAME {`$TASK_NAME`}

    # Unsorted list of mtime-task-file
    set unsorted_files {}
    set tasks {}
    catch {
        foreach file [glob ../../../../work_*/*/out/*.json] {
            set mtime [file mtime $file]
            set task [regsub {\..*$} [file tail $file] {}]
            set id [file tail [file dirname [file dirname [file dirname $file]]]].[file tail [file dirname [file dirname $file]]][regsub {^[^\.]+} [file tail $file] {}]
            lappend unsorted_files [list $mtime $task $id $file]
            if {[lsearch -exact $tasks $task] < 0} {
                lappend tasks $task
            }
        }
    }
    
    # Files sorted by modified date
    set sorted_files [lsort -index 0 -integer $unsorted_files]
    
    # Group metrics by task
    foreach task $tasks {

        # Read metrics
        set ids {}
        foreach sorted_file $sorted_files {
            if {$task == [lindex $sorted_file 1]} {
                catch {
                    puts "Reading metrics $file ..."
                    set id [lindex $sorted_file 2]
                    set file [lindex $sorted_file 3]
                    read_metric $file -id $id
                    if {[lsearch -exact $ids $id] < 0} {
                        lappend ids $id
                    }
                }
            }
        }

        # Write metrics to compare
        if {[llength $ids]} {
            catch {
                puts "Writing html metrics ./reports/$TASK_NAME.$task.html ..."
                report_metric -id $ids -format html -file ./reports/$TASK_NAME.$task.html
            }
            catch {
                report_metric -id $ids -format vivid -file ./reports/$TASK_NAME.$task.vivid.html
                puts "Writing vivid metrics ./reports/$TASK_NAME.$task.vivid.html ..."
            }
        } else {
            puts "ERROR: No metric files for $task tasks"
        }
        
        puts {}
    }
    
    exit
'

# Check for success
gf_add_status_marks 'Metric file included:' 'metrics written:' 'ERROR:'
gf_add_success_marks 'metrics written:'

# Run task
gf_submit_task
