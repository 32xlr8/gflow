#!../../gflow/bin/gflow

################################################################################
# Generic Flow v5.5.4 (December 2025)
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
# Filename: templates/project.2025/blocks/template/flow.gf
# Purpose:  Synthesis, implementation and signoff flow
################################################################################

########################################
# Settings
########################################

# Project and block initialization scripts
gf_source -once "../../project.common.gf"

########################################
# Generic Flow history
########################################

gf_create_task -name History
gf_set_task_command "../../../../../../tools/print_flow_history.pl ../../../../work_*/*/ -html ./reports/$TASK_NAME.html"
gf_submit_task -silent
