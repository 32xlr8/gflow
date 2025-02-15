#!../../../bin/gflow

# Task status demo

# Failed task
gf_create_task -name Fail
gf_set_task_command 'cat ../../../Failed.log; read'

gf_add_failed_marks 'failed'

gf_submit_task

# Successful task
gf_create_task -name Success
gf_set_task_command 'cat ../../../Success.log; read'

gf_add_success_marks 'successful'

gf_add_status_marks -1 +6 'Setup mode'
gf_add_status_marks '^ERROR'

gf_submit_task
