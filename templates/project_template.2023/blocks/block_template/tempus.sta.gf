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
# Filename: templates/project_template.2023/blocks/block_template/tempus.sta.gf
# Purpose:  Batch signoff STA flow
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source "../../project.common.gf"
gf_source "../../project.tempus.gf"
gf_source "./block.common.gf"
gf_source "./block.files.gf"
gf_source "./block.tempus.gf"

########################################
# Tempus STA
########################################

gf_create_task -name STA
gf_use_tempus

# Choose configuration file
gf_choose_file_dir_task -variable TEMPUS_TIMING_CONFIG_FILE -keep -prompt "Choose timing configuration file:" -files '
    ../data/*.timing.tcl
    ../data/*/*.timing.tcl
    ../work_*/*/out/ConfigSignoff*.timing.tcl
'

# Choose configuration file
gf_choose_file_dir_task -variable TEMPUS_DATA_OUT_CONFIG_FILE -keep -prompt "Choose design configuration file:" -files '
    ../data/*.design.tcl
    ../data/*/*.design.tcl
    ../work_*/*/out/DataOutPhysical*.design.tcl
' -want -active -task_to_file '$RUN/out/$TASK.design.tcl' -tasks '
    ../work_*/*/tasks/DataOutPhysical*
'

# Choose configuration file
gf_choose_file_dir_task -variable TEMPUS_SPEF_CONFIG_FILE -keep -prompt "Choose SPEF configuration file:" -files '
    ../data/*.design.tcl
    ../data/*/*.design.tcl
    ../work_*/*/out/Extraction*.design.tcl
' -want -active -task_to_file '$RUN/out/$TASK.design.tcl' -tasks '
    ../work_*/*/tasks/Extraction*
'

# TCL commands
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}

    set DESIGN_NAME {`$DESIGN_NAME`} 
    set IGNORE_IO_TIMING {`$IGNORE_IO_TIMING`}

    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}

    set TEMPUS_TIMING_CONFIG_FILE {`$TEMPUS_TIMING_CONFIG_FILE`}
    set TEMPUS_DATA_OUT_CONFIG_FILE {`$TEMPUS_DATA_OUT_CONFIG_FILE`}
    set TEMPUS_SPEF_CONFIG_FILE {`$TEMPUS_SPEF_CONFIG_FILE`}

    # Load configuration variables
    source $TEMPUS_TIMING_CONFIG_FILE
    source $TEMPUS_DATA_OUT_CONFIG_FILE
    source $TEMPUS_SPEF_CONFIG_FILE
    
    # Start metric collection
    `@collect_metrics`

    # Load common tool procedures
    source ./scripts/$TASK_NAME.procs.tcl

    # Pre-load settings
    `@tempus_pre_read_libs`
    
    # Initialize power and ground nets
    set_db init_power_nets [join $POWER_NETS]
    set_db init_ground_nets [join $GROUND_NETS]

    # Load MMMC configuration
    read_mmmc $MMMC_FILE

    # Read physical information defined in project config
    read_physical -lefs [join $LEF_FILES]
    
    # Load netlist
    read_netlist $NETLIST_FILE -top $DESIGN_NAME
    
    # Initialize design with MMMC configuration
    init_design
    
    # Load OCV configuration
    redirect -tee ./reports/$TASK_NAME.ocv.rpt {
        reset_timing_derate
        source $OCV_FILE
    }
    redirect ./reports/$TASK_NAME.derate.rpt {report_timing_derate}
    
    # Initialize tool environment
    `@tempus_post_init_design_technology`
    `@tempus_post_init_design`

    # Read parasitics
    gf_read_parasitics $SPEF_DIR/$SPEF_TASK_NAME
    
    # Path groups for analysis
    if {[catch create_basic_path_groups]} {
        set registers [all_registers]
        group_path -name reg2reg -from $registers -to $registers
    }

    # Switch to propagated clocks mode
    if {$IGNORE_IO_TIMING == "Y"} {
        set_interactive_constraint_mode [get_db [get_db constraint_modes -if {.is_setup||.is_hold}] .name]
        reset_propagated_clock [get_clocks *] 
        set_propagated_clock [get_clocks *] 
        set_interactive_constraint_mode {}
    } else {
        update_io_latency
    }

    # Timing analysis
    `@reports_sta_tempus`
    
    # Report collected metrics
    `@report_metrics`
        
    # Close interactive session
    exit
'

# Common tool procedures
gf_add_tool_commands -comment '#' -file ./scripts/$TASK_NAME.procs.tcl '
    `@tempus_procs_common`
    `@procs_tempus_read_data`
'

# # Postprocess timing summary file
# gf_add_shell_commands -post '
    # cat ./reports/$TASK_NAME/timing.summary | perl -e '"'"'
        # my $view = "";
        # my $type = "";
        # while (<STDIN>) {
            # if (/View:(\w+)/) {
                # $view = $1;
                # $type = "";
                # print "  | $view\n";
            # } elsif ($view ne "") {
                # if (/GroupType:(\w+)/) {
                    # $type = $1;
                # } elsif ($type ne "") {
                    # s/\s+/ /g;
                    # if (s/[-\d\.]+:[-\d\.]+:[-\d\.]+\s+[-\d\.]+:[-\d\.]+:[-\d\.]+\s+[-\d\.]+:[-\d\.]+:[-\d\.]+\s+([-\d\.]+):([-\d\.]+):([-\d\.]+)\s+[-\d\.]+:[-\d\.]+:[-\d\.]+\s+/sprintf("%7s:%-7s:%-10s", $1, $2, $3)/ge) {
                        # # print "  | ".sprintf("%-10s", $type)." $_\n";
                        # print "  | $_\n";
                    # }
                # }
            # }
        # }
    # '"'"'
# '

# Failed if some files not found
gf_add_failed_marks '^\*\*ERROR:.\+file.\+not'

# # Print summary
# gf_add_status_marks '(Group|View) : '  'Check : .*[1-9\-]' 
# gf_add_status_marks -1 +1 '^# (SETUP|HOLD|DRV)' '^  \|'

# Run task
gf_submit_task
