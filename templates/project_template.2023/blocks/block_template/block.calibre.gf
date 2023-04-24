################################################################################
# Generic Flow v5.1 (May 2023)
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
# Filename: templates/project_template.2023/blocks/block_template/block.calibre.gf
# Purpose:  Block-specific Calibre configuration and flow steps
################################################################################

# Tasks to run
gf_set_task_options -disable *
gf_set_task_options -enable Fill*
# gf_set_task_options -enable Bumps*
# gf_set_task_options -enable Antenna*
gf_set_task_options -enable DRC*
gf_set_task_options -enable LVS*

################################################################################
# Flow variables
################################################################################

# # Nets to connect virtually during LVS
# LVS_VIRTUAL_NET_CONNECT="<PLACEHOLDER>POC VDD VSS VSSPST VDDPST AVDD AVSS"

# Sed commands to replace LEF metal layer names with GDS text layer numbers 
MAP_PORT_NAMES_SED_SCRIPT='
    s| M\([123456789]\) | 13\1 |
    s| M1\([0123456789]\) | 14\1 |
    s| AP | 126 |
'

################################################################################
# Additional files content
################################################################################

# Additional port labels for LVS
gf_create_step -name lvs_user_port_labels '
    # LAYOUT TEXT "POC" 0.0 0.0 M5 `$DESIGN_NAME`
    # LAYOUT TEXT "ESD" 0.0 0.0 M5 `$DESIGN_NAME`
    # LAYOUT TEXT "RTE" 0.0 0.0 M5 `$DESIGN_NAME`
'
