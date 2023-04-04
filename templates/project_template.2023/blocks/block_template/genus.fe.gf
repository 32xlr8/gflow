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
# Filename: templates/project_template.2023/blocks/block_template/genus.fe.gf
# Purpose:  Batch synthesis flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source "../../project.common.gf"
gf_source "../../project.genus.gf"
# gf_source "../../project.innovus.gf"
gf_source "./block.common.gf"
gf_source "./block.files.gf"
gf_source "./block.genus.gf"
# gf_source "./block.innovus.gf"

########################################
# Genus generic synthesis
########################################

gf_create_task -name SynGen
gf_use_genus

# Choose between logical/physical mode 
gf_choose -keep -variable PHYSICAL_MODE -keys YN -time 30 -default Y -prompt "Do you want to run physical synthesis (Y/N)?"

# Choose floorplan for physical mode if not chosen
if [ "$PHYSICAL_MODE" == "Y" ]; then
    gf_choose_file_dir_task -variable GENUS_FLOORPLAN_FILE -keep -prompt "Choose floorplan DEF file:" -files '
        ../data/*.fp.def
        ../data/*.fp.def.gz
        ../data/*/*.fp.def
        ../data/*/*.fp.def.gz
        ../work_*/*/out/*.fp.def
        ../work_*/*/out/*.fp.def.gz
    '

    # Create floorplan files copy in the run directory
    [[ -n "$GENUS_FLOORPLAN_FILE" ]] && gf_save_files -copy $(dirname $GENUS_FLOORPLAN_FILE)/$(basename $GENUS_FLOORPLAN_FILE .gz)*
fi

# Choose configuration file
gf_choose_file_dir_task -variable GENUS_TIMING_CONFIG_FILE -keep -prompt "Choose timing configuration file:" -files '
    ../data/*.timing.tcl
    ../data/*/*.timing.tcl
    ../work_*/*/out/ConfigFrontend*.timing.tcl
'

# TCL commands
gf_add_tool_commands '

    # Transfer flow variables to the tool
    set PHYSICAL_MODE {`$PHYSICAL_MODE`}
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set DESIGN_NAME {`$DESIGN_NAME`}
    set ELAB_DESIGN_NAME {`$ELAB_DESIGN_NAME`}
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}
    set FLOORPLAN_FILE {`$GENUS_FLOORPLAN_FILE -optional`}
    set GENUS_TIMING_CONFIG_FILE {`$GENUS_TIMING_CONFIG_FILE`}
    
    # Load configuration variables
    source $GENUS_TIMING_CONFIG_FILE

    # Start metric collection
    `@collect_metrics`
    
    # Pre-load tool options
    `@genus_pre_read_libs`

    # Load MMMC configuration
    read_mmmc $MMMC_FILE

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
    `@genus_post_init_design_technology`
    `@genus_post_init_design`

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
    
    # # Load OCV configuration
    # redirect -tee ./reports/$TASK_NAME.ocv.rpt {
    #     reset_timing_derate
    #     source $OCV_FILE
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
gf_choose -keep -variable PHYSICAL_MODE -keys YN -time 30 -default Y -prompt "Do you want to run physical synthesis (Y/N)?"

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

# Run task
gf_add_status_marks Error
gf_submit_task

########################################
# Genus optimization
########################################

gf_create_task -name SynOpt -mother SynMap
gf_use_genus

# Choose between logical/physical mode 
gf_choose -keep -variable PHYSICAL_MODE -keys YN -time 30 -default Y -prompt "Do you want to run physical synthesis (Y/N)?"

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
