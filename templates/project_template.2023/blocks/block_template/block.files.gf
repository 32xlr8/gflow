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
# Physical files - many flows
################################################################################

# Technology LEF files (Cadence PRTF)
CADENCE_TLEF_FILES='
    <PLACEHOLDER>/PATH_TO_TECHNOLOGY.tlef
'

# LEF files (physical information)
LEF_FILES='
    <PLACEHOLDER>/PATH_TO_STANDARD_CELL_FILE.lef
    <PLACEHOLDER>/PATH_TO_STANDARD_CELL_FILE_par.lef
    <PLACEHOLDER>/PATH_TO_MACRO_FILE.lef
    <PLACEHOLDER>/PATH_TO_FEOL_TCD_FILE.lef
    <PLACEHOLDER>/PATH_TO_BEOL_TCD_FILE.lef
'

# # GDS files (stream out) - ./innovus.out.gf
# GDS_FILES='
#     <PLACEHOLDER>/PATH_TO_STANDARD_CELL_FILE.gds
#     <PLACEHOLDER>/PATH_TO_MACRO_FILE.gds
#     <PLACEHOLDER>/PATH_TO_FEOL_TCD_FILE.gds
#     <PLACEHOLDER>/PATH_TO_BEOL_TCD_FILE.gds
# '

# # Spice files (LVS) - ./calibre.phys.gf, ./pegasus.phys.gf, ./icv.phys.gf
# CDL_FILES='
#     <PLACEHOLDER>/PATH_TO_LVS_DIR/source.added
#     <PLACEHOLDER>/PATH_TO_STANDARD_CELL_FILE.cdl
#     <PLACEHOLDER>/PATH_TO_STANDARD_CELL_FILE.spi
#     <PLACEHOLDER>/PATH_TO_MACRO_FILE.cdl
#     <PLACEHOLDER>/PATH_TO_MACRO_FILE.spi
# '

################################################################################
# Timing analysis files - ./config.out.gf
################################################################################

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
    #     <PLACEHOLDER>../../../../data/scan.sdc
    # }
    gconfig::add_files sdc -views {func * * * * *} {
        <PLACEHOLDER>../../../../data/func.sdc
    }

    # # Clock uncertainty stored in separate SDC files
    # gconfig::add_files sdc -views {func tt * * * *} {
    #     <PLACEHOLDER>../../../../data/uncertainty.tt.sdc
    # }
    # gconfig::add_files sdc -views {func ss * * * *} {
    #     <PLACEHOLDER>../../../../data/uncertainty.ss.sdc
    # }
    # gconfig::add_files sdc -views {func ff * * * *} {
    #     <PLACEHOLDER>../../../../data/uncertainty.ff.sdc
    # }
    
    # # View-independent constraints
    # gconfig::add_files sdc {
    #     ../../../../data/exceptions.sdc
    # }
'

################################################################################
# RTL files - ./genus.fe.gf
################################################################################

# # Paths to locate relative RTL files (only when RTL files used without full path)
# RTL_SEARCH_PATHS='
#     <PLACEHOLDER>../../../../../../data/hdl
#     <PLACEHOLDER>../../../../data/hdl
# '
# 
# # Option 1: List of system-verilog RTL files for synthesis
# RTL_FILES='
#     <PLACEHOLDER>block_name.sv
# '
# # Option 2: System-verilog RTL files list for synthesis
# RTL_FILES_LIST='<PLACEHOLDER>/path/to/block_name.f'

################################################################################
# Common design files - ./genus.fe.gf, ./innovus.be.gf
################################################################################

# # Scan chains definition DEF file (required if scan chains exist in the design)
# SCANDEF_FILE='../../../../data/DESIGN_NAME.*.scandef'

# # Power intent file for low-power design (optional)
# CPF_FILE='../../../../data/DESIGN_NAME.*.cpf'
# UPF_FILE='../../../../data/DESIGN_NAME.*.upf'

