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
# Filename: templates/project.2025/blocks/template/voltus.gui.gf
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
gf_choose_file_dir_task -variable VOLTUS_RAIL_DATA -prompt "Choose rail data to load:" -dirs '
    '"$VOLTUS_RAIL_DATA"'
    ../work_*/*/out/*.rail/*
'
gf_spacer
    
# Voltus power data
gf_choose -variable OPEN_POWER_DB -keep -keys YN -default Y -prompt "Do you want to open power data (Y/N)?"
if [ "$OPEN_POWER_DB" == "Y" ]; then
    gf_choose_file_dir_task -variable VOLTUS_POWER_DATA -prompt "Choose power data to load:" -files '
        '"$VOLTUS_POWER_DATA"'
        ../work_*/*/out/*.power/*power.db
    '
fi
gf_spacer

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES` `$PARTITIONS_LEF_FILES -optional`}
    set VOLTUS_POWER_DATA {`$VOLTUS_POWER_DATA -optional`} 
    set VOLTUS_RAIL_DATA {`$VOLTUS_RAIL_DATA`} 
    set DESIGN_NAME {`$DESIGN_NAME`} 

    # Files base
    set files_base [regsub {/out/(.*)\.rail/.*?$} $VOLTUS_RAIL_DATA {/in/\1}]
    if {![llength $files_base]} {
        set files_base [regsub {/out/(.*)\.power/.*?$} $VOLTUS_POWER_DATA {/in/\1}]
    }

    # Start metric collection
    `@collect_metrics`

    # Design variables
    `@voltus_pre_init_design_variables`

    # Load design files
    read_physical -lefs [join $LEF_FILES]
    read_netlist $files_base.v.gz -top $DESIGN_NAME
    puts "Netlist files: [join $files_base.v.gz]"
    
    # Design initialization
    init_design
    `@voltus_post_init_design_project`
    `@voltus_post_init_design_variables`
    `@voltus_post_init_design`
    
    # Load physical data
    read_def $files_base.def.gz -skip_signal_nets 

    # Open power and rail results
    if {[llength $VOLTUS_POWER_DATA] && [llength $VOLTUS_RAIL_DATA]} {
        ::read_power_rail_results \
            -power_db $VOLTUS_POWER_DATA \
            -rail_directory $VOLTUS_RAIL_DATA \
            -instance_voltage_window {timing whole} \
            -instance_voltage_method {worst best avg worstavg}

    # Rail results only
    } elseif {[llength $VOLTUS_RAIL_DATA]} {
        ::read_power_rail_results \
            -rail_directory $VOLTUS_RAIL_DATA \
            -instance_voltage_window {timing whole} \
            -instance_voltage_method {worst best avg worstavg}

    # Power results only
    } elseif {[llength $VOLTUS_POWER_DATA]} {
        ::read_power_rail_results \
            -power_db $VOLTUS_POWER_DATA \
            -instance_voltage_window {timing whole} \
            -instance_voltage_method {worst best avg worstavg}
    }

    # GUI commands
    `@voltus_pre_gui -optional`

    gui_show
'

# Run task
gf_submit_task
