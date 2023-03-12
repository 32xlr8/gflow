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
# Filename: templates/project_template.2023/blocks/block_template/block.voltus.gf
# Purpose:  Block-specific Voltus configuration and flow steps
################################################################################

gf_info "Loading block-specific Voltus steps ..."

# Mandatory tasks
gf_set_task_options -enable Init Extraction

# PGV generation tasks to run
gf_set_task_options -enable TechPGV
# gf_set_task_options -enable CellsPGV
# gf_set_task_options -enable MacrosPGV

# Power analysis tasks to run
gf_set_task_options -enable Static*
# gf_set_task_options -enable Dynamic*
# gf_set_task_options -enable Signal*

################################################################################
# Flow variables
################################################################################

# # Reuse already generated PGV libraries
# PGV_LIBS="
#     <PLACEHOLDER>../../../../../block_name/work_*/voltus.pgv.0000/out/TechPGV.cl
#     <PLACEHOLDER>../../../../../block_name/work_*/voltus.pgv.0000/out/CellsPGV.cl
#     <PLACEHOLDER>../../../../../block_name/work_*/voltus.pgv.0000/out/MacrosPGV.cl
# "

# Static and dynamic power analysis scenarios
POWER_SCENARIOS='
    Switching activity 0.2
    Switching activity 0.4
    VCD: Default mode
'

# # Select scenario automatically
# POWER_SCENARIO="Switching activity 0.4"

# Global nets
POWER_NETS_VOLTUS='`$POWER_NETS_CORE`'
GROUND_NETS_VOLTUS='`$GROUND_NETS_CORE`'

# # Filler and decap cells for PGV
# VOLTUS_PGV_FILLER_CELLS='
#     <PLACEHOLDER>CELL_NAME
# '
# VOLTUS_PGV_DECAP_CELLS='
#     <PLACEHOLDER>CELL_NAME
# '

################################################################################
# Flow steps
################################################################################

# Commands before generating tech-only PGV models
gf_create_step -name voltus_pre_write_pgv_tech_only '

    # Tech only PGV settings
    set_pg_library_mode -cell_type techonly -extraction_tech_file [gconfig::get_files qrc -view $POWER_VIEW] -lef_layer_map ./scripts/$TASK_NAME.lef.map
'

# Commands before generating PGV models for standard cells
gf_create_step -name voltus_pre_write_pgv_standard_cells '

    # Standard cells PGV settings
    set_pg_library_mode -cell_type techonly
    set_pg_library_mode -extraction_tech_file [gconfig::get_files qrc -view $POWER_VIEW]
    set_pg_library_mode -cell_dcap_file ./scripts/$TASK_NAME.dcap

    # set_pg_library_mode -cell_list_file ./scripts/$TASK_NAME.cells
        
    set_pg_library_mode \
        -spice_subckts [join {
            <PLACEHOLDER>*.spi
        }] \
        -spice_models <PLACEHOLDER>*.scs \
        -spice_corners {{<PLACEHOLDER>ss}}
        
    set_pg_library_mode \
        -filler_cells [join $FILLER_CELLS] \
        -decap_cells [join $DECAP_CELLS] \
        -power_pins {<PLACEHOLDER>VDD 0.9 TVDD 0.9} \
        -ground_pins {<PLACEHOLDER>VSS 0} \
        -cell_list_file ../../../voltus/cell_std_all.list \
        -cell_decap_file ../../../voltus/decap.cmd \
        -current_distribution propagation \
        -powergate_parameters {{RING_SWITCH TVDD VDD {} {} {}}}
'

# Commands before generating PGV models for macros
gf_create_step -name voltus_pre_write_pgv_macros '

    # Macros PGV settings
    set_pg_library_mode -cell_type macros -extraction_tech_file [gconfig::get_files qrc -view $POWER_VIEW] \
        -stream_files $GDS_FILES -stream_layer_map ./scripts/$TASK_NAME.connect.map \
        -cells_file ./scripts/$TASK_NAME.cells \
        -spice_subckts [join $SPICE_FILES] \
        -spice_subckts_xy_scaling $SPICE_SCALING \
        -spice_models [join $SPICE_MODELS] \
        -spice_corners $SPICE_CORNERS \

'

# Commands before performing static power analysis
gf_create_step -name voltus_pre_report_power_static '
    set_db power_method static
    set_db power_write_static_currents true
    set_db power_ignore_control_signals false
    set_db power_read_rcdb true

    # Default activity analysis
    if {$POWER_SCENARIO == "Switching activity 0.2"} {
        set_default_switching_activity -input_activity 0.2
        set_default_switching_activity -sequential_activity 0.2
        set_default_switching_activity -clock_gates_output 2

    } elseif {$POWER_SCENARIO == "Switching activity 0.4"} {
        set_default_switching_activity -input_activity 0.4
        set_default_switching_activity -sequential_activity 0.4
        set_default_switching_activity -clock_gates_output 2

    # VCD-based analysis
    } elseif {$POWER_SCENARIO == "VCD: Default mode"} {
        read_activity_file <PLACEHOLDER>/PATH_TO/ACTIVITY_FILE.vcd -format <PLACEHOLDER>VCD \
            -scope <PLACEHOLDER>/design_instance/scope/in/vcd \
            -start <PLACEHOLDER>10ns -end <PLACEHOLDER>20ns
        set_db power_scale_to_sdc_clock_frequency true
        
    # Unknown scenario
    } else {
        error "Incorrect scenario: $POWER_SCENARIO"
    }