################################################################################
# Genus input files - ./innovus.fp.gf, ./innovus.be.gf
################################################################################

# # Timing configuration
# GENUS_TIMING_CONFIG_FILE='../../../config.gen.0000/out/ConfigBackend*.timing.tcl'

# # DEF floorplan for physical synthesis
# GENUS_FLOORPLAN_FILE='../../../../data/DESIGN_NAME.*.fp.def.gz'
# GENUS_FLOORPLAN_FILE='../../../innovus.fp.0000/out/Floorplan.*.fp.def.gz'

################################################################################
# Innovus input files - ./innovus.fp.gf, ./innovus.be.gf, ./innovus.out.gf
################################################################################

# # Innovus GDS map file and units in nm (mandatory for ./innovus.out.gf)
# INNOVUS_GDS_LAYER_MAP_FILE='<PLACEHOLDER>/PATH_TO_INNOVUS_STREAM_OUT.map'
# INNOVUS_GDS_UNITS=1000

# # Timing configuration (optional, will be asked if empty)
# INNOVUS_TIMING_CONFIG_FILE='../../../config.gen.0000/out/ConfigBackend*.timing.tcl'

# # Floorplan for implementation (optional, will be asked if empty)
# INNOVUS_FLOORPLAN_FILE='../../../../data/DESIGN_NAME.*.fp'
# INNOVUS_FLOORPLAN_FILE='../../../innovus.fp.0000/out/Floorplan.*.fp'

# # Netlist for implementation (optional, will be asked if empty)
# INNOVUS_NETLIST_FILES='../../../../data/DESIGN_NAME.*.v'
# INNOVUS_NETLIST_FILES='../../../frontend.0000/out/SynMap.v'
# INNOVUS_NETLIST_FILES='../../../frontend.0000/out/SynOpt.v'

# # Foundry legacy scripts (optional, if used in ./block.innovus.gf)
# INNOVUS_DFM_VIA_SWAP_SCRIPT='<PLACEHOLDER>/path/to/the_script.tcl'

# # Partitions to assemble (hierarchical flow only)
# INNOVUS_PARTITIONS='<PLACEHOLDER>block1_name block2_name ...'

# # Top level database (hierarchical flow only, leave empty for interactive selection)
# INNOVUS_TOP_DATABASE='<PLACEHOLDER>../../../../../DESIGN_NAME/work_*/innovus.be.0000/out/Route.innovus.db'

# # Partition databases (hierarchical flow only, leave empty for interactive selection)
# INNOVUS_PARTITION_DATABASES='
#     <PLACEHOLDER>../../../../../block1_name/work_*/innovus.be.0000/out/Route.innovus.db
#     <PLACEHOLDER>../../../../../block2_name/work_*/innovus.eco.0000/out/ECO.innovus.db
#'

################################################################################
# Quantus input files - ./quantus.ext.gf
################################################################################

# # Quantus extraction files (optional, can be manually defined in ./block.quantus.gf)
# QUANTUS_DEF_LAYER_MAP_FILE='/PATH_TO/PRTF_Innovus_*/PR_tech/Cadence/QrcMap/PRTF_Innovus_*.map'
# QUANTUS_GDS_LAYER_MAP_FILE='/PATH_TO/PRTF_Innovus_*/PR_tech/Cadence/QrcDummyMap/PRTF_Innovus_*'

# # Corners configuration (optional, will be asked if empty)
# QUANTUS_CORNERS_CONFIG_FILE='/path/to/out/ConfigBackend*.timing.tcl'
# QUANTUS_CORNERS_CONFIG_FILE='/path/to/out/ConfigBackend*.power.tcl'

# # Design DEF (optional, will be asked if empty)
# QUANTUS_DEF_FILE='../../../innovus.out.000/out/DataOutPhysical*.full.def.gz'

