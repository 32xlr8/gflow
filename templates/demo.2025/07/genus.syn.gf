#!../../../bin/gflow

##################################################
# Elaboration
##################################################
gf_create_task -name Elaborate
gf_set_task_command "
    touch ./out/$TASK_NAME.genus.db
"
gf_submit_task

##################################################
# Generic Synthesis
##################################################
gf_create_task -name SynGen -mother Elaborate
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$MOTHER_TASK_NAME.genus.db
    touch ./out/$TASK_NAME.genus.db
"
gf_submit_task

##################################################
# Mapping
##################################################
gf_create_task -name SynMap -mother SynGen
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$MOTHER_TASK_NAME.genus.db
    touch ./out/$TASK_NAME.genus.db
"
gf_submit_task

##################################################
# Optimization
##################################################
gf_create_task -name SynOpt -mother SynMap
gf_set_task_command "
    echo $TASK_NAME inputs:
    ls -l ./out/$MOTHER_TASK_NAME.genus.db
    tree -L 2 ../../
    read
    touch ./out/$TASK_NAME.genus.db
    touch ./out/$TASK_NAME.v
"
gf_submit_task
