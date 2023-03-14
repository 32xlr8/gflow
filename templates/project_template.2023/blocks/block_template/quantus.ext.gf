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
# Filename: templates/project_template.2023/blocks/block_template/quantus.ext.gf
# Purpose:  Batch signoff parasitics extraction flow for timing analysis
################################################################################

########################################
# Main options
########################################

# Project and block initialization scripts
gf_source "../../project.common.gf"
gf_source "../../project.quantus.gf"
gf_source "./block.common.gf"
gf_source "./block.files.gf"
gf_source "./block.quantus.gf"

########################################
# Quantus extraction
########################################

gf_create_task -name Extraction
gf_use_quantus_batch

# Choose gconfig file
gf_choose_file_dir_task -variable QUANTUS_CORNERS_CONFIG_FILE -keep -prompt "Please select corners configuration file:" -files '
    ../data/*.timing.tcl
    ../data/*.power.tcl
    ../data/*/*.timing.tcl
    ../data/*/*.power.tcl
    ../work_*/*/out/ConfigSignoff*.timing.tcl
    ../work_*/*/out/ConfigSignoff*.power.tcl
'

# Choose DEF file
gf_choose_file_dir_task -variable QUANTUS_DEF_FILE -keep -prompt "Please select design DEF file:" -files '
    ../data/*.full.def.gz
    ../data/*/*.full.def.gz
    ../work_*/*/out/*/*.full.def.gz
' -want -active -task_to_file '$RUN/out/$TASK/'$DESIGN_NAME'.full.def.gz' -tasks '
    ../work_*/*/tasks/DataOutPhysical*
'

# Select dummy fill to use when empty
if [ -n "$QUANTUS_DUMMY_TOP" -a -z "$QUANTUS_DUMMY_GDS" ]; then
    gf_spacer
    gf_choose -variable USE_DUMMY_GDS -keep -keys YN -time 30 -default Y -prompt "Do you want to use dummy fill GDS (Y/N)?"

    # Select dummy fill to use when required
    if [ "$USE_DUMMY_GDS" == "Y" ]; then
        gf_spacer
        gf_choose_file_dir_task -variable QUANTUS_DUMMY_GDS -keep -prompt "Please select dummy fill to use:" -files '
            ../work_*/*/out/Dummy*.gds.gz
        ' -want -active -task_to_file '$RUN/out/$TASK.gds.gz' -tasks '
            ../work_*/*/tasks/Dummy*
        '
        gf_info "Metal fill GDS \e[32m$QUANTUS_DUMMY_GDS\e[0m selected"
    fi
fi
[[ "$USE_DUMMY_GDS" != "Y" ]] && QUANTUS_DUMMY_GDS=""

# Shell commands to initialize environment
gf_add_shell_commands -init "tclsh ./scripts/$TASK_NAME.config.tcl"

# Quantus CCL commands
gf_add_tool_commands '
    
    # Initialize tool environment
    `@quantus_pre_init_design_technology`
    `@quantus_pre_init_design_timing`
    `@quantus_pre_init_design`
    
    # Load script generated from configuration
    include ./inputs.ccl

    output_setup -directory_name ./ -compressed true
    log_file -dump_options true -max_warning_messages 100
'

# Configuration TCL commands
gf_add_tool_commands -comment '#' -file "./scripts/$TASK_NAME.config.tcl" '
    
    # Current design variables
    set LEF_FILES {`$CADENCE_TLEF_FILES` `$LEF_FILES`}
    set GDS_FILES {`$GDS_FILES`}
    set DEF_FILE {`$QUANTUS_DEF_FILE`}
    set DUMMY_TOP {`$QUANTUS_DUMMY_TOP -optional`}
    set DUMMY_GDS {`$QUANTUS_DUMMY_GDS -optional`}
    set POWER_NETS {`$POWER_NETS_CORE` `$POWER_NETS_OTHER -optional`}
    set GROUND_NETS {`$GROUND_NETS_CORE` `$GROUND_NETS_OTHER -optional`}
    set CORNERS_CONFIG_FILE {`$QUANTUS_CORNERS_CONFIG_FILE`}

    # Load configuration
    source $CORNERS_CONFIG_FILE
    
    # Remove files created before
    exec rm -f ./corner.defs ./lib.defs ./inputs.ccl

    # Create corner definition file for Standalone Quantus
    set FH [open "./corner.defs" w]
    foreach {qrc_corner qrc_tech_file} $QRC_CORNERS {
        puts $FH "DEFINE $qrc_corner [file dirname $qrc_tech_file]"
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
        foreach {extraction_corner qrc_corner temperature} $EXTRACTION_CORNERS {
            lappend spef_files $extraction_corner.spef
            lappend qrc_corners $qrc_corner
            lappend qrc_temperatures $temperature
        }
        
        # Commands to read in LEF files
        puts $FH "input_db -type def -lef_file_list \\\n    [join $LEF_FILES " \\\n    "]\n"
        
        # Commands to read in GDS files
        if {[llength $GDS_FILES] > 0} {
            puts $FH "input_db -type def -gds_file_list \\\n    [join $GDS_FILES " \\\n    "]\n"
        }
        
        # Design DEF file
        puts $FH "input_db -type def -design_file \\\n    $DEF_FILE\n"

        # Command to read in metal fill
        if {$DUMMY_GDS != {}} {
            puts $FH "graybox -type layout"
            puts $FH "input_db -type metal_fill -metal_fill_top_cell $DUMMY_TOP -gds_file \\\n    $DUMMY_GDS\n"
            puts $FH "metal_fill -type \"floating\""
        }
        
        # Global nets
        puts $FH "global_nets -nets [regsub -all {([\[\]])} [concat $POWER_NETS $GROUND_NETS] {\\\1}]\n"    

        # Corners to extract
        puts $FH "process_technology \\\n    -technology_library_file ./lib.defs \\\n    -technology_name qrc_tech_lib \\"
        puts $FH "    -technology_corner \\\n        [join $qrc_corners " \\\n        "] \\"
        puts $FH "    -temperature \\\n        [join $qrc_temperatures " \\\n        "]\n"
        
        # Output file names
        puts $FH "output_db \\\n    -type spef \\\n    -hierarchy_delimiter \"/\" \\\n    -output_incomplete_nets true \\\n    -output_unrouted_nets true \\\n    -subtype \"starN\" \\\n    -user_defined_file_name \\\n        [join $spef_files " \\\n        "]\n"

    close $FH
'

# Move SPEF files to output directory
gf_add_shell_commands -post "bash -e ./scripts/$TASK_NAME.move.sh"
gf_add_tool_commands -file "./scripts/$TASK_NAME.move.sh" '
    for file in *.spef.gz; do
        mv $file ./out/`$TASK_NAME`.$file
        ln -nsf ./out/`$TASK_NAME`.$file $file
    done
'

# Run task
gf_submit_task
