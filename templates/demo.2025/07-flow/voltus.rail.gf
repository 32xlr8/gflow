#!../../../bin/gflow

# Voltus Power/Rail sub-flow

##################################################
# Data out
##################################################
gf_create_task -name Init

# Select Innovus database to analyze from latest available if $DATABASE is empty
echo
gf_choose_file_dir_task -variable DATABASE -prompt "Please select database or active task:" -keep -files "
    */out/PostR*.innovus.db
    */out/ECO*.innovus.db
" -active -tasks "
    */tasks/PostR*
    */tasks/ECO*
"

# Auto-populate database for task
if [ -e "$DATABASE/run" ]; then
    gf_want_task -exact $DATABASE
    DATABASE="$DATABASE/out/$(basename "$DATABASE").innovus.db"
fi

gf_info "Innovus database \e[32m$DATABASE\e[0m selected"

# Tool commands
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l $DATABASE
    ln -vnsf $DATABASE ./in/$TASK_NAME.innovus.db
    read
    touch ./out/$TASK_NAME.v.gz
    touch ./out/$TASK_NAME.def.gz
"
gf_submit_task

##################################################
# Quantus extraction
##################################################
gf_create_task -name Extraction -mother Init

gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$MOTHER_TASK_NAME.def.gz
    read
    touch ./out/$TASK_NAME.spef.gz
"
gf_submit_task

##################################################
# Static power
##################################################
gf_create_task -name StaticPower

# Select scenario to calculate power
gf_choose -variable POWER_SCENARIO -message "Which power scenario to run?" -variants "
Switching activity 0.2
Switching activity 0.4
VCD: Default mode
"

gf_want_task -variable INIT_TASK_NAME Init
gf_want_task -variable EXTRACTION_TASK_NAME Extraction
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$INIT_TASK_NAME.v.gz
    ls -l ./out/$INIT_TASK_NAME.def.gz
    ls -l ./out/$EXTRACTION_TASK_NAME.spef.gz
    echo $POWER_SCENARIO
    read
    touch ./out/$TASK_NAME.power.db
"
gf_submit_task

##################################################
# Static rail analysis
##################################################
gf_create_task -name StaticRail

# Select PGV to analyze if empty
gf_choose_file_dir_task -variable PGV_LIBS -keep -prompt "Please select PGV libraries:" -files "
    */out/Tech*.cl
"
gf_info "Selected PGV libraries: \e[32m$PGV_LIBS\e[0m selected"

gf_want_task -variable INIT_TASK_NAME Init
gf_want_task -variable POWER_TASK_NAME StaticPower
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$INIT_TASK_NAME.v.gz
    ls -l ./out/$INIT_TASK_NAME.def.gz
    ls -l ./out/$POWER_TASK_NAME.power.db
    ls -l $PGV_LIBS
    tree -L 2 ../../
    read
    touch ./out/$TASK_NAME.rail.db
"
gf_submit_task

##################################################
# Dynamic power
##################################################
gf_create_task -name DynamicPower

# Select scenario to calculate power
gf_choose -variable POWER_SCENARIO -message "Which power scenario to run?" -variants "
Switching activity 0.2
Switching activity 0.4
VCD: Default mode
"

gf_want_task -variable INIT_TASK_NAME Init
gf_want_task -variable EXTRACTION_TASK_NAME Extraction
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$INIT_TASK_NAME.v.gz
    ls -l ./out/$INIT_TASK_NAME.def.gz
    ls -l ./out/$EXTRACTION_TASK_NAME.spef.gz
    echo $POWER_SCENARIO
    read
    touch ./out/$TASK_NAME.power.db
"
gf_submit_task

##################################################
# Dynamic rail analysis
##################################################
gf_create_task -name DynamicRail

# Select PGV to analyze if empty
gf_choose_file_dir_task -variable PGV_LIBS -keep -prompt "Please select PGV libraries:" -files "
    */out/Tech*.cl
"
gf_info "Selected PGV libraries: \e[32m$PGV_LIBS\e[0m selected"

gf_want_task -variable INIT_TASK_NAME Init
gf_want_task -variable POWER_TASK_NAME DynamicPower
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$INIT_TASK_NAME.v.gz
    ls -l ./out/$INIT_TASK_NAME.def.gz
    ls -l ./out/$POWER_TASK_NAME.power.db
    ls -l $PGV_LIBS
    sleep 1
    tree -L 2 ../../
    read
    touch ./out/$TASK_NAME.rail.db
"
gf_submit_task
