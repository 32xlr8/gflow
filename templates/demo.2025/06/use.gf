#!../../../bin/gflow

# Data use task
gf_create_task -name Use

# Choose file or task
gf_choose_file_dir_task -variable DATA -keep -prompt "Please select data to use:" -files "
    */out/*.dat
" -active -tasks "
    */tasks/Data*
"

# Auto-populate data when active task selected
if [ -e "$DATA/run" ]; then
    gf_want_task -exact $DATA
    DATA="$DATA/out/$(basename "$DATA").dat"
fi

# Display chosen file
gf_set_task_command "
    ls -l $DATA
    read
"

# End task
gf_submit_task
