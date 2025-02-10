# Query MMMC steps for gconfig
gf_source ../../project.2025/tools/tool_steps.gconfig.gf

# Initialize gconfig variables
gf_create_step -name init_variables '

    # Variables used in file names
    gconfig::define_variables -group "Project file name substitutions" {pvt_p pvt_v pvt_t rc}

    # Context-aware values
    gconfig::add_section {
        # Views mask is {<constraint_mode> <process> <voltage> <temperature> <rc_corner> <check>}

        # Extraction temperature value
        -views {* * * m40 * *} {$temperature -40}
        -views {* * *  25 * *} {$temperature 25}
        -views {* * *  85 * *} {$temperature 85}
        -views {* * * 125 * *} {$temperature 125}

        # Process variants to use in file name patterns
        -views {* tt * * * *} {$pvt_p {tt nominal typical}}
        -views {* ss * * * *} {$pvt_p {ssg slow worst}}
        -views {* ff * * * *} {$pvt_p {ffg ffast best}}

        # Voltage variants to use in file name patterns
        -views {* * 500mv * * *} {$pvt_v {500mv 0p500v 0p50v 0p5v}}
        -views {* * 720mv * * *} {$pvt_v {720mv 0p720v 0p72v}}
        -views {* * 800mv * * *} {$pvt_v {800mv 0p800v 0p80v 0p8v}}
        -views {* * 880mv * * *} {$pvt_v {880mv 0p880v 0p88v}}

        # Temperature variants to use in file name patterns
        -views {* * * m40 * *} {$pvt_t {m40 m40c n40c}}
        -views {* * *  25 * *} {$pvt_t {25 25c}}
        -views {* * *  85 * *} {$pvt_t {85 85c}}
        -views {* * * 125 * *} {$pvt_t {125 125c}}

        # QRC variants to use in file name patterns
        -views {* * * * cb *} {$rc {cb cbest}}
        -views {* * * * cw *} {$rc {cw cworst}}
        -views {* * * * ct *} {$rc {ct typical}}
    }
'

# Initialize project files
gf_create_step -name init_files '

    # Imitate existing files
    exec touch cells.ffg0p88v125.lib cells.ffg0p88vm40c.lib cells.ssg0p72v125.lib cells.ssg0p5vm40c.lib cells.ssg0p72vm40c.lib cells.tt0p8v25.lib cells.tt0p8v85.lib func.sdc qrc.cbest qrc.cworst qrc.typical scan.sdc

    # QRC technology file
    gconfig::add_files qrc {
        ./qrc.${rc}
    }

    # LIB files
    gconfig::add_files lib {
        ./cells.${pvt_p}${pvt_v}${pvt_t}.lib
    }

    # Block-specific SDC files
    gconfig::add_files sdc -views {scan * * * * *} {
        ./scan.sdc
    }
    gconfig::add_files sdc -views {func * * * * *} {
        ./func.sdc
    }

'
