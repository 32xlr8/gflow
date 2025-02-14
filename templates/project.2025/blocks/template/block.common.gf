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
# Filename: templates/project.2025/blocks/template/block.common.gf
# Purpose:  Block-specific configuration and flow steps
################################################################################

gf_info "Loading block-specific setup ..."

################################################################################
# Flow options
################################################################################

# Default tasks resources
gf_set_task_options -cpu 8 -mem 20

# # Disable Generic Flow history tasks
# gf_set_task_options -disable History*

################################################################################
# Flow variables
################################################################################

# Top cell name in netlist (default is current block directory name)
DESIGN_NAME="$(basename $PWD | sed -e 's|\..*$||')"
# <PLACEHOLDER>
# DESIGN_NAME='block_name'

# Global core nets
POWER_NETS_CORE='VDD'
GROUND_NETS_CORE='VSS'

# # Other global nets
# <PLACEHOLDER>
# POWER_NETS_OTHER='VDDA VDDPST'
# GROUND_NETS_OTHER='VSSA VSSPST'

################################################################################
# Physical files
################################################################################

# Technology LEF files (Cadence PRTF)
CADENCE_TLEF_FILES='
    <PLACEHOLDER>
    /PATH_TO_TECHNOLOGY.tlef
'

# LEF files (physical information)
LEF_FILES='
    <PLACEHOLDER>
    /PATH_TO_STANDARD_CELL_FILE.lef
    /PATH_TO_STANDARD_CELL_FILE_par.lef
    /PATH_TO_MACRO_FILE.lef
    /PATH_TO_FEOL_TCD_FILE.lef
    /PATH_TO_BEOL_TCD_FILE.lef
'

# # GDS files (stream out)
# GDS_FILES='
#     /PATH_TO_STANDARD_CELL_FILE.gds
#     /PATH_TO_MACRO_FILE.gds
#     /PATH_TO_FEOL_TCD_FILE.gds
#     /PATH_TO_BEOL_TCD_FILE.gds
# '

# # Spice files (LVS)
# CDL_FILES='
#     /PATH_TO_LVS_DIR/source.added
#     /PATH_TO_STANDARD_CELL_FILE.cdl
#     /PATH_TO_STANDARD_CELL_FILE.spi
#     /PATH_TO_MACRO_FILE.cdl
#     /PATH_TO_MACRO_FILE.spi
# '

################################################################################
# Timing analysis files
################################################################################

