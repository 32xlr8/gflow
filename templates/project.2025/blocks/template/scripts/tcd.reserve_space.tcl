# Reserve space for TCD cells to use at dummy insertion stage
<PLACEHOLDER>
catch {delete_route_blockages -name blockage_for_dtcd}
set xgrid [get_db site:core .size.x]
set ygrid [get_db site:core .size.y]
foreach rect {
    {1000 1000 1020 1020}
} {
    create_place_blockage -type hard -name blockage_for_dtcd -rects [list \
        [expr "round([lindex $rect 0] / $xgrid) * $xgrid"] \
        [expr "round([lindex $rect 1] / $ygrid) * $ygrid"] \
        [expr "round([lindex $rect 2] / $xgrid) * $xgrid"] \
        [expr "round([lindex $rect 3] / $ygrid) * $ygrid"] \
    ]
    create_route_blockage -layers {M1 M2 M3 M4 M5 M6 M7 M8 M9} -name blockage_for_dtcd -rects [list \
        [expr "round([lindex $rect 0] / $xgrid + 6) * $xgrid"] \
        [expr "round([lindex $rect 1] / $ygrid + 1) * $ygrid"] \
        [expr "round([lindex $rect 2] / $xgrid - 6) * $xgrid"] \
        [expr "round([lindex $rect 3] / $ygrid - 1) * $ygrid"] \
    ]
}
