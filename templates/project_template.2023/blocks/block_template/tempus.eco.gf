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
# Filename: templates/project_template.2023/blocks/block_template/tempus.eco.gf
# Purpose:  Batch signoff ECO flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source "../../project.common.gf"
gf_source "../../project.tempus.gf"
gf_source "../../project.innovus.gf"
gf_source "../../project.quantus.gf"
gf_source "./block.common.gf"
gf_source "./block.files.gf"
gf_source "./block.tempus.gf"
gf_source "./block.innovus.gf"
gf_source "./block.quantus.gf"

########################################
# Main flow
########################################

# Include STA flow
gf_source "./tempus.sta.gf"

########################################
# Tempus ECO
########################################

gf_create_task -name TSO -mother Init
gf_use_tempus
gf_add_tool_arguments -eco

# Want for extraction
gf_want_tasks Extraction -variable SPEF_TASKS

# Choose scenario
gf_choose -keep -variable ECO_SCENARIO -message "Which ECO scenario to run?" -variants "$(echo "$ECO_SCENARIOS" | sed -e 's|^\s\+||g; s|\s\+$||g;')" -count 25

# Want for STA
gf_want_tasks STA

# Choose configuration file
gf_choose_file_dir_task -variable TEMPUS_TIMING_CONFIG_FILE -keep -prompt "Please select timing configuration file:" -files '
    ../data/*.timing.tcl
    ../data/*/*.timing.tcl
    ../work_*/*/out/ConfigSignoff*.timing.tcl
'

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}
    set SPEF_TASKS {`$SPEF_TASKS`}
    set ECO_SCENARIO {`$ECO_SCENARIO`}
    set IGNORE_IO_TIMING {`$IGNORE_IO_TIMING`}
    set MMMC_FILE {`$MMMC_FILE`}
    set OCV_FILE "[regsub {\.mmmc\.tcl$} $MMMC_FILE {}].ocv.tcl"

    # Ignore IMPESI-3490
    eval_legacy {setDelayCalMode -sgs2set abortCdbMmmcFlow:false}

    # Start metric collection
    `@collect_metrics`

    # Get top level design name from Innovus database
    source ./out/$MOTHER_TASK_NAME.init_tempus.tcl
    
    # Initialize power and ground nets
    set_db init_power_nets [join $POWER_NETS]
    set_db init_ground_nets [join $GROUND_NETS]

    # Load MMMC configuration
    read_mmmc $MMMC_FILE
    
    # Read physical information defined in project config
    read_physical -lefs [join $LEF_FILES]

    # Load netlist
    read_netlist ./out/$MOTHER_TASK_NAME.v -top $DESIGN_NAME
    
    # Load physical data
    read_def ./out/$MOTHER_TASK_NAME.lite.def.gz
    
    # Initialize design with MMMC configuration
    init_design
    
    # Initialize tool environment
    `@tempus_post_init_design_technology`
    `@tempus_post_init_design`

    # Read parasitics
    `@procs_tempus_read_data`
    gf_read_parasitics $SPEF_TASKS
    
    # Init cells allowed for ECO
    `@init_cells_tempus`

    # Read ECO timing DB
    set_db opt_signoff_read_eco_opt_db ./out/$MOTHER_TASK_NAME.eco_db
    
    # Multiple ECO in the same session
    set_db opt_signoff_allow_multiple_incremental true
    
    # Take legal location into account
    set_db opt_signoff_legal_only true
    
    # Do not optimize interface paths
    if {$IGNORE_IO_TIMING == "Y"} {
        set_db opt_signoff_optimize_core_only true
    }
    
    # Allow to fix hold if setup violated
    set_db opt_signoff_fix_hold_allow_setup_tns_degrade true

    # Optimize setup with hold
    set_db opt_signoff_fix_hold_allow_setup_optimization true

    # Accumulated ECO scripts    
    rm -f ./out/$TASK_NAME.eco_innovus.tcl
    rm -f ./out/$TASK_NAME.eco_tempus.tcl
    set ECO_COUNT 0

    # Perform ECO operations in given order
    `@run_opt_signoff`

    # Report collected metrics
    `@report_metrics`
        
    # Close interactive session
    exit
'

# Failed if some files not found
gf_add_failed_marks '^\*\*ERROR:.\+file.\+not'

# Run task
gf_submit_task

########################################
# Innovus ECO
########################################

gf_create_task -name ECO -mother Init
gf_use_innovus

# Wait for TSO task
gf_want_tasks STA -variable STA_TASKS
gf_want_tasks TSO -variable TSO_TASK

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set STA_TASKS {`$STA_TASKS`}
    set TSO_TASK {`$TSO_TASK`}

    # Load input database
    read_db [exec readlink -m ./in/$MOTHER_TASK_NAME.innovus.db]
    
    # Include STA metrics
    `@procs_stylus_metrics`
    gf_include_metrics [concat $STA_TASKS $TSO_TASK]

    # Start metric collection
    `@collect_metrics`

    # Cumulative ECO
    source ./out/$TSO_TASK.eco_innovus.tcl
    
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
gf_add_status_marks -from 'Final .*Summary' -to 'Density:' WNS TNS max_tran -3 +3
gf_add_status_marks -from '\|.*max hotspot.*\|' -expr '[\|\+]' -to '^[^\|\+]*$' -1
gf_add_status_marks 'number of DRC violations'

# Run task
gf_submit_task
