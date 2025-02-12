# Insert TCD cells into the design
set tcd_patterns {*_TCD_* FEOL_* BEOL_* *DTCD_FEOL* *DTCD_BEOL* *_DTCD_*}
foreach cell [get_db base_cells $tcd_patterns] {get_db insts -if ".base_cell==$cell" -foreach {delete_inst -inst [get_db $object .name]}}
set index 1
foreach location {
    {600 980}
    {600 1640}
    {1470 980}
    {1470 1640}
} {
    incr index
    set tcd_insts {}
    foreach cell [get_db [get_db base_cells $tcd_patterns] .name] {
        create_inst -physical -status fixed -location $location -cell $cell -inst ${cell}_${index}
        lappend tcd_insts inst:${cell}_${index}
    }
    
    gf_align_instances_to_grid 0.048 0.090 $tcd_insts
    
    catch {delete_route_blockages -name block_under_tcd}
    foreach rect [get_db $tcd_insts .bbox -u] {
        create_route_blockage -layers {M1 VIA1 M2 VIA2 M3 VIA3 M4 VIA4 M5 VIA5 M6 VIA6 M7 VIA7 M8 VIA8 M9} -name block_under_tcd -rects [list [list \
            [expr [lindex $rect 0]-4.0] [expr [lindex $rect 1]-4.0] \
            [expr [lindex $rect 2]+4.0] [expr [lindex $rect 3]+4.0] \
        ]]
    }
}
