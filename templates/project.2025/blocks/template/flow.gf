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
gf_source -once "../../project.genus.gf"
# gf_source -once "../../project.modus.gf"
gf_source -once "../../project.innovus.gf"
gf_source -once "../../project.calibre.gf"
gf_source -once "../../project.quantus.gf"
gf_source -once "../../project.tempus.gf"
gf_source -once "../../project.voltus.gf"
gf_source -once "./block.common.gf"
gf_source -once "./block.genus.gf"
# gf_source -once "./block.modus.gf"
gf_source -once "./block.innovus.gf"
gf_source -once "./block.calibre.gf"
gf_source -once "./block.quantus.gf"
gf_source -once "./block.tempus.gf"
gf_source -once "./block.voltus.gf"

# # Chose scenarios
# GENUS_FE=Y
# INNOVUS_BE=Y
# INNOVUS_OUT=Y
# QUANTUS_OUT=Y
# CALIBRE_DUMMY=Y
# CALIBRE_DRC=Y
# CALIBRE_LVS=Y
# TEMPUS_STA=Y
# TEMPUS_TSO=N
# VOLTUS_STATIC=Y
# VOLTUS_DYNAMIC=Y

########################################
# Flows
########################################

# Genus - synthesis
gf_choose -keep -variable GENUS_FE -keys YN -prompt "Run Genus synthesis (Y/N)?"
if [ "$GENUS_FE" == "Y" ]; then
    gf_source "../template/genus.fe.gf"
    gf_get_task_dir SynOpt -variable INNOVUS_NETLIST_FILES
fi

# Innovus - implementation
gf_choose -keep -variable INNOVUS_BE -keys YN -prompt "Run Innovus implementation (Y/N)?"
if [ "$INNOVUS_BE" == "Y" ]; then
    gf_source "../template/innovus.be.gf"
    gf_get_task_dir Route -variable INNOVUS_DATABASE
fi

# Innovus - data out
gf_choose -keep -variable INNOVUS_OUT -keys YN -prompt "Run Innovus data out (Y/N)?"
if [ "$INNOVUS_OUT" == "Y" ]; then
    gf_source "../template/innovus.out.gf"
    gf_get_task_dir InnovusOut -variable DATA_OUT_DIR
    gf_get_task_dir InnovusOut -variable GDS_OUT_FILE
fi

# Calibre Fill
gf_choose -keep -variable CALIBRE_DUMMY -keys YN -prompt "Run Calibre dummy fill (Y/N)?"
if [ "$CALIBRE_DUMMY" == "Y" ]; then
    gf_source "../template/calibre.dummy.gf"
    gf_get_task_dir Dummy -variable QUANTUS_DUMMY_GDS
    gf_get_task_dir Merge -variable GDS_OUT_FILE
fi

# Calibre DRC
gf_choose -keep -variable CALIBRE_DRC -keys YN -prompt "Run Calibre DRC (Y/N)?"
if [ "$CALIBRE_DRC" == "Y" ]; then
    gf_source "../template/calibre.drc.gf"
fi

# Calibre LVS
gf_choose -keep -variable CALIBRE_LVS -keys YN -prompt "Run Calibre LVS (Y/N)?"
if [ "$CALIBRE_LVS" == "Y" ]; then
    gf_source "../template/calibre.lvs.gf"
fi

# Quantus - parasistics extraction
gf_choose -keep -variable QUANTUS_OUT -keys YN -prompt "Run Quantus extraction (Y/N)?"
if [ "$QUANTUS_OUT" == "Y" ]; then
    gf_source "../template/quantus.out.gf"
    gf_get_task_dir QuantusOut -variable SPEF_OUT_DIR
fi

# Tempus - static timing analysis
gf_choose -keep -variable TEMPUS_STA -keys YN -prompt "Run Tempus timing analysis (Y/N)?"
if [ "$TEMPUS_STA" == "Y" ]; then
    gf_source "../template/tempus.sta.gf"
    gf_get_task_dir STA -variable ECO_DB_DIR
fi

# Tempus - ECO
gf_choose -keep -variable TEMPUS_TSO -keys YN -prompt "Run Tempus ECO (Y/N)?"
if [ "$TEMPUS_TSO" == "Y" ]; then
    gf_source "../template/tempus.tso.gf"
    gf_get_task_dir TSO -variable ECO_SCRIPT
    gf_source "../template/innovus.tso.gf"
    gf_get_task_dir ECO -variable INNOVUS_DATABASE
fi

# Voltus - static power and rail analysis
gf_choose -keep -variable VOLTUS_STATIC -keys YN -prompt "Run Voltus static analysis (Y/N)?"
if [ "$VOLTUS_STATIC" == "Y" ]; then
    gf_source "../template/voltus.static.gf"
fi

# Voltus - dynamic power and rail analysis
gf_choose -keep -variable VOLTUS_DYNAMIC -keys YN -prompt "Run Voltus dynamic analysis (Y/N)?"
if [ "$VOLTUS_DYNAMIC" == "Y" ]; then
    gf_source "../template/voltus.dynamic.gf"
fi
