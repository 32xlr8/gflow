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
# Filename: templates/project_template.2023/blocks/block_template/innovus.reports.gf
# Purpose:  Batch implementation reports creation flow
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

########################################
# Innovus initial reports task
########################################

gf_create_task -name ReportNetlist -group Reports -parallel 1
gf_use_innovus_batch

# Wait for Innovus database from previous run
gf_wait_files ./out/Init.innovus.db/viewDefinition.tcl

# TCL commands
gf_add_tool_commands '

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Load Innovus database
    read_db ./out/Init.innovus.db
    
    # Show additional timing columns
    set_db timing_report_fields {cell arc delay incr_delay arrival required transition fanout load aocv_adj_stages aocv_derate user_derate annotation instance}

    # Start metric collection
    `@collect_metrics`

    # Create reports directory
    exec mkdir -p ./reports/$TASK_NAME

    # Design-specific reports
    `@innovus_design_reports_pre_place`

    # Report collected metrics
    `@report_metrics`
'

# Print timing summary
gf_add_status_marks -from 'time_design Summary' -1 -from '(Setup|Hold) mode' -to 'Density:' -exclude '^\s*$'

# Submit task
gf_submit_task -silent

########################################
# Innovus pre-cts reports task
########################################

gf_create_task -name ReportPlace -mother Place -group Reports -parallel 1
gf_use_innovus_batch

# TCL commands
gf_add_tool_commands '

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Load Innovus database
    read_db ./out/$MOTHER_TASK_NAME.innovus.db
    
    # Show additional timing columns
    set_db timing_report_fields {cell arc delay incr_delay arrival required transition fanout load aocv_adj_stages aocv_derate user_derate annotation instance}

    # Start metric collection
    `@collect_metrics`

    # Create reports directory
    exec mkdir -p ./reports/$TASK_NAME
    
    # Design-specific reports
    `@innovus_design_reports_pre_clock`
    
    # Report collected metrics
    `@report_metrics`
'

# Print timing summary
gf_add_status_marks -from 'time_design Summary' -1 -from '(Setup|Hold) mode' -to 'Density:' -exclude '^\s*$'

# Submit task
gf_submit_task -silent

########################################
# Innovus post-clock reports tasks
########################################

gf_create_task -name ReportClock -mother Clock -group Reports -parallel 1
gf_use_innovus_batch

# TCL commands
gf_add_tool_commands '

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Load Innovus database
    read_db ./out/$MOTHER_TASK_NAME.innovus.db

    # Show additional timing columns
    set_db timing_report_fields {cell arc delay incr_delay arrival required transition fanout load aocv_adj_stages aocv_derate user_derate annotation instance}

    # Start metric collection
    `@collect_metrics`

    # Create reports directory
    exec mkdir -p ./reports/$TASK_NAME
    
    # Design-specific reports
    `@innovus_design_reports_pre_route`

    # Report collected metrics
    `@report_metrics`
'

# Print timing summary
gf_add_status_marks -from 'time_design Summary' -1 -from '(Setup|Hold) mode' -to 'Density:' -exclude '^\s*$'

# Submit task
gf_submit_task -silent

########################################
# Innovus post-route reports task
########################################

gf_create_task -name ReportRoute -mother Route -group Reports -parallel 1
gf_use_innovus_batch

# TCL commands
gf_add_tool_commands '

    # Pre-load settings
    `@innovus_pre_read_libs`

    # Load Innovus database
    read_db ./out/$MOTHER_TASK_NAME.innovus.db

    # Show additional timing columns
    set_db timing_report_fields {cell arc delay incr_delay arrival required transition fanout load aocv_adj_stages aocv_derate user_derate annotation instance}

    # Start metric collection
    `@collect_metrics`

    # Create reports directory
    exec mkdir -p ./reports/$TASK_NAME
    
    # Design-specific reports
    `@innovus_design_reports_post_route`

    # Report collected metrics
    `@report_metrics`
'

# Print timing summary
gf_add_status_marks -from 'time_design Summary' -1 -from '(Setup|Hold) mode' -to 'Density:' -exclude '^\s*$'

# Submit task
gf_submit_task -silent
