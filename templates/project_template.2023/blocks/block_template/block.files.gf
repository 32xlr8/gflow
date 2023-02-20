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
# Filename: templates/project_template.2023/blocks/block_template/block.files.gf
# Purpose:  Block-specific files configuration
################################################################################

gf_info "Loading block-specific files setup ..."

################################################################################
# Synthesis and implementation files
################################################################################

# Technology LEF files (Cadence PRTF)
CADENCE_TLEF_FILES='
    <PLACEHOLDER:/PATH_TO_TECHNOLOGY.tlef>
'

# LEF files (physical information)
LEF_FILES='
    <PLACEHOLDER:/PATH_TO_STANDARD_CELL_FILE.lef>
    <PLACEHOLDER:/PATH_TO_STANDARD_CELL_FILE_par.lef>
    <PLACEHOLDER:/PATH_TO_MACRO_FILE.lef>
    <PLACEHOLDER:/PATH_TO_FEOL_TCD_FILE.lef>
    <PLACEHOLDER:/PATH_TO_BEOL_TCD_FILE.lef>
'

# GDS files (stream out)
BLOCK_GDS_FILES='
    <PLACEHOLDER:/PATH_TO_STANDARD_CELL_FILE.gds>
    <PLACEHOLDER:/PATH_TO_MACRO_FILE.gds>
    <PLACEHOLDER:/PATH_TO_FEOL_TCD_FILE.gds>
    <PLACEHOLDER:/PATH_TO_BEOL_TCD_FILE.gds>
'

# # Cadence GDS map file and units in nm
# CADENCE_GDS_LAYER_MAP_FILE='<PLACEHOLDER:/PATH_TO_INNOVUS_STREAM_OUT.map>'
# CADENCE_GDS_UNITS=1000

# Cadence MMMC configuration (TCL flow step)
gf_create_step -name gconfig_cadence_mmmc_files '
    # Hint: use ${mode}, ${pvt_p}, ${pvt_v}, ${pvt_t}, ${pvt_rc}/${qrc}, ${check} variables in the file name patterns

    # QRC technology files
    gconfig::add_files qrc {
        /path/qrc_dir_pattern_${qrc}/qrcTechFile
    }

    # Library files
    gconfig::add_files lib {
        -when nldm_libraries {
            /path/liberty/standard_cells_${pvt_p}${pvt_v}${pvt_t}${pvt_rc}.lib
        }
        -when ecsm_libraries {
            /path/liberty/standard_cells_${pvt_p}${pvt_v}${pvt_t}${pvt_rc}_ecsm.lib
        }
        -when ccs_libraries {
            /path/liberty/standard_cells_${pvt_p}${pvt_v}${pvt_t}${pvt_rc}_ccs.lib
        }
        -when lvf_libraries {
            /path/liberty/standard_cells_${pvt_p}${pvt_v}${pvt_t}${pvt_rc}_lvf.lib
        }
        
        /path/liberty/macro_${pvt_p}${pvt_v}${pvt_t}.lib
        
        /path/liberty/block/${mode}_${pvt_p}${pvt_v}${pvt_t}${pvt_rc}_${check}.lib
    }

    # # Celtic database files
    # gconfig::add_files cdb {
    #     -when nldm_libraries {
    #         /path/celtic/standard_cells_${pvt_p}${pvt_v}${pvt_t}${pvt_rc}.cdb
    #
    #         /path/celtic/macro_${pvt_p}${pvt_v}${pvt_t}.cdb
    #     }
    # }

    # # Advanced OCV (AOCV, SBOCV) files
    # gconfig::add_files aocv -when aocv_libraries {
    #     -when ecsm_libraries {
    #         /path/aocv/standard_cells_${pvt_p}${pvt_v}${pvt_t}${pvt_rc}${check}.aocvm
    #     }
    #     -when ccs_libraries {
    #         /path/aocv/standard_cells_${pvt_p}${pvt_v}${pvt_t}${pvt_rc}${check}.aocvm
    #     }
    # }

    # # Statistical OCV (SOCV) files
    # gconfig::add_files socv -when socv_libraries {
    #     /path/aocv/standard_cells_${pvt_p}${pvt_v}${pvt_t}${pvt_rc}${check}.socv
    # }

    # # Block-specific SDC files
    # gconfig::add_files sdc -views {scan * * * * *} {
    #     <PLACEHOLDER:../../../../data/constraints/scan.sdc>
    # }
    gconfig::add_files sdc -views {func * * * * *} {
        <PLACEHOLDER:../../../../data/constraints/func.sdc>
    }
    # gconfig::add_files sdc -views {func tt * * * *} {
    #     <PLACEHOLDER:../../../../data/constraints/func.typ.sdc>
    # }
    # gconfig::add_files sdc -views {func ss * * * *} {
    #     <PLACEHOLDER:../../../../data/constraints/func.slow.sdc>
    # }
    # gconfig::add_files sdc -views {func ff * * * *} {
    #     <PLACEHOLDER:../../../../data/constraints/func.fast.sdc>
    # }
    
    # # View-independent constraints
    # gconfig::add_files sdc {
    #     ../../../../data/constraints/exceptions.sdc
    # }
