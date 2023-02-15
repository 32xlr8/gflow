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
# Filename: templates/technology_template.cadence.2022/technology.innovus.gf
# Purpose:  Technology-specific Innovus steps to use in the Generic Flow
################################################################################

gf_info "Loading technology-specific Innovus steps ..."

# Basic technology settings needed for floorplan
gf_create_step -name innovus_post_init_design_physical_mode_technology '

    # Process related settings
    set_db design_process_node <PLACEHOLDER>
    # set_db design_tech_node <PLACEHOLDER>
    set_db route_design_process_node <PLACEHOLDER>
'