# Cadence MMMC configuration (TCL flow step)
gf_create_step -name gconfig_cadence_mmmc_files '
    # Hint: use ${mode}, ${pvt_p}, ${pvt_v}, ${pvt_t}, ${pvt_rc}/${qrc}, ${check} variables in the file name patterns

    # QRC technology files
    gconfig::add_files qrc {
        /path/qrc_dir_pattern_${qrc}/qrcTechFile
    }

    # # Cap Table files when QRC technology files not available
    # gconfig::add_files cap_table {
    #     /path/cap_table_dir_pattern_${qrc}.capTbl
    # }

    # Library files
    gconfig::add_files lib {
        -when nldm_libraries {
            /path/liberty/standard_cells_${pvt_p}${pvt_v}v${pvt_t}c${pvt_rc}.lib
        }
        -when ecsm_libraries {
            /path/liberty/standard_cells_${pvt_p}${pvt_v}v${pvt_t}c${pvt_rc}_ecsm.lib
        }
        -when ecsm_p_libraries {
            /path/liberty/standard_cells_${pvt_p}${pvt_v}v${pvt_t}c${pvt_rc}_ecsm_p.lib
        }
        -when ccs_libraries {
            /path/liberty/standard_cells_${pvt_p}${pvt_v}v${pvt_t}c${pvt_rc}_ccs.lib
        }
        -when ccs_p_libraries {
            /path/liberty/standard_cells_${pvt_p}${pvt_v}v${pvt_t}c${pvt_rc}_ccs_p.lib
        }
        -when lvf_libraries {
            /path/liberty/standard_cells_${pvt_p}${pvt_v}v${pvt_t}c${pvt_rc}_lvf.lib
        }
        -when ldb_libraries {
            /path/liberty/standard_cells_${pvt_p}${pvt_v}v${pvt_t}c${pvt_rc}_lvf.ldb
        }
        
        /path/liberty/macro_${pvt_p}${pvt_v}${pvt_t}.lib
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

    # # PGV files
    # gconfig::add_files pgv {
    #     /path/pgv/standard_cells_${pvt_p}_${pvt_rc}_${pvt_v}_${pvt_t}.cl
    # }

    # Block-specific SDC files
    <PLACEHOLDER>
    gconfig::add_files sdc -views {func * * * * *} {
        ../../../../scripts/func.sdc
    }
    # gconfig::add_files sdc -views {scan * * * * *} {
    #     ../../../../scripts/scan.sdc
    # }
    
    # # View-independent constraints
    # gconfig::add_files sdc {
    #     ../../../../scripts/design.sdc
    # }

    # # Clock uncertainty stored in separate SDC files
    # <PLACEHOLDER>
    # gconfig::add_files sdc -views {func tt * * * *} {
    #     ../../../../scripts/uncertainty.tt.sdc
    # }
    # gconfig::add_files sdc -views {func ss * * * *} {
    #     ../../../../scripts/uncertainty.ss.sdc
    # }
    # gconfig::add_files sdc -views {func ff * * * *} {
    #     ../../../../scripts/uncertainty.ff.sdc
    # }

    `@gconfig_cadence_mmmc_partitions_files -optional`
'

# Design-specific configuration (optional)
gf_create_step -name gconfig_settings_common '

    # # IO voltage variants to use in file name patterns
    # gconfig::add_section {
    #     -views {* ss 0p900v * * *} {$pvt_v {0p9v1p62v 0p9v1p62v1p62v}}
    #     -views {* tt 1p000v * * *} {$pvt_v {1v1p8v 1v1p8v1p8v}}
    #     -views {* ff 1p100v * * *} {$pvt_v {1p1v1p98v 1p1v1p98v1p98v}}
    # }

    # # Other design-specific variable variants to use in file name patterns
    # gconfig::add_section {
    #     -views {test * * * * *} {$mode test}
    #     -views {* tt * * * *} {$pvt_p {typ}}
    #     -views {* * 1p100v * * *} {$pvt_v {HV}}
    #     -views {* * * m40 * *} {$pvt_t {neg40}}
    #     -views {* ss * * * *} {$pvt_rc {max}}
    #     -views {* tt *  25 * *} {$pvt {typical}}
    #     -views {* * * *   cb *} {$qrc {cbest}}
    #     -views {* * * * * s} {$check {late}}
    # }
    
    # # Timing conditions for low power designs
    # gconfig::add_power_domain_timing_conditions {
    #     -views {func * 0p900v * * *} {
    #         PD1 {* * * * * *}
    #         PD2 {* * 0p810v * * *}
    #     }
    #     -views {func * 1p100v * * *} {
    #         PD1 {* * * * * *}
    #         PD2 {* * 0p990v * * *}
    #     }
    # }
'

################################################################################
# RTL files
################################################################################

# # Paths to locate relative RTL files (only when RTL files used without full path)
# <PLACEHOLDER>
# RTL_SEARCH_PATHS='
#     ../../../../../../data/hdl
#     ../../../../data/hdl
# '

# # RTL defines to apply
# <PLACEHOLDER>
# RTL_DEFINES='
#     SYNTHESIS
# '

# Option 1: List of system-verilog RTL files for synthesis
<PLACEHOLDER>
RTL_FILES='
    block_name.sv
'
# # Option 2: System-verilog RTL files list for synthesis
# RTL_FILES_LIST='/path/to/block.f'

################################################################################
# Design input files
################################################################################

# # Power intent file for low-power design (optional)
# CPF_FILE='../../../../data/DESIGN_NAME.*.cpf'
# UPF_FILE='../../../../data/DESIGN_NAME.*.upf'

################################################################################
# Genus input files
################################################################################

# # DEF floorplan for physical synthesis
# GENUS_FLOORPLAN_FILE='../../../../data/DESIGN_NAME.*.fp.def.gz'
# GENUS_FLOORPLAN_FILE='../../../innovus.fp.0000/out/Floorplan.*.fp.def.gz'

################################################################################
# Innovus input files
################################################################################

# Innovus scripts templates
INNOVUS_INIT_PORTS_SCRIPT='../../../../../template/scripts/init.ports.tcl'
INNOVUS_INIT_POWER_GRID_SCRIPT='../../../../../template/scripts/init.pg.default.tcl'
INNOVUS_ROUTE_FLIPCHIP_SCRIPT='../../../../../template/scripts/route.flipchip.tcl'

# # Innovus GDS map file and units in nm (mandatory for ./innovus.out.gf)
# <PLACEHOLDER>
# INNOVUS_GDS_LAYER_MAP_FILE='/PATH_TO_INNOVUS_STREAM_OUT.map'
# INNOVUS_GDS_UNITS=1000

# # Floorplan for implementation (optional, will be asked if empty)
# INNOVUS_FLOORPLAN_FILE='../../../../data/DESIGN_NAME.*.fp'
# INNOVUS_FLOORPLAN_FILE='../../../innovus.fp.0000/out/Floorplan.*.fp'

# # Netlist for implementation (optional, will be asked if empty)
# INNOVUS_NETLIST_FILES='../../../../data/DESIGN_NAME.*.v'
# INNOVUS_NETLIST_FILES='../../../genus.fe.0000/out/SynMap.v'
# INNOVUS_NETLIST_FILES='../../../genus.fe.0000/out/SynOpt.v'

# # Scan chains definition DEF file (required for DFT)
# INNOVUS_SCANDEF_FILE='../../../../data/DESIGN_NAME.*.scandef'

# # Design RC factors script
# INNOVUS_RC_FACTORS='../../../innovus.be.0000/out/Route.rc_factors.tcl'

# # Foundry legacy scripts (optional, if used in ./block.innovus.gf)
# INNOVUS_DFM_VIA_SWAP_SCRIPT='/path/to/the_script.tcl'

################################################################################
# Quantus input files
################################################################################

# # Quantus extraction files (optional, can be manually defined in ./block.quantus.gf)
# QUANTUS_DEF_LAYER_MAP_FILE='/PATH_TO/PRTF_Innovus_*/PR_tech/Cadence/QrcMap/PRTF_Innovus_*.map'
# QUANTUS_GDS_LAYER_MAP_FILE='/PATH_TO/PRTF_Innovus_*/PR_tech/Cadence/QrcDummyMap/PRTF_Innovus_*'

# # Dummy fill top cell name (required to enable parasitics extraction flow with dummy fill)
# <PLACEHOLDER>
# QUANTUS_DUMMY_TOP="${DESIGN_NAME}_dummy_fill"
#
# # Dummy fill GDS (optional, will be asked if empty)
# QUANTUS_DUMMY_GDS='../../../calibre.phys.000/out/Dummy*.gds.gz'
# QUANTUS_DUMMY_GDS='../../../pegasus.phys.000/out/Dummy*.gds.gz'
# QUANTUS_DUMMY_GDS='../../../pvs.phys.000/out/Dummy*.gds.gz'
# QUANTUS_DUMMY_GDS='../../../icv.phys.000/out/Dummy*.gds.gz'

################################################################################
# Signoff and tapeout files
################################################################################

# # Directory with design output data
# DATA_OUT_DIR='../../../innovus.out*/out/InnovusOut'

# # Directory with design SPEF files
# SPEF_OUT_DIR='../../../quantus.out*/out/QuantusOut'

################################################################################
# Voltus input files
################################################################################

# # Spice models for PGV generation (mandatory for detailed PGV)
# <PLACEHOLDER>
# VOLTUS_PGV_SPICE_MODELS='/PATH_TO/models/spectre/*.scs'
# VOLTUS_PGV_SPICE_CORNERS='ss'
# VOLTUS_PGV_SPICE_SCALING=0.9

# # Extracted spice files with coordinates for macro PGV generation (mandatory for detailed PGV)
# <PLACEHOLDER>
# VOLTUS_PGV_SPICE_FILES='
#     /PATH_TO_MACRO_FILE.spi
# '

# # Signal EM analysis rule file (mandatory for signal elecromigration analysis)
# <PLACEHOLDER>
# VOLTUS_EM_MODELS='/PATH_TO/VSTORM/EM.rules'
# VOLTUS_ICT_EM_MODELS='/PATH_TO/VOLTUS_EM_RULE.ictem'

# # Optional include files
# VOLTUS_STATIC_POWER_INCLUDE_FILE=/PATH/TO/static.include.cmd
# VOLTUS_DYNAMIC_POWER_INCLUDE_FILE=/PATH/TO/dynamic.include.cmd
# VOLTUS_EXTRACTOR_INCLUDE_FILE=/PATH/TO/extract.inc

# # PGV libraries for rail analysis (optional, will be asked if empty)
# <PLACEHOLDER>
# VOLTUS_PGV_LIBS='
#     ../../../../../voltus.pgv.0000/out/TechPGV/techonly.cl
#     ../../../../../voltus.pgv.0000/out/CellsPGV/stdcells.cl
#     ../../../../../voltus.pgv.0000/out/MacrosPGV/macros.cl
# '

# # Voltus power calculation include files (optional}
# VOLTUS_STATIC_POWER_INCLUDE_FILE=/PATH/TO/static.include.cmd
# VOLTUS_DYNAMIC_POWER_INCLUDE_FILE=/path/to/dynamic.include.cmd

################################################################################
# Calibre input files
################################################################################

# # Physical verification rules for Calibre (mandatory)
# <PLACEHOLDER>
# CALIBRE_DRC_RULES='/PATH_TO_DRC_RULE_FILE'
# CALIBRE_LVS_RULES='/PATH_TO_LVS_RULE_FILE'
# CALIBRE_FILL_RULES='/PATH_TO_COMBINED_FEOL_BEOL_FILL_RULE_FILE'
# CALIBRE_ANT_RULES='/PATH_TO_ANTENNA_RULE_FILE'
# CALIBRE_BUMP_RULES='/PATH_TO_BUMP_RULE_FILE'

# # Hierarchical cells file used for LVS (optional, auto-generated when empty)
# <PLACEHOLDER>
# HCELL_FILE='../../../../data/hcell'

################################################################################
# Hierarchical flow
################################################################################

# # LEF files (mandatory for synthesis and implementation)
# PARTITIONS_LEF_FILES='
#     ../../../../../partition/work_*/innovus.out.0000/out/InnovusOut/partition.lef
# '
# 
# # GDS files (mandatory for implementation)
# PARTITIONS_GDS_FILES='
#     ../../../../../partition/work_*/innovus.out.0000/out/InnovusOut/partition.gds.gs
# '
# 
# # CDL files (mandatory for hierarchical LVS)
# PARTITIONS_CDL_FILES='
#     ../../../../../partition/work_*/*.lvs.0000/out/LVS.sp
# '
# 
# # Cadence MMMC files
# gf_create_step -name gconfig_cadence_mmmc_partitions_files '
# 
#     # Partitions library files (mandatory for synthesis and implementation)
#     gconfig::add_files lib {
#         -when !assembled {
#             ../../../../../partition/work_*/tempus.out.0000/out/TempusOut/partition.${analysis_view_name}.lib
#         }
#     }
#     
#     # # Partitions SPEF files (hierarchical power and timing analysis)
#     # gconfig::add_files spef {
#     #     -when !assembled {
#     #         ../../../../../partition/work_*/quantus.out.0000/out/QuantusOut/partition.${extract_corner_name}.spef.gz
#     #     }
#     # }
# 
#     # # Partitions TWF files (hierarchical power analysis)
#     # gconfig::add_files twf {
#     #     -when !assembled {
#     #         ../../../../../partition/work_*/tempus.out.0000/out/TempusOut/partition.${analysis_view_name}.twf.gz
#     #     }
#     # }
# 
#     # # Partitions SDC files (flat timing analysis)
#     # gconfig::add_files sdc {
#     #     -when assembled {
#     #         ../../../../scripts/${constraint_mode_name}.partition.sdc
#     #     }
#     # }
# '
# 
# # # Partitions interface logic models (optional for implementation)
# # PARTITIONS_PRECTS_ILM_DIRECTORIES='
# #     ../../../../../partition/work_*/innovus.be.0000/out/Place/partition.prects.ilm
# #'
# # PARTITIONS_POSTCTS_ILM_DIRECTORIES='
# #     ../../../../../partition/work_*/innovus.be.0000/out/Clock/partition.postcts.ilm
# #'
# # PARTITIONS_POSTROUTE_ILM_DIRECTORIES='
# #     ../../../../../partition/work_*/innovus.be.0000/out/Route/partition.postroute.ilm
# #'
# 
# # # Partitions databases to assemble after route (assemble design for flat timing and power analysis)
# # PARTITIONS_INNOVUS_DATABASES='
# #     ../../../../../partition/work_*/innovus.be.0000/out/Route.innovus.db
# #'
# 
# # # Partitions netlist files (hierarchical power and timing analysis)
# # PARTITIONS_NETLIST_FILES='
# #     ../../../../../partition/work_*/innovus.out.0000/out/InnovusOut/partition.v.gz
# # '
# #
# # # Partitions DEF files (hierarchical power and timing analysis)
# # PARTITIONS_DEF_FILES='
# #     ../../../../../partition/work_*/innovus.out.0000/out/InnovusOut/partition.pg.def.gz
# # '
