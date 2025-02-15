#!../../../bin/gflow

# Calibre physical signoff sub-flow

##################################################
# Stream out
##################################################
gf_create_task -name StreamOut

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
    read
    touch ./out/$TASK_NAME.v.gz
    touch ./out/$TASK_NAME.gds.gz
"
gf_submit_task

##################################################
# Dummy fill
##################################################
gf_create_task -name Dummy -mother StreamOut
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$MOTHER_TASK_NAME.gds.gz
    read
    touch ./out/$TASK_NAME.gds.gz
"
gf_submit_task

##################################################
# DRC
##################################################
gf_create_task -name DRC -mother Dummy
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$MOTHER_TASK_NAME.gds.gz
    read
    touch ./out/$TASK_NAME.results
"
gf_submit_task

##################################################
# LVS
##################################################
gf_create_task -name LVS
gf_want_task -variable STREAMOUT_TASK_NAME StreamOut
gf_want_task -variable DUMMY_TASK_NAME Dummy
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$STREAMOUT_TASK_NAME.v.gz
    ls -l ./out/$DUMMY_TASK_NAME.gds.gz
    tree -L 2 ../../
    read
    touch ./out/$TASK_NAME.svdb
"
gf_submit_task
