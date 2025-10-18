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
# Filename: templates/project.2025/blocks/template/innovus.tso.gf
# Purpose:  Batch signoff ECO flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.innovus.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.innovus.gf"

########################################
# Innovus ECO
########################################

gf_create_task -name ECO
gf_use_innovus

# Design data directory
gf_choose_file_dir_task -variable DATA_OUT_DIR -keep -prompt "Choose design data directory:" -dirs '
    ../work_*/*/out/InnovusOut*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/InnovusOut*
'

# Design data directory
gf_choose_file_dir_task -variable ECO_SCRIPT -keep -prompt "Choose ECO script:" -files '
    ../work_*/*/out/TSO*.eco_innovus.tcl
' -want -active -task_to_file '$RUN/out/$TASK.eco_innovus.tcl' -tasks '
    ../work_*/*/tasks/TSO*
'

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set DESIGN_NAME {`$DESIGN_NAME`}

    set DATA_OUT_DIR {`$DATA_OUT_DIR`}
    set ECO_SCRIPT {`$ECO_SCRIPT`}

    # Load input database
    read_db $DATA_OUT_DIR/$DESIGN_NAME.innovus.db
    puts "Database: $DATA_OUT_DIR/$DESIGN_NAME.innovus.db"
    
    # Include STA metrics
    `@procs_stylus_metrics`

    # Start metric collection
    `@collect_metrics`

    # Cumulative ECO
    source $ECO_SCRIPT
    
    # Apply routing changes
    set_db route_design_with_timing_driven false
    route_eco
    reset_db route_design_with_timing_driven
    
    # Report collected metrics
    `@report_metrics`
        
    # Write Innovus database
    write_db ./out/$TASK_NAME.innovus.db
    
    # Close interactive session
    exit
'

# Display status
# gf_add_status_marks -from '\|.*max hotspot.*\|' -expr '[\|\+]' -to '^[^\|\+]*$' -1
gf_add_status_marks 'Local HotSpot Analysis'
gf_add_status_marks 'number of DRC violations'
gf_add_status_marks -from 'Final .*Summary' -to 'Density:' WNS TNS max_tran -3 +3

# Run task
gf_submit_task

########################################
# Generic Flow history
########################################

gf_create_task -name HistoryECO -mother ECO
gf_set_task_command "../../../../../../tools/print_flow_history.pl ../.. -html ./reports/$TASK_NAME.html"
gf_submit_task -silent
