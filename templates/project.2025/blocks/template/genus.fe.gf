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
# Filename: templates/project.2025/blocks/template/genus.fe.gf
# Purpose:  Batch synthesis flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.genus.gf"
# gf_source -once "../../project.innovus.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.genus.gf"
# gf_source -once "./block.innovus.gf"

########################################
# Genus generic synthesis
########################################

gf_create_task -name SynGen
gf_use_genus

# Choose between logical/physical mode 
gf_choose -keep -variable PHYSICAL_MODE -keys YN -time 30 -default N -prompt "Run physical synthesis (Y/N)?"

# Floorplan DEF for Genus
if [ "$PHYSICAL_MODE" == "Y" ]; then
    gf_choose_file_dir_task -variable GENUS_FLOORPLAN_FILE -keep -prompt "Choose floorplan DEF file:" -files '
        ../data/*.fp.def
        ../data/*.fp.def.gz
        ../data/*/*.fp.def
        ../data/*/*.fp.def.gz
        ../work_*/*/out/*.fp.def
        ../work_*/*/out/*.fp.def.gz
    '
fi

# TCL commands
gf_add_tool_commands '

    # Transfer flow variables to the tool
    set PHYSICAL_MODE {`$PHYSICAL_MODE`}
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES` `$PARTITIONS_LEF_FILES -optional`}
    set DESIGN_NAME {`$DESIGN_NAME`}
    set ELAB_DESIGN_NAME {`$ELAB_DESIGN_NAME`}
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}
    set FLOORPLAN_FILE {`$GENUS_FLOORPLAN_FILE -optional`}
    
    # Use separate Generic Config script
    source ./scripts/$TASK_NAME.gconfig.tcl

    # Start metric collection
    `@collect_metrics`
    
    # Pre-load tool options
    `@genus_pre_read_libs`

    # Load MMMC configuration
    read_mmmc ./in/$TASK_NAME.mmmc.tcl

    # Initialize power and ground nets
    set_db init_power_nets [join $POWER_NETS]
    set_db init_ground_nets [join $GROUND_NETS]

    # Read physical information defined in project config
    read_physical -lefs [join $LEF_FILES]

    # Read RTL of current design
    `@genus_read_rtl`
    
    # Initialize library and design information
    elaborate $ELAB_DESIGN_NAME
    `@genus_post_elaborate`
 
    # Design initialization
    init_design -top $DESIGN_NAME
    
    # Read floorplan
    if {$FLOORPLAN_FILE == ""} {
        if {$PHYSICAL_MODE == "Y"} {
            puts "\033\[41;31m \033\[0m Floorplan is empty"
            error 1
        } else {
            puts "\033\[43;33m \033\[0m Floorplan is empty"
        }
        
    } elseif {[file exists $FLOORPLAN_FILE]} {
        read_def $FLOORPLAN_FILE
    } else { 
        if {$PHYSICAL_MODE == "Y"} {
            puts "\033\[41;31m \033\[0m Floorplan $FLOORPLAN_FILE not found"
            error $FLOORPLAN_FILE
        } else {
            puts "\033\[43;33m \033\[0m Floorplan $FLOORPLAN_FILE not found"
        }
    }
    
    # Initialize tool environment
    `@genus_post_init_design_project`
    `@genus_post_init_design`

    # # Load OCV configuration
    # redirect -tee ./reports/$TASK_NAME.ocv.rpt {
    #     reset_timing_derate
    #     source ./in/$TASK_NAME.ocv.tcl
    # }
    
    # Write Genus database
    write_db ./out/$TASK_NAME.intermediate.genus.db
 
    # Run generic synthesis
    `@genus_pre_syn_gen`
    if {$PHYSICAL_MODE == "Y"} {
        syn_generic -physical
    } else {
        syn_generic
    }
    `@genus_post_syn_gen`

    # Setting up DFT
    `@modus_dft_prepare -optional`

    # Write out HDL
    write_hdl > ./out/$TASK_NAME.v
    
    # Report collected metrics
    `@report_metrics`
    
    # Write Genus database
    write_db ./out/$TASK_NAME.genus.db
    
    # Close interactive session
    exit
'

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands '
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@genus_gconfig_design_settings`
    
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

# Task marks
gf_add_status_marks Error ' successful .* failed '
gf_add_failed_marks 'ERROR:.\+No files'
gf_add_success_marks 'No unresolved references'

# Run task
gf_submit_task

########################################
# Genus mapping
########################################

gf_create_task -name SynMap -mother SynGen
gf_use_genus

# Choose between logical/physical mode 
gf_choose -keep -variable PHYSICAL_MODE -keys YN -time 30 -default N -prompt "Run physical synthesis (Y/N)?"

# TCL commands
gf_add_tool_commands '
    set PHYSICAL_MODE {`$PHYSICAL_MODE`}

    # Start metric collection
    `@collect_metrics`
    
    # Read Genus database
    read_db ./out/$MOTHER_TASK_NAME.genus.db
    
    # Run generic synthesis
    `@genus_pre_syn_map`
    if {$PHYSICAL_MODE == "Y"} {
        syn_map -physical
    } else {
        syn_map
    }
    `@genus_post_syn_map`

    # Write out HDL
    write_hdl > ./out/$TASK_NAME.v
    
    # Connect up DFT
    `@modus_dft_connect -optional`

    # Report collected metrics
    `@report_metrics`
    
    # Write Genus database
    write_db ./out/$TASK_NAME.genus.db
    
    # Close interactive session
    exit
'

# Task marks
gf_add_status_marks -1 'Worst cost_group:'

# Run task
gf_add_status_marks Error
gf_submit_task

########################################
# Genus optimization
########################################

gf_create_task -name SynOpt -mother SynMap
gf_use_genus

# Choose between logical/physical mode 
gf_choose -keep -variable PHYSICAL_MODE -keys YN -time 30 -default N -prompt "Run physical synthesis (Y/N)?"

# TCL commands
gf_add_tool_commands '
    set PHYSICAL_MODE {`$PHYSICAL_MODE`}

    # Start metric collection
    `@collect_metrics`
    
    # Read Genus database
    read_db ./out/$MOTHER_TASK_NAME.genus.db
    
    # Run optimization
    `@genus_pre_syn_opt`
    if {$PHYSICAL_MODE == "Y"} {
        # syn_opt -physical
        syn_opt -spatial
    } else {
        syn_opt
    }
    `@genus_post_syn_opt`

    # Write out HDL
    write_hdl > ./out/$TASK_NAME.v
    
    # Report collected metrics
    `@report_metrics`
    
    # Write Genus database
    write_db ./out/$TASK_NAME.genus.db

    # Close interactive session
    exit
'

# Task marks
gf_add_status_marks -1 'Worst cost_group:'

# Run task
gf_add_status_marks Error
gf_submit_task

########################################
# Genus post syn-gen reports task
########################################

gf_create_task -name ReportSynGen -mother SynGen -group Reports
gf_use_genus_batch

# TCL commands
gf_add_tool_commands '

    # Load Genus database
    read_db ./out/$MOTHER_TASK_NAME.genus.db

    # Start metric collection
    `@collect_metrics`

    # Create reports directory
    exec mkdir -p ./reports/$TASK_NAME
    
    # Design-specific reports
    `@genus_design_reports_post_syn_gen`
    
    # Report collected metrics
    `@report_metrics`
'

# Submit task
gf_submit_task -silent

########################################
# Genus post syn-map reports task
########################################

gf_create_task -name ReportSynMap -mother SynMap -group Reports
gf_use_genus_batch

# TCL commands
gf_add_tool_commands '

    # Load Genus database
    read_db ./out/$MOTHER_TASK_NAME.genus.db

    # Start metric collection
    `@collect_metrics`

    # Create reports directory
    exec mkdir -p ./reports/$TASK_NAME
    
    # Design-specific reports
    `@genus_design_reports_post_syn_map`

    # Report collected metrics
    `@report_metrics`
'

# Submit task
gf_submit_task -silent

########################################
# Genus post syn-opt reports task
########################################

gf_create_task -name ReportSynOpt -mother SynOpt -group Reports
gf_use_genus_batch

# TCL commands
gf_add_tool_commands '

    # Load Genus database
    read_db ./out/$MOTHER_TASK_NAME.genus.db

    # Start metric collection
    `@collect_metrics`

    # Create reports directory
    exec mkdir -p ./reports/$TASK_NAME
    
    # Design-specific reports
    `@genus_design_reports_post_syn_map`

    # Report collected metrics
    `@report_metrics`
'

# Submit task
gf_submit_task -silent
