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
# Filename: templates/project.2025/blocks/template/quantus.out.split.gf
# Purpose:  Batch signoff parasitics extraction flow for timing analysis with several tasks splitted by delay corners
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"
gf_source -once "../../project.quantus.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.quantus.gf"

# Run tasks in silent mode
gf_set_task_options 'QuantusOut_*' -silent

########################################
# Split tasks
########################################

# Spread tasks in time
[[ -n "$QUANTUS_WAIT_TIME_STEP" ]] && WAIT_TIME=0

gf_create_task -name SplitQuantusOut -restart
gf_set_task_command "sleep 10; grep -H set ./in/$TASK_NAME/*.tcl"

# Generic Config MMMC generation
gf_use_gconfig
gf_add_tool_commands -file "./tasks/$TASK_NAME/run.tcl" '
    set TASK_NAME {`$TASK_NAME`}
    set DIR "`$GF_RUN_DIR`/tasks/$TASK_NAME"
    cd $DIR

    # Initialize Generic Config 
    source "../../../../../../gflow/bin/gconfig.tcl"

    # Load MMMC procedures
    `@init_gconfig_mmmc`
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@quantus_gconfig_design_settings`

    # Create groups based on input files
    set groups {}
    set grouped_masks {}
    foreach mask $RC_CORNERS {
        set group [gconfig::get extract_corner_name -view $mask]
        if {[lsearch -exact $groups $group] < 0} {
            lappend groups $group
        }
        lappend grouped_masks [list $group $mask]
    }
    
    # Generate timing configuration
    exec mkdir -p ../../in/$TASK_NAME
    set FG [open ../../in/$TASK_NAME.groups "w"]
    foreach group $groups {
        set masks {}
        foreach grouped_mask $grouped_masks {
            if {[lindex $grouped_mask 0] == $group} {
                lappend masks [lindex $grouped_mask 1]
            }
        }
        set file "../../in/$TASK_NAME/$group.tcl"
        set FH [open $file "w"]
        puts $FH "set RC_CORNERS {$masks}"
        close $FH
        puts $FG "$group"
    }
    close $FG
'
if [ -z "$GF_SKIP_TASK" ]; then
    rm -f $GF_RUN_DIR/in/$TASK_NAME/*.tcl $GF_RUN_DIR/in/$TASK_NAME.*.init.tcl
    tclsh $GF_RUN_DIR/tasks/$TASK_NAME/run.tcl
fi

# Statuses
gf_add_status_marks 'tcl:set'

# Run task
SPLIT_TASK_NAME=$TASK_NAME
gf_submit_task

########################################
# Quantus extraction
########################################
for GROUP in $(cat $GF_RUN_DIR/in/$SPLIT_TASK_NAME.groups); do

gf_create_task -name QuantusOut_$GROUP -mother SplitQuantusOut
gf_use_quantus_batch

# Spread tasks in time
if [ -n "$QUANTUS_WAIT_TIME_STEP" -a -z "$GF_SKIP_TASK" ]; then
    gf_wait_time $WAIT_TIME
    WAIT_TIME=$((WAIT_TIME+$QUANTUS_WAIT_TIME_STEP))
fi

# Design data directory
gf_choose_file_dir_task -variable DATA_OUT_DIR -keep -prompt "Choose design data directory:" -dirs '
    ../work_*/*/out/InnovusOut*
' -want -active -task_to_file '$RUN/out/$TASK' -tasks '
    ../work_*/*/tasks/InnovusOut*
'

# Select dummy fill to use when empty
if [ -n "$QUANTUS_DUMMY_TOP" ]; then
    gf_spacer
    gf_choose -variable USE_DUMMY_GDS -keep -keys YN -time 30 -default Y -prompt "Use dummy fill GDS (Y/N)?"
fi

# Select dummy fill to use when empty
if [ -n "$QUANTUS_DUMMY_TOP" -a "$USE_DUMMY_GDS" == "Y" ]; then
    gf_spacer
    gf_choose_file_dir_task -variable QUANTUS_DUMMY_GDS -keep -prompt "Choose dummy fill to use:" -files '
        ../work_*/*/out/Dummy*.gds.gz
    ' -want -active -task_to_file '$RUN/out/$TASK.gds.gz' -tasks '
        ../work_*/*/tasks/Dummy*
    '
else
    QUANTUS_DUMMY_GDS=""
fi

# Shell commands to initialize environment
gf_add_shell_commands -init "
    rm -f *.spef.gz
    tclsh ./scripts/$TASK_NAME.gconfig.tcl
"

# Quantus CCL commands
gf_add_tool_commands '
    
    # Initialize tool environment
    `@quantus_pre_init_design_project`
    `@quantus_pre_init_design`
    
    # Load script generated from configuration
    include ./inputs.ccl

    output_setup -directory_name ./ -compressed true
    log_file -dump_options true -max_warning_messages 100
'

# GConfig TCL commands
gf_use_gconfig
gf_add_tool_commands '

    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES` `$PARTITIONS_LEF_FILES -optional`}
    set GDS_FILES {`$GDS_FILES` `$PARTITIONS_GDS_FILES -optional`}
    set QUANTUS_DUMMY_TOP {`$QUANTUS_DUMMY_TOP -optional`}
    set QUANTUS_DUMMY_GDS {`$QUANTUS_DUMMY_GDS -optional`}

    set DESIGN_NAME {`$DESIGN_NAME`}
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}

    set DATA_OUT_DIR {`$DATA_OUT_DIR`}

    # Initialization
    `@gconfig_project_settings`
    `@gconfig_settings_common`
    `@gconfig_cadence_mmmc_files`
    `@quantus_gconfig_design_settings`

    # Load split configuration
    source ./in/`$MOTHER_TASK_NAME`/`$GROUP`.tcl

    # Remove files created before
    exec rm -f ./corner.defs ./lib.defs ./inputs.ccl

    # Get qrc corners from signoff views list
    set index {}
    set QRC_CORNERS {}
    foreach view $RC_CORNERS {
        set name [lindex $view 4]

        # Add qrc corner once
        if {[lsearch -exact $index $name] == -1} {
            lappend index $name
            lappend QRC_CORNERS [list $name [gconfig::get_files qrc -view [list * * * * $name *]]]
        }
    }

    # Get extraction corners from signoff views list
    set index {}
    set EXTRACTION_CORNERS {}
    foreach view $RC_CORNERS {
        set name [gconfig::get extract_corner_name -view $view]

        # Add extraction corner once
        if {[lsearch -exact $index $name] == -1} {
            lappend index $name
            lappend EXTRACTION_CORNERS [list $name [lindex $view 4] [gconfig::get temperature -view $view]]
        }
    }

    # Create corner definition file for Standalone Quantus
    set FH [open "./corner.defs" w]
    foreach qrc_corner $QRC_CORNERS {
        puts $FH "DEFINE [lindex $qrc_corner 0] [file dirname [lindex $qrc_corner 1]]"
    }
    close $FH
    
    # Create library definition file for Standalone Quantus
    set FH [open "./lib.defs" w]
        puts $FH "DEFINE qrc_tech_lib ."
    close $FH
    
    # Create input file commands for Standalone Quantus
    set FH [open "./inputs.ccl" w]
    
        # Get corners from configuration
        set qrc_corners {}
        set qrc_temperatures {}
        set spef_files {}
        foreach extraction_corner $EXTRACTION_CORNERS {
            lappend spef_files [lindex $extraction_corner 0].spef
            lappend qrc_corners [lindex $extraction_corner 1]
            lappend qrc_temperatures [lindex $extraction_corner 2]
        }
        
        # Commands to read in LEF files
        puts $FH "input_db -type def -lef_file_list \\\n    [join $LEF_FILES " \\\n    "]\n"
        
        # Commands to read in GDS files
        if {[llength $GDS_FILES] > 0} {
            puts $FH "input_db -type def -gds_file_list \\\n    [join $GDS_FILES " \\\n    "]\n"
        }
        
        # Design DEF file
        puts $FH "input_db -type def -design_file \\\n    $DATA_OUT_DIR/$DESIGN_NAME.full.def.gz\n"

        # Command to read in metal fill
        if {$QUANTUS_DUMMY_GDS != {}} {
            puts $FH "graybox -type layout"
            puts $FH "input_db -type metal_fill -metal_fill_top_cell $QUANTUS_DUMMY_TOP -gds_file \\\n    $QUANTUS_DUMMY_GDS\n"
            puts $FH "metal_fill -type \"floating\""
        }
        
        # Global nets
        puts $FH "global_nets -nets [regsub -all {([\[\]])} [join [concat $POWER_NETS $GROUND_NETS]] {\\\1}]\n"    

        # Corners to extract
        puts $FH "process_technology \\\n    -technology_library_file ./lib.defs \\\n    -technology_name qrc_tech_lib \\"
        puts $FH "    -technology_corner \\\n        [join $qrc_corners " \\\n        "] \\"
        puts $FH "    -temperature \\\n        [join $qrc_temperatures " \\\n        "]\n"
        
        # Output file names
        puts $FH "output_db \\\n    -type spef \\\n    -hierarchy_delimiter \"/\" \\\n    -output_incomplete_nets true \\\n    -output_unrouted_nets true \\\n    -subtype \"starN\" \\\n    -user_defined_file_name \\\n        [join $spef_files " \\\n        "]\n"

    close $FH
