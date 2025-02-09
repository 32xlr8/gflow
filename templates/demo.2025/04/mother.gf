#!../../../bin/gflow

################################################################################
# Generic Flow v5.5.1 (February 2025)
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
# Filename: templates/demo.2025/04/mother.gf
# Purpose:  Simple task dependency
################################################################################

# Mother task
gf_create_task -name Mother
gf_set_task_command 'tree ../..; read'
gf_submit_task

# Daughter task
gf_create_task -name Daughter -mother Mother
gf_set_task_command "echo '$MOTHER_TASK_NAME => $TASK_NAME'; read"
gf_submit_task
