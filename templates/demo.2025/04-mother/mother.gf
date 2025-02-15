#!../../../bin/gflow

# Simple task dependencies demo

# Mother task
gf_create_task -name Mother
gf_set_task_command 'tree ../..; read'
gf_submit_task

# Daughter task
gf_create_task -name Daughter -mother Mother
gf_set_task_command "echo '$MOTHER_TASK_NAME => $TASK_NAME'; read"
gf_submit_task
