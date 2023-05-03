#!../../gflow/bin/gflow

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
# Filename: templates/project_template.2023/blocks/block_template/voltus.gui.gf
# Purpose:  Interactive power results debug flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.voltus.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.voltus.gf"

# Basic flow script options
gf_set_flow_options -continue -incr -auto_close -hide

########################################
# Innovus interactive task
########################################

gf_create_task -name DebugVoltus
gf_use_voltus

# Voltus rail data
gf_choose_file_dir_task -variable VOLTUS_RAIL_DATA -keep -prompt "Choose rail data to load:" -dirs '
    ../work_*/*/out/*.rail/*
'
gf_spacer
    
# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set VOLTUS_RAIL_DATA {`$VOLTUS_RAIL_DATA`} 
    set DESIGN_NAME {`$DESIGN_NAME`} 

    # Start metric collection
    `@collect_metrics`

    # Design variables
    `@voltus_pre_init_variables`

    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist [regsub {/out/(.*)\.rail/.*?$} $VOLTUS_RAIL_DATA {/in/\1.v.gz}] -top $DESIGN_NAME
    
    # Design initialization
    init_design
    
    # Load physical data
    read_def [regsub {/out/(.*)\.rail/.*?$} $VOLTUS_RAIL_DATA {/in/\1.def.gz}]  -skip_signal_nets 

    # Open latest directory
    ::read_power_rail_results \
        -rail_directory $VOLTUS_RAIL_DATA \
        -instance_voltage_window {timing whole} \
        -instance_voltage_method {worst best avg worstavg}

    # Initialize tool environment
    `@voltus_post_init_design_project`
    `@voltus_post_init_variables`

    # GUI commands
    `@voltus_pre_gui -optional`

    gui_show
'

# Run task
gf_submit_task