# # Dummy fill top cell name (required to enable parasitics extraction flow with dummy fill)
# QUANTUS_DUMMY_TOP="<PLACEHOLDER>${DESIGN_NAME}_dummy_fill"
#
# # Dummy fill GDS (optional, will be asked if empty)
# QUANTUS_DUMMY_GDS='../../../calibre.phys.000/out/Dummy*.gds.gz'
# QUANTUS_DUMMY_GDS='../../../pegasus.phys.000/out/Dummy*.gds.gz'
# QUANTUS_DUMMY_GDS='../../../pvs.phys.000/out/Dummy*.gds.gz'
# QUANTUS_DUMMY_GDS='../../../icv.phys.000/out/Dummy*.gds.gz'

################################################################################
# Tempus input files - ./tempus.sta.gf
################################################################################

# # Specific design configuration for STA (optional, will be asked if empty)
# TEMPUS_STA_TIMING_CONFIG_FILE='../../../config.gen.0000/out/ConfigSignoff*.timing.tcl'

# # Specific design configuration for TSO (optional, will be asked if empty)
# TEMPUS_TSO_TIMING_CONFIG_FILE='../../../config.gen.0000/out/ConfigSignoff*.timing.tcl'

################################################################################
# Voltus files - ./voltus.pgv.gf, ./voltus.rail.gf
################################################################################

# # Spice models for PGV generation (mandatory for detailed PGV)
# VOLTUS_PGV_SPICE_MODELS='<PLACEHOLDER>/PATH_TO/models/spectre/*.scs'
# VOLTUS_PGV_SPICE_CORNERS='<PLACEHOLDER>ss'
# VOLTUS_PGV_SPICE_SCALING=<PLACEHOLDER>0.9

# Extracted spice files with coordinates for macro PGV generation (mandatory for detailed PGV)
# VOLTUS_PGV_SPICE_FILES='
#     <PLACEHOLDER>/PATH_TO_MACRO_FILE.spi
# '

# # Signal EM analysis rule file (mandatory for signal elecromigration analysis)
# VOLTUS_ICT_EM_RULE='<PLACEHOLDER>/PATH_TO/VOLTUS_EM_RULE.ictem'

# # PGV libraries for rail analysis (optional, will be asked if empty)
# VOLTUS_PGV_LIBS="
#     <PLACEHOLDER>../../../../../voltus.pgv.0000/out/TechPGV/techonly.cl
#     <PLACEHOLDER>../../../../../voltus.pgv.0000/out/CellsPGV/stdcells.cl
#     <PLACEHOLDER>../../../../../voltus.pgv.0000/out/MacrosPGV/macros.cl
# "

# # Specific design configuration for power analysis (optional, will be asked if empty)
# VOLTUS_POWER_CONFIG_FILE='../../../config.gen.0000/out/ConfigSignoff*.power.tcl'
# VOLTUS_DATA_OUT_CONFIG_FILE='../../../innovus.out.0000/out/DataOutPhysical*.design.tcl'
# VOLTUS_SPEF_CONFIG_FILE='../../../quantus.ext.0000/out/Extraction*.design.tcl'

################################################################################
# Calibre input files - ./calibre.phys.gf
################################################################################

# # Physical verification rules for Calibre (mandatory)
# CALIBRE_DRC_RULES='<PLACEHOLDER>/PATH_TO_DRC_RULE_FILE'
# CALIBRE_LVS_RULES='<PLACEHOLDER>/PATH_TO_LVS_RULE_FILE'
# CALIBRE_FILL_RULES='<PLACEHOLDER>/PATH_TO_COMBINED_FEOL_BEOL_FILL_RULE_FILE'
# CALIBRE_ANT_RULES='<PLACEHOLDER>/PATH_TO_ANTENNA_RULE_FILE'
# CALIBRE_BUMP_RULES='<PLACEHOLDER>/PATH_TO_BUMP_RULE_FILE'

# # Hierarchical cells file used for LVS (optional, auto-generated when empty)
# HCELL_FILE='<PLACEHOLDER>../../../../data/hcell'
