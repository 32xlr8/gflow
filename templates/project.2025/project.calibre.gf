################################################################################
# Generic Flow v5.5.4 (December 2025)
################################################################################
#
# Copyright 2011-2025 Gennady Kirpichev
#
#    https://github.com/32xlr8/gflow.git
#    https://gitflic.ru/project/32xlr8/gflow
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
# Filename: templates/project.2025/project.calibre.gf
# Purpose:  Project-specific Calibre configuration and flow steps
################################################################################

# Load tool plugin, tool and technology steps to use in GF scripts
gf_source -once "../../tools/gflow_plugin.calibre.gf"
gf_source -once "../../tools/tool_steps.calibre.gf"

gf_info "Loading project-specific Calibre settings ..."

# Tool initialization in Linux environment
gf_create_step -name init_calibre_environment '
    <PLACEHOLDER>
    export MGC_HOME=/PATH_TO_AOI_CAL
    export PATH=$MGC_HOME/bin:$PATH
    export MGLS_LICENSE_FILES=29700@$HOSTNAME
    export MGC_DISABLE_BACKING_STORE=true
    export USE_CALIBRE_VCO=aoi
'
