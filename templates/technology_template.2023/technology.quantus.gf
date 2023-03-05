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
# Filename: templates/technology_template.2023/technology.quantus.gf
# Purpose:  Quantus steps to use in the Generic Flow
################################################################################

gf_info "Loading technology-specific Quantus steps ..."

# Technology-specific tool environment
gf_create_step -name quantus_technology_settings '

    # Cross-coupling mode required for SI
    extract \
        -selection all \
        -type rc_coupled

    # Filtering options
    filter_coupling_cap \
        -total_cap_threshold 0.0 \
        -coupling_cap_threshold_absolute 0.1 \
        -coupling_cap_threshold_relative 1.0 \
        -cap_filtering_mode absolute_and_relative

    # Parasitics reduction
    parasitic_reduction -enable_reduction false
    
    # Process scale factor
    extraction_setup \
        -layout_scale <PLACEHOLDER:1.0>

    extraction_setup \
        -promote_pin_pad logical
'
