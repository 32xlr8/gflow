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
# Filename: templates/project_template.2023/project.calibre.gf
# Purpose:  Project-specific Calibre configuration and flow steps
################################################################################

# Load tool plugin, tool and technology steps to use in GF scripts
gf_source -once "../../tools/gflow_plugin.calibre.gf"
gf_source -once "../../tools/tool_steps.calibre.gf"

gf_info "Loading project-specific Calibre settings ..."

# Tool initialization in Linux environment
gf_create_step -name init_calibre_environment '
    export MGC_HOME=<PLACEHOLDER>/PATH_TO_AOI_CAL
    export PATH=$MGC_HOME/bin:$PATH
    export MGLS_LICENSE_FILES=<PLACEHOLDER>29700@$HOSTNAME
    export MGC_DISABLE_BACKING_STORE=true
    export USE_CALIBRE_VCO=aoi
'
