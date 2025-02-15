#!../../gflow/bin/gflow

################################################################################
# Generic Flow v5.5.1 (February 2025)
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
# Filename: templates/project.2025/blocks/template/tempus.tso.gf
# Purpose:  Batch signoff ECO flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.tempus.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.tempus.gf"

########################################
# Tempus signoff ECO
########################################

gf_create_task -name TSO
gf_use_tempus -eco

# Design data directory
gf_choose_file_dir_task -variable DATA_OUT_DIR -keep -prompt "Choose design data directory:" -dirs '
    ../work_*/*/out/InnovusOut*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/InnovusOut*
'

# SPEF directory
gf_choose_file_dir_task -variable SPEF_OUT_DIR -keep -prompt "Choose SPEF directory:" -dirs '
    ../work_*/*/out/QuantusOut*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/QuantusOut*
'

# Choose configuration file
gf_choose_file_dir_task -variable ECO_DB_DIR -keep -prompt "Choose Tempus ECO directory:" -dirs '
    ../work_*/*/out/STA*.tempus.eco.db
' -want -active -task_to_file '$RUN/out/$TASK.tempus.eco.db' -tasks '
    ../work_*/*/tasks/STA*
'

# Choose scenario
gf_choose -keep -variable ECO_SCENARIO -message "Which ECO scenario to run?" -variants "$(echo "$ECO_SCENARIOS" | sed -e 's|^\s\+||g; s|\s\+$||g;')" -count 25

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES` `$PARTITIONS_LEF_FILES -optional`}

    set DESIGN_NAME {`$DESIGN_NAME`}
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}

    set DATA_OUT_DIR {`$DATA_OUT_DIR`}
    set SPEF_OUT_DIR {`$SPEF_OUT_DIR`}
    set ECO_DB_DIR {`$ECO_DB_DIR`}

    set ECO_SCENARIO {`$ECO_SCENARIO`}
    set IGNORE_IO_TIMING {`$IGNORE_IO_TIMING`}

    # Start metric collection
    `@collect_metrics`

    # Use separate Generic Config script
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Load common tool procedures
    source ./scripts/$TASK_NAME.procs.tcl

    # Pre-load settings
    `@tempus_pre_read_libs`
    
    # Initialize power and ground nets
    set_db init_power_nets [join $POWER_NETS]
    set_db init_ground_nets [join $GROUND_NETS]

    # Load MMMC configuration
    read_mmmc ./in/$TASK_NAME.mmmc.tcl

    # Read physical information defined in project config
    read_physical -lefs [join $LEF_FILES]

    # Load netlist
    read_netlist $DATA_OUT_DIR/$DESIGN_NAME.v.gz -top $DESIGN_NAME
    
    # Initialize design with MMMC configuration
    init_design
    
    # Load physical data
    read_def $DATA_OUT_DIR/$DESIGN_NAME.lite.def.gz
    
    # Read parasitics
    gf_read_parasitics $SPEF_OUT_DIR/$DESIGN_NAME
    
    # Initialize tool environment
    `@tempus_post_init_design_project`
    `@tempus_post_init_design`

    # Init cells allowed for ECO
    `@init_cells_tempus`

    # Read ECO timing DB
    set_db opt_signoff_read_eco_opt_db $ECO_DB_DIR
    
    # Multiple ECO in the same session
    set_db opt_signoff_allow_multiple_incremental true
    
    # Do not optimize interface paths
    if {$IGNORE_IO_TIMING == "Y"} {
        set_db opt_signoff_optimize_core_only true
    }
        
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

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands '
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@tempus_gconfig_design_settings`
    
    # Print out summary
    gconfig::show_variables
    gconfig::show_switches

    # Generate timing configuration
    try {
        gconfig::get_ocv_commands -views $MMMC_VIEWS -dump_to_file ./in/$TASK_NAME.ocv.tcl
        gconfig::get_mmmc_commands -views $MMMC_VIEWS -dump_to_file ./in/$TASK_NAME.mmmc.tcl

    # Suspend on error
    } on error {result options} {
        exec rm -f ./in/$TASK_NAME.ocv.tcl ./in/$TASK_NAME.mmmc.tcl
        puts "\033\[41;31m \033\[0m $result"
        suspend
    }
'

# Common tool procedures
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.procs.tcl '
    `@tempus_procs_common`
    `@procs_tempus_read_data`
'

# Statuses
gf_add_status_marks '^\w+\s+file:'

# Failed if some files not found
gf_add_failed_marks '^\*\*ERROR:.+file\s+not'

# Run task
gf_submit_task
