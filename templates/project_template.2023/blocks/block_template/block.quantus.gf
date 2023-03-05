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
# Filename: templates/project_template.2023/blocks/block_template/block.quantus.gf
# Purpose:  Block-specific Quantus configuration and flow steps
################################################################################

gf_info "Loading block-specific Quantus steps ..."

################################################################################
# Flow steps
################################################################################

# Project-specific tool environment
gf_create_step -name quantus_project_settings '

    # LEF to QRC layer mapping
    extraction_setup -technology_layer_map \
        PO poly \
        NWELL none \
        PWELL none \
        VTH_P none \
        VTL_P none \
        VTUL_P none \
        CO polyCont \
        M1 metal1 \
        M2 metal2 \
        <PLACEHOLDER:LEF_layer QRC_layer> \
        AP metal9 \
        VIA1 VIA1 \
        <PLACEHOLDER:LEF_layer QRC_layer> \
        RV VIA8

    # # LEF to GDS layer mapping
    # extraction_setup -gds_layer_map \
       # <PLACEHOLDER:LEF_layer GDS_layer_num GDS_data_type> \
       # PO    17  0  \
       # CO    30  0  \
       # M1    31  0  \
       # VIA1  51  0  \
       # RV    85  0  \
       # AP    74  0
    # # LEF to GDS layer mapping
    #extraction_setup -gds_layer_map_by_color \
       # - M0 180 250 \
       # 1 M0 180 255 \
       # 2 M0 180 256 \
       # <PLACEHOLDER:mask LEF_layer GDS_layer_num GDS_data_type> \
       # - AP 74 0 \
       # - VIA0 159 250 \
       # - VIA1 51 250 \
       # 1 VIA1 51 255 \
       # 2 VIA1 51 256 \
       # <PLACEHOLDER:mask LEF_layer GDS_layer_num GDS_data_type> \
       - RV 85 0

    # # LEF to GDS metal fill layer mapping
    # extraction_setup -gds_fill_layer_map \
       # OD 6 1 \
       # OD 6 7 \
       # PO 17 1 \
       # PO 17 7 \
       # PO 17 11 \
       # PO 17 12 \
       # M1 31 1 \
       # M1 31 7 \
       # M1 31 209 \
       # M2 32 1 \
       # M2 32 7 \
       # M2 32 209 \
       # M3 33 1 \
       # M3 33 7 \
       # M4 34 1 \
       # M4 34 7 \
       # <PLACEHOLDER:LEF_layer GDS_layer_num GDS_data_type> \
       # VIA1 51 1 \
       # VIA2 52 1 \
       # VIA3 53 1 \
       # <PLACEHOLDER:LEF_layer GDS_layer_num GDS_data_type>
    # # LEF to GDS metal fill layer mapping
    # extraction_setup -gds_fill_layer_map_by_color \
       # - OD 6 1 \
       # - OD 6 7 \
       # - OD 6 21 \
       # - OD 6 22 \
       # - OD 6 25 \
       # - COD_H 6 26 \
       # - COD_V 6 27 \
       # - COD_BLOCK 6 28 \
       # - PO 17 1 \
       # - PO 17 7 \
       # - PO 17 8 \
       # - CPO 17 23 \
       # - M1 31 2 \
       # - M1 31 3 \
       # 1 M2 32 72 \
       # 2 M2 32 73 \
       # 1 M3 33 72 \
       # 2 M3 33 73 \
       # - M4 34 151 \
       # - M4 34 157 \
       # <PLACEHOLDER:mask LEF_layer GDS_layer_num GDS_data_type> \
       # - VIA1 51 71 \
       # <PLACEHOLDER:mask LEF_layer GDS_layer_num GDS_data_type>
'
