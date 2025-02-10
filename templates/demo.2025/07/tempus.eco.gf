#!../../../bin/gflow

gf_source tempus.sta.gf

##################################################
# Tempus TSO
##################################################
gf_create_task -name TSO

# Choose scenario
gf_choose -keep -variable ECO_SCENARIO -message "Which ECO scenario to run?" -variants '
Swap: setup, hold
Swap: leakage
Swap: power
Full: drv
Full: setup
Full: hold
Full: leakage
Full: power
Full: area
Full: setup hold
Full: drv setup hold
'
gf_want_task -variable INIT_TASK_NAME Init
gf_want_task -variable EXTRACTION_TASK_NAME Extraction
gf_want_task -variable STA_TASK_NAME STA
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$INIT_TASK_NAME.v.gz
    ls -l ./out/$INIT_TASK_NAME.def.gz
    ls -l ./out/$EXTRACTION_TASK_NAME.spef.gz
    ls -l ./out/$STA_TASK_NAME.tempus.db
    echo $ECO_SCENARIO
    read
    touch ./out/$TASK_NAME.eco.tcl
"
gf_submit_task

#################################################
# Innovus ECO
##################################################
gf_create_task -name ECO -mother TSO
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$MOTHER_TASK_NAME.eco.tcl
    tree -L 2 ../../
    read
    touch ./out/$TASK_NAME.innovus.db
"
gf_submit_task