'

# Commands before performing dynamic power analysis
gf_create_step -name voltus_pre_report_power_dynamic '
    set_db power_write_static_currents true
    set_db power_honor_negative_energy true
    set_db power_ignore_control_signals false
    set_db power_read_rcdb true
    set_db power_disable_static false

    # Default activity analysis
    if {$POWER_SCENARIO == "Switching activity 0.2"} {
        set_default_switching_activity -input_activity 0.2
        set_default_switching_activity -sequential_activity 0.2
        set_default_switching_activity -clock_gates_output 2
        set_db power_method dynamic_vectorless
        set_dynamic_power_simulation -resolution 10ps -period 10ns

    } elseif {$POWER_SCENARIO == "Switching activity 0.4"} {
        set_default_switching_activity -input_activity 0.4
        set_default_switching_activity -sequential_activity 0.4
        set_default_switching_activity -clock_gates_output 2
        set_db power_method dynamic_vectorless
        set_dynamic_power_simulation -resolution 10ps -period 10ns

    # VCD-based analysis
    } elseif {$POWER_SCENARIO == "VCD: Default mode"} {
        read_activity_file <PLACEHOLDER>/PATH_TO/ACTIVITY_FILE.vcd -format <PLACEHOLDER>VCD \
            -scope <PLACEHOLDER>/design_instance/scope/in/vcd \
            -start <PLACEHOLDER>10ns -end <PLACEHOLDER>20ns
        set_db power_method dynamic_vectorbased
        set_dynamic_power_simulation -resolution <PLACEHOLDER>10ps

    # Unknown scenario
    } else {
        error "Incorrect scenario: $POWER_SCENARIO"
    }
'

gf_create_step -name init_static_rail_voltus '
    set_rail_analysis_mode \
        -extraction_tech_file $QRC_TECH_FILE \
        -accuracy hd -method static -ignore_shorts true \
        -temperature <PLACEHOLDER>125 \
        -power_grid_libraries $PGV_LIBS \
        -ict_em_models $VOLTUS_ICT_EM_RULE
   
    set_pg_net -net <PLACEHOLDER>VDD -voltage <PLACEHOLDER>0.900 -threshold <PLACEHOLDER>0.892
    set_pg_net -net <PLACEHOLDER>VSS -voltage 0.0 -threshold <PLACEHOLDER>0.008

    set_power_pads -format xy -net <PLACEHOLDER>VDD -file ./out/$MOTHER_TASK_NAME.VDD.pp
    set_power_pads -format xy -net <PLACEHOLDER>VSS -file ./out/$MOTHER_TASK_NAME.VSS.pp
'

gf_create_step -name init_dynamic_rail_voltus '
    set_rail_analysis_mode \
        -extraction_tech_file $QRC_TECH_FILE \
        -accuracy hd -method dynamic -ignore_shorts true -limit_number_of_steps false \
        -temperature 125 \
        -power_grid_libraries $PGV_LIBS
   
    # -write_movies true
    
    set_pg_net -net <PLACEHOLDER>VDD -voltage <PLACEHOLDER>0.900 -threshold <PLACEHOLDER>0.892
    set_pg_net -net <PLACEHOLDER>VSS -voltage 0.0 -threshold <PLACEHOLDER>0.008

    set_power_pads -format xy -net <PLACEHOLDER>VDD -file ./out/$MOTHER_TASK_NAME.VDD.pp
    set_power_pads -format xy -net <PLACEHOLDER>VSS -file ./out/$MOTHER_TASK_NAME.VSS.pp
'

gf_create_step -name run_signal_em_voltus '
    set_default_switching_activity -input_activity <PLACEHOLDER>0.2
    set_default_switching_activity -sequential_activity <PLACEHOLDER>0.2
    set_default_switching_activity -clock_gates_output <PLACEHOLDER>2
    check_ac_limits -method peak -ict_em_models $VOLTUS_ICT_EM_RULE
'

################################################################################
# Additional files content
################################################################################

# LEF to DEF layer map file
gf_create_step -name lef_def_map_file '
    metal  M1    lefdef   M1
    via    VIA1  lefdef   VIA1
    # <PLACEHOLDER>layer_type LEF_layer_name lefdef DEF_layer_name
    via    RV    lefdef   RV
    metal  AP    lefdef   AP
'

# GDS layer mapping for PGV connectivity
gf_create_step -name pgv_layer_connect_file '
    <PLACEHOLDER>via LEF_layer_name GDS_layer_num GDS_data_type \
    <PLACEHOLDER>metal LEF_layer_name GDS_layer_num GDS_data_type \
    via          RV      gds  85  0  
    metal        AP      gds  74  0  
'

# Standard cells PGV generation cell list file
gf_create_step -name pgv_standard_cell_list_file '
    <PLACEHOLDER>INVX1
    <PLACEHOLDER>ANDX1
'

# Standard cells PGV generation decap file
gf_create_step -name pgv_standard_cell_decap_file '
    <PLACEHOLDER>DCAP 10pF 
'

# Macro PGV generation cell list file
gf_create_step -name pgv_macro_list_file '
    <PLACEHOLDER>RAM1
'
