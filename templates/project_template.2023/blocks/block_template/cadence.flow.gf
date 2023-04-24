#!../../gflow/bin/gflow

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
# Filename: templates/project_template.2023/blocks/block_template/cadence.flow.gf
# Purpose:  Batch synthesis flow
################################################################################

########################################
# Settings
########################################

# Project and block initialization scripts
gf_source "../../project.common.gf"
gf_source "../../project.genus.gf"
# gf_source "../../project.modus.gf"
gf_source "../../project.innovus.gf"
gf_source "../../project.quantus.gf"
gf_source "../../project.tempus.gf"
gf_source "../../project.voltus.gf"
gf_source "./block.common.gf"
gf_source "./block.genus.gf"
# gf_source "./block.modus.gf"
gf_source "./block.innovus.gf"
gf_source "./block.quantus.gf"
gf_source "./block.tempus.gf"
gf_source "./block.voltus.gf"

########################################
# Flows
########################################

# Genus - synthesis
gf_choose -keep -variable IS_RUN_FE -keys YN -prompt "Run Genus synthesis (Y/N)?"
if [ "$IS_RUN_FE" == "Y" ]; then
    gf_source "./genus.fe.gf"
    gf_get_task_dir SynOpt -variable INNOVUS_NETLIST_FILES
fi

# Innovus - implementation
gf_choose -keep -variable IS_RUN_BE -keys YN -prompt "Run Innovus implementation (Y/N)?"
if [ "$IS_RUN_BE" == "Y" ]; then
    gf_source "./innovus.be.gf"
    gf_get_task_dir Route -variable INNOVUS_DATABASE
fi

# Innovus - data out
if [ "$IS_RUN_BE" == "Y" ]; then
    gf_source "./innovus.out.gf"
    gf_get_task_dir DataOutPhysical -variable DATA_OUT_DIR
fi

# Quantus - parasistics extraction
gf_source "./quantus.ext.gf"
gf_get_task_dir Extraction -variable SPEF_OUT_DIR

# Tempus - static timing analysis
gf_choose -keep -variable IS_RUN_TIMING -keys YN -prompt "Run Tempus timing analysis (Y/N)?"
if [ "$IS_RUN_TIMING" == "Y" ]; then
    gf_source "./tempus.sta.gf"
    gf_get_task_dir STA -variable ECO_DB_DIR
fi

# Voltus - power and rail analysis
gf_choose -keep -variable IS_RUN_POWER -keys YN -prompt "Run Voltus power analysis (Y/N)?"
if [ "$IS_RUN_POWER" == "Y" ]; then
    gf_source "./voltus.rail.gf"
fi
