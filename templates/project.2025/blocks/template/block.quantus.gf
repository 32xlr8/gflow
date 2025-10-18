################################################################################
# Generic Flow v5.5.3 (October 2025)
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
# Filename: templates/project.2025/blocks/template/block.quantus.gf
# Purpose:  Block-specific Quantus configuration and flow steps
################################################################################

gf_info "Loading block-specific Quantus steps ..."

################################################################################
# Flow options
################################################################################

# # Override all tasks resources
# gf_set_task_options -cpu 8 -mem 15

# # Override resources for batch tasks
# gf_set_task_options QuantusOut -cpu 8 -mem 15
# gf_set_task_options 'QuantusOut_*' -cpu 4 -mem 15

# # Limit simultaneous tasks count
# gf_set_task_options QuantusOut -group Heavy -parallel 1
gf_set_task_options 'QuantusOut_*' -group QuantusOut -parallel 8

# Spread parallel tasks in time
QUANTUS_WAIT_TIME_STEP=60

################################################################################
# Flow variables
################################################################################

# # Extraction with dummy GDS
# USE_DUMMY_GDS=Y
# USE_DUMMY_GDS=N

################################################################################
# Flow steps
################################################################################

# Corner configuration
gf_create_step -name quantus_gconfig_design_settings '
    <PLACEHOLDER> Review signoff settings for parasitics extraction

    # Choose analysis view patterns:
    # - {mode process voltage temperature rc_corner timing_check}
    set RC_CORNERS [regsub -all -line {^\s*\#.*\n} {
        {* * * 85 ct *}
        
        {* * * m40 cwt *} 
        {* * * m40 rcwt *} 
        
        {* * * 125 cwt *}
        {* * * 125 rcwt *} 

        {* * * m40 cb *} 
        {* * * m40 cw *} 
        {* * * m40 rcb *} 
        {* * * m40 rcw *} 
        
        {* * * 125 cb *} 
        {* * * 125 cw *} 
        {* * * 125 rcb *} 
        {* * * 125 rcw *} 

        {* * * 0 cb *} 
        {* * * 0 cw *} 
        {* * * 0 rcb *} 
        {* * * 0 rcw *}
    } {}]
'

# CCL Commands before design initialized
gf_create_step -name quantus_pre_init_design '

    # Choose one of option 1.*  and 2.*

    # Option 1.1: LEF to QRC layer mapping file (./block.common.gf)
    include "`$QUANTUS_DEF_LAYER_MAP_FILE -optional`"
    
    # # Option 1.2: LEF to QRC manual layer mapping
    # extraction_setup -technology_layer_map \
    #     PO poly \
    #     NWELL none \
    #     PWELL none \
    #     VTH_P none \
    #     VTL_P none \
    #     VTUL_P none \
    #     CO polyCont \
    #     M1 metal1 \
    #     M2 metal2 \
    #     <PLACEHOLDER>LEF_layer QRC_layer \
    #     AP metal9 \
    #     VIA1 VIA1 \
    #     <PLACEHOLDER>LEF_layer QRC_layer \
    #     RV VIA8

    # Option 2.1.1/2.2.1: LEF to GDS layer and metal fill mapping file (./block.common.gf)
    extraction_setup -stream_layer_map_file "`$QUANTUS_GDS_LAYER_MAP_FILE -optional`"
    
    # # Option 2.1.2: LEF to GDS manual layer mapping without DPT layers
    # extraction_setup -gds_layer_map \
    #     <PLACEHOLDER>LEF_layer GDS_layer_num GDS_data_type \
    #     PO    17  0  \
    #     CO    30  0  \
    #     M1    31  0  \
    #     VIA1  51  0  \
    #     RV    85  0  \
    #     AP    74  0
    #
    # # Option 2.1.3: LEF to GDS manual layer mapping with DPT layers
    # extraction_setup -gds_layer_map_by_color \
    #     - M0 180 250 \
    #     1 M0 180 255 \
    #     2 M0 180 256 \
    #     <PLACEHOLDER>mask LEF_layer GDS_layer_num GDS_data_type \
    #     - AP 74 0 \
    #     - VIA0 159 250 \
    #     - VIA1 51 250 \
    #     1 VIA1 51 255 \
    #     2 VIA1 51 256 \
    #     <PLACEHOLDER>mask LEF_layer GDS_layer_num GDS_data_type \
    #     - RV 85 0
    #
    # # Option 2.2.2: LEF to GDS metal fill manual layer mapping without DPT layers
    # extraction_setup -gds_fill_layer_map \
    #     OD 6 1 \
    #     OD 6 7 \
    #     PO 17 1 \
    #     PO 17 7 \
    #     PO 17 11 \
    #     PO 17 12 \
    #     M1 31 1 \
    #     M1 31 7 \
    #     M1 31 209 \
    #     M2 32 1 \
    #     M2 32 7 \
    #     M2 32 209 \
    #     M3 33 1 \
    #     M3 33 7 \
    #     M4 34 1 \
    #     M4 34 7 \
    #     <PLACEHOLDER>LEF_layer GDS_layer_num GDS_data_type \
    #     VIA1 51 1 \
    #     VIA2 52 1 \
    #     VIA3 53 1 \
    #    <PLACEHOLDER>LEF_layer GDS_layer_num GDS_data_type
    #  
    # # Option 2.2.3: LEF to GDS metal fill manual layer mapping with DPT layers
    # extraction_setup -gds_fill_layer_map_by_color \
    #     - OD 6 1 \
    #     - OD 6 7 \
    #     - OD 6 21 \
    #     - OD 6 22 \
    #     - OD 6 25 \
    #     - COD_H 6 26 \
    #     - COD_V 6 27 \
    #     - COD_BLOCK 6 28 \
    #     - PO 17 1 \
    #     - PO 17 7 \
    #     - PO 17 8 \
    #     - CPO 17 23 \
    #     - M1 31 2 \
    #     - M1 31 3 \
    #     1 M2 32 72 \
    #     2 M2 32 73 \
    #     1 M3 33 72 \
    #     2 M3 33 73 \
    #     - M4 34 151 \
    #     - M4 34 157 \
    #     <PLACEHOLDER>mask LEF_layer GDS_layer_num GDS_data_type \
    #     - VIA1 51 71 \
    #     <PLACEHOLDER>mask LEF_layer GDS_layer_num GDS_data_type
'
