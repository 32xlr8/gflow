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
# Filename: templates/project_template.2023/blocks/block_template/innovus.metric.gf
# Purpose:  Compare different runs
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source "../../project.common.gf"
gf_source "../../project.innovus.gf"
gf_source "./block.common.gf"
gf_source "./block.files.gf"
gf_source "./block.innovus.gf"

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

    # Unsorted list of mtime-file pairs
    set unsorted_files {}
    foreach task {Place Clock Route} {
        catch {
            foreach file [glob ../../../../work_*/*/out/$task*.json] {
                lappend unsorted_files [list [file mtime $file] $file]
            }
        }
    }
    
    # Files sorted by modified date
    set sorted_files {}
    set ids {}
    foreach sorted_file [lsort -index 0 -integer $unsorted_files] {
        catch {
            set file [lindex $sorted_file 1]
            set id [file tail [file dirname [file dirname [file dirname $file]]]].[file tail [file dirname [file dirname $file]]]
            read_metric -id $id $file
            if {[lsearch -exact $ids $id] < 0} {
                lappend ids $id
            }
            puts "Metric file included: $file"
        }
    }

    # Write metrics to compare
    if {[llength $ids]} {
        catch {
            report_metric -id $ids -format html -file ./reports/`$TASK_NAME`.html
            puts {Html metrics written: ./reports/`$TASK_NAME`.html}
        }
        catch {
            report_metric -id $ids -format vivid -file ./reports/`$TASK_NAME`.vivid.html
            puts {Vivid metrics written: ./reports/`$TASK_NAME`.vivid.html}
        }
    } else {
        puts "ERROR: No metric files found"
    }
'

# Check for success
gf_add_status_marks 'Metric file included:' 'metrics written:' 'ERROR:'
gf_add_success_marks 'metrics written:'

# Run task
gf_submit_task
