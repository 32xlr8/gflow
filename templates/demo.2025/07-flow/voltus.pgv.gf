#!../../../bin/gflow

# Voltus PGV sub-flow

##################################################
# Tech-only PGV
##################################################
gf_create_task -name TechPGV

# Tool commands
gf_set_task_command "
    touch ./out/$TASK_NAME.cl
    echo $TASK_NAME output:
    ls -l ./out/$TASK_NAME.cl
    sleep 1
    tree -L 2 ../../
    read
"
gf_submit_task

##################################################
# Cells PGV
##################################################
gf_create_task -name CellsPGV

# Tool commands
gf_set_task_command "
    touch ./out/$TASK_NAME.cl
    echo $TASK_NAME output:
    ls -l ./out/$TASK_NAME.cl
"
gf_submit_task

##################################################
# Macro PGV
##################################################
gf_create_task -name MacroPGV

# Tool commands
gf_set_task_command "
    touch ./out/$TASK_NAME.cl
    echo $TASK_NAME output:
    ls -l ./out/$TASK_NAME.cl
"
gf_submit_task