'

# Run task
gf_submit_task

done

########################################
# Summary task
########################################

gf_create_task -name QuantusOut -mother SplitQuantusOut
gf_want_tasks QuantusOut_* -variable QUANTUS_TASKS
gf_set_task_command "bash -e ./scripts/$TASK_NAME.sh"

# Move SPEF files to output directory
gf_add_tool_commands -file "./scripts/$TASK_NAME.sh" -comment '#' '
    TASK_NAME=`$TASK_NAME`
    DESIGN_NAME=`$DESIGN_NAME`
    
    # Move spef files to the output directory
    rm -Rf ./out/$TASK_NAME/
    mkdir -p ./out/$TASK_NAME/
    for task in `$QUANTUS_TASKS`; do
        for file in ../../tasks/$task/*.spef.gz; do
            result_file=./out/$TASK_NAME/$DESIGN_NAME.$(basename $file)
            mv $file $result_file
            ln -nsf $result_file $file
            echo $result_file
        done
    done
'

# Statuses
gf_add_status_marks '\.spef\.gz'

# Run task
gf_submit_task

########################################
# Generic Flow history
########################################

gf_create_task -name HistoryQuantusOut -mother QuantusOut
gf_set_task_command "../../../../../../tools/print_flow_history.pl ../.. -html ./reports/$TASK_NAME.html"
gf_submit_task -silent
