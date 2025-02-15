# Check floorplan with TCIC rules
<PLACEHOLDER>
eval_legacy {
    source "*_tCIC_macro_usage_manager.tcl"
    source "*_tCIC_set_cip_variables.tcl"

    tCIC_set_design_cell_type <PLACEHOLDER>
    tCIC_set_max_DTCD_layer 11
    tCIC_reset_macro_usage
    tCIC_specify_macro_usage -usage SRAM -macro [get_db [get_db insts -if .base_cell.name==*] .name]
    
    Report macro usage
    tCIC_report_macro_usage
    
    convert_tCIC_to_ufc \
        -input_files "*_tCIC_*.tcl" \
        -ufc_file ./out/$TASK_NAME.ufc
    redirect { check_ufc ./out/$TASK_NAME.ufc } > "./reports/$TASK_NAME.tcic.log"
}