'

# Synopsys MCMM configuration (TCL flow step)
gf_create_step -name gconfig_synopsys_mcmm_files '
    # To be defined
'

################################################################################
# Signoff files
################################################################################

# Spice netlist files for LVS
LVS_SPICE_FILES='
    <PLACEHOLDER:/PATH_TO_LVS_DIR/source.added>
    <PLACEHOLDER:/PATH_TO_STANDARD_CELL_FILE.cdl>
    <PLACEHOLDER:/PATH_TO_STANDARD_CELL_FILE.spi>
    <PLACEHOLDER:/PATH_TO_MACRO_FILE.cdl>
    <PLACEHOLDER:/PATH_TO_MACRO_FILE.spi>
'

# # Spice models for PGV generation 
# PGV_SPICE_MODELS='<PLACEHOLDER:/PATH_TO/models/spectre/*.scs>'
# PGV_SPICE_CORNERS='<PLACEHOLDER:ss>'
# PGV_SPICE_SCALING=<PLACEHOLDER:0.9>

# Extracted spice files with coordinates for macro PGV generation
# PGV_SPICE_FILES='
#     <PLACEHOLDER:/PATH_TO_MACRO_FILE.spi>
# '

################################################################################
# Optional flow files
################################################################################

# # Scan chains definition DEF file
# SCANDEF_FILE='../../../../data/netlists/DESIGN_NAME.*.scandef'

# # LP design power intent file
# CPF='../../../../data/DESIGN_NAME.*.cpf'
# UPF='../../../../data/DESIGN_NAME.*.upf'

# # Pre-selected floorplan for synthesis and implementation
# FLOORPLAN_FILE='../../../../data/DESIGN_NAME.*.fp'
# FLOORPLAN_FILE='../../../innovus.fp.0000/out/Floorplan.*.fp'

# # Pre-selected netlist for implementation
# NETLIST_FILE="../../../../data/netlists/DESIGN_NAME.*.v"
# NETLIST_FILE="../../../frontend.0000/out/SynMap.v"
# NETLIST_FILE="../../../frontend.0000/out/SynOpt.v"

# Foundry legacy scripts
# DFM_VIA_SWAP_SCRIPT=<PLACEHOLDER:/path/to/the_script.tcl>

################################################################################
# Optional hierarchical flow files
################################################################################

# # Hierarchical flow: partitions to assemble
# INNOVUS_PARTITIONS='<PLACEHOLDER:block1_name block2_name ...>'

# # Hierarchical flow: top level database (leave empty for interactive selection)
# INNOVUS_TOP_DATABASE='<PLACEHOLDER:../../../../../DESIGN_NAME/work_*/innovus.impl.0000/out/PostR.innovus.db>'

# # Hierarchical flow: partition databases (leave empty for interactive selection)
# INNOVUS_PARTITION_DATABASES='
#     <PLACEHOLDER:0../../../../../block1_name/work_*/innovus.impl.0000/out/PostR.innovus.db>
#     <PLACEHOLDER:0../../../../../block2_name/work_*/innovus.eco.0000/out/ECO.innovus.db>
#'
