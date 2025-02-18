#!/usr/bin/perl

my @tasks; # [$task_id] = \%( R => $run, T => $task, F = $run_file, S => $status, M => $mark, L{$log_id} = 1);
my %tasks; # {$run}{$task} = $task_id;

my @files; # [$i] = \%( C => $count, F => $file, M => $modified);
my %files; # {$file} = $i;

my %parsed; # {R}{$run} = $count, {F}{$file} = $count, {L}{$file} = $count;

# Absolute path
my $start_dir = `readlink -m .`;
$start_dir =~ s/\n$//;
sub abs_path {
    my $path = shift;
    my $relative_dir = shift;
    $path = $relative_dir."/".$path if (($relative_dir ne "") && !($path =~ m:^/:));
    $path = $start_dir."/".$path if (!($path =~ m:^/:));
    $path =~ s:/{2,}:/:g;
    if ($path ne "/") {
        $path =~ s:^\./::g;
        1 while ($path =~ s:/\./:/:);
        while ($path =~ m:[^/]+/\.\.(/|$):) {
            last if ($path =~ m:^\.\./\.\.:);
            $path =~ s:[^/]+/\.\.(/|$)::;
        }
        $path =~ s:/\.$::;
        $path =~ s:[/\s]+$::;
        $path =~ s:(/\.)+$::;
    }
    $path = "/" if ($path eq "");
    return $path;
}

# Unique file/dir identifier
use File::stat;
sub get_file_id {
    my $file = abs_path(shift);
    if (defined $files{$file}) {
        $files[$files{$file}]{C}++;
        return $files{$file};
    } else {
        my %record = ();
        $record{F} = $file;
        $record{C} = 1;
        if (-e $file) {
            my $stat = stat($file);
            $record{M} = $stat->mtime;
        } else {
            $record{M} = 0;
        }
        push @files, \%record;
        $files{$file} = $#files;
        return $#files;
    }
}

# Next run directory to parse
sub next_run {
    my $dir = abs_path(shift);
    if (!defined $parsed{R}{$dir}) {
        $parsed{R}{$dir} = 0;
        print STDERR "Run $dir not found.\n" if (!-e $dir);
    }
    return get_file_id($dir);
}

# Next log file to parse
sub next_log {
    my $file = abs_path(shift);
    $parsed{L}{$file} = 0 if (!defined $parsed{L}{$file});
    return get_file_id($file);
}

# Preprocess status line
sub preprocess_status {
    my $status = shift;
    $status =~ s/\e\[[\d\;]+m//g;
    return $status;
}

# Parse new run
sub parse_run {
    my $run = abs_path(shift);

    # Parse only once
    if (!$parsed{R}{$run}) {
        # Parse run logs
        my %index = ();
        foreach my $file (glob "$run/logs/run.*.log") {
            if ($file =~ m|/logs/run\.(\d+)\.log$|) {
                my $index = $1;
                if (open FILE, $file) {
                    print "Run: $file ...\n";
                    my $task = "";
                    my %tasks = (); my @tasks = ();
                    while (<FILE>) {
                        next if (!/\S/);
                        my $status = "";
                        if (/^\[\e\[94m\d+\e\[0m\].*?\e\[94m(\S+?)\e\[0m status is/) {
                            $task = $1;
                            push @tasks, $task if (!defined $tasks{$task}); $tasks{$task} = 1;
                            $index{$index}{H}{$task}{S} = preprocess_status($_);
                        } elsif (s/^.*?\e\[35;45m \e\[0;35m //) {
                            $index{$index}{H}{$task}{S} .= preprocess_status($_);
                        } else {
                            if (/^\[\e\[94m\d+\e\[0m\].*?9?m(\S+?)\e\[0m (done|failed) in/) {
                                my $task = $1;
                                my $mark = $2;
                                push @{$index{$index}{A}}, $task if (!defined $index{$index}{X}{$task}); $index{$index}{X}{$task} = 1;
                                push @tasks, $task if (!defined $tasks{$task}); $tasks{$task} = 1;
                                $index{$index}{H}{$task}{F} = $file;
                                $index{$index}{H}{$task}{M} = $mark;
                                $index{$index}{H}{$task}{S} .= preprocess_status($_);
                            }
                            $task = "";
                        }
                        if ($status ne "") {
                            $status =~ s/\e\[[\d\;]+m\s*$//g;
                            $status =~ s/\e\[[\d\;]+m//g;
                            $index{$index}{H}{$task}{S} = $status;
                        }
                    }        
                    close FILE;
                    print "  Tasks: ".(join ", ", @tasks)."\n" if ($#tasks >= 0);
                    print "\n";
                } else {
                    print STDERR "Cannot open file ".$file." for read.\n";
                }
            }
        }
        
        # Update run index
        my %order = ();
        foreach my $index (sort {$a<=>$b} keys %index) {
            foreach my $task (@{$index{$index}{A}}) {
                $order{$task} = $index;
            }
        }
        
        # Add task for latest index only
        foreach my $index (sort {$a<=>$b} keys %index) {
            foreach my $task (@{$index{$index}{A}}) {
                if ($order{$task} == $index) {

                    # Current task record
                    my %record = ();
                    $record{T} = $task;
                    $record{R} = $run;
                    $record{F} = $index{$index}{H}{$task}{F};
                    $record{I} = $index;
                    $record{S} = $index{$index}{H}{$task}{S};
                    if (defined $index{$index}{H}{$task}{M}) {
                        $record{M} = $index{$index}{H}{$task}{M};
                    } else {
                        $record{M} = "unknown";
                    }
                    foreach my $pattern (
                        "$run/logs/$task.log",
                        "$run/scripts/$task.sh",
                        "$run/scripts/$task.tcl",
                        "$run/in/$task.mmmc.tcl"
                    ) {
                        foreach my $file (glob $pattern) {
                            push @{$record{L}}, next_log($file) if (-e "$file");
                        }
                    }

                    push @tasks, \%record;
                    $tasks{$run}{$task} = $#tasks;
                }
            }
        }
    }
    
    # Return run id
    return (++$parsed{R}{$run});
}

# Parse task logs
sub parse_log {
    my $log = abs_path(shift);
    if (!$parsed{L}{$log}) {
        my $root = $log;
        $root =~ s:/(in|out|tasks|logs|scripts)/.*::;
        if (open FILE, $log) {
            print "  Log: $log ...";
            my $log_id = get_file_id($log);
            while (<FILE>) {
                my $line = $_;

                # Internal files
                # s:([^\s\033]+/work_\S+/(in|out|tasks|logs|scripts)/[^\s\033]+)::
                while ($line =~ s:([^\s\033]+/(in|out|tasks|logs|scripts)/[^\s\033]+)::){
                    my $file = $1;
                    $file =~ s/^[\'\"\[\]\{\}\;\:]+//;
                    $file =~ s/[\'\"\.\,\?\[\]\{\}\;\:]+$//;
                    1 while ($file =~ s://:/:);
                    1 while ($file =~ s:/\./:/:);
                    1 while ($file =~ s:^\./::);
                    1 while ($file =~ s:/[^/]+/\.\./:/:);
                    if ($file =~ m:^(in|out|tasks)/:) {
                        my $run = $log;
                        $file = "$run/$file" if ($run =~ s:/(in|out|tasks|logs|scripts)/.*$::);
                    }
                    next if (!($file =~ m:^/:));
                    next if ($file =~ m:[\$\'\"]:);
                    $file =~ s:(\.db)/.*$:$1:;

                    # Attach found file to the task
                    $files[$log_id]{IF}{get_file_id($file)}++;

                    # Parent run detected
                    my $run = $file;
                    $files[$log_id]{R}{next_run($run)}++ if ($run =~ s:/(in|out|tasks|logs|scripts)/.*$::);
                }

                # External files
                while ($line =~ s:([^\s\033]+/[^\s\033]+/[^\s\033]+)::){
                    my $file = $1;
                    $file =~ s/^[\'\"\[\]\{\}\;\:]+//;
                    $file =~ s/[\'\"\.\,\?\[\]\{\}\;\:]+$//;
                    if ($file =~ s:^\.\./\.\./::) {
                        $file = $root."/".$file;
                        1 while ($file =~ s://:/:);
                        1 while ($file =~ s:/\./:/:);
                        1 while ($file =~ s:/[^/]+/\.\./:/:);
                    }
                    next if (!($file =~ m:^/:));
                    $file =~ s:(\.db)/.*$:$1:;
                    next if (! -f $file);

                    # Attach found file to the task
                    $files[$log_id]{EF}{get_file_id($file)}++;
                }
            }
            print "\n";
            close FILE;
        } else {
            print STDERR "Cannot open file ".$log." for read.\n";
        }
    }
    return (++$parsed{L}{$log});
}

# Parse 
sub parse {
    my $is_done = 0;
    
    # Repeat while nothing to parse
    while (!$is_done) {
        $is_done = 1;
    
        # Parse next run directories
        foreach my $run (keys %{$parsed{R}}) {
            if ($parsed{R}{$run} == 0) {
                parse_run($run);
                $is_done = 0;
            }
        }

        # Parse next log files
        my $count = 0;
        foreach my $file (keys %{$parsed{L}}) {
            if ($parsed{L}{$file} == 0) {
                parse_log($file);
                $is_done = 0;
                $count++;
            }
        }
        print "\n" if ($count);
    }
}

# Dump history in HTML format
sub print_html {
    my $file = shift;
    
    # Create HTML
    my $html = "";
    
    # Count tasks
    my $r_count = 0;
    my $t_count = 0;
    foreach my $run (keys %tasks) {
        $r_count++;
        foreach my $task (keys %{$tasks{$run}}) {
            $t_count++;
        }
    }
    
    # Header
    my $content = '<!DOCTYPE HTML>
        <html>
            <head>
                <meta charset="utf-8">
                    <title>Generic Flow History: '.$t_count.' tasks in '.$r_count.' runs</title>
                    <style type="text/css">
                        body {
                            font-family: Consolas,Monaco,Lucida Console,Liberation Mono,DejaVu Sans Mono,Bitstream Vera Sans Mono,Courier New, monospace;
                            font-size: 12px;
                        }
                        
                        p {
                            padding: 2px 4px 2px 4px;
                            margin: 4px 0px 0px 0px;
                        }

                        span.N { margin: 0px 4px 0px 0px; padding: 1px 4px 1px 4px; border: 1px solid #aaa; }

                        h1 {
                            text-align: center;
                            font-size: 18px;
                            padding: 0px;
                            margin-top: 16px;
                            margin-bottom: 3px;
                        }
                        h2 {
                            font-size: 14px;
                            padding: 0px;
                            margin-top: 12px;
                            margin-bottom: 4px;
                        }
                        h3 {
                            font-size: 14px;
                            padding: 0px;
                            margin-top: 8px;
                            margin-bottom: 4px;
                        }
                        
                        #control {
                            border:1px solid #aa8;
                            background-color: #fff;
                            font-size: 14px;
                            z-index: 9;
                            position: fixed;
                            top: 0px;
                            right: 0;
                            padding: 5px;
                            opacity: 0.1;
                            max-width: 75%;
                        }
                        #control:hover {
                            opacity: 1.0;
                        }
                        
                        
                        div.R0 { display: none; } 
                        div.R1 { display: block; margin-left: 8px; } 
                        
                        p.R0, p#R { border-left: 4px solid #8ac; } 
                        p.R1, p#R:hover { border-left: 4px solid #08c; background-color: #def; }

                        p.R1:hover { cursor: pointer; background-color: #eee; } 
                        p.R0:hover { cursor: pointer; background-color: #def; } 

                        div.TG0 { display: none;} 
                        div.TG1 { display: block; margin-left: 8px; } 
                        p.TG0, p#TG { border-left: 4px solid #aca; } 
                        p.TG1, p#TG:hover { border-left: 4px solid #0a0; background-color: #cfc; } 
                        p.TG1:hover { cursor: pointer; background-color: #eee; } 
                        p.TG0:hover { cursor: pointer; background-color: #cfc; } 

                        div.TR0 { display: none;} 
                        div.TR1 { display: block; margin-left: 8px; } 
                        p.TR0, p#TR { border-left: 4px solid #c88; } 
                        p.TR1, p#TR:hover { border-left: 4px solid #c00; background-color: #fdd; } 
                        p.TR1:hover { cursor: pointer; background-color: #eee; } 
                        p.TR0:hover { cursor: pointer; background-color: #fdd; } 

                        div.TS0 { display: none;} 
                        div.TS1 { display: block; padding: 4px; border-left: 4px solid #c8c; } 
                        p.TS0, p#TS { border-left: 4px solid #c8c; } 
                        p.TS1, p#TS:hover { border-left: 4px solid #c8c; background-color: #fef; }
                        p.TSN { border-left: 4px solid #c8c; background-color: #fef; } 
                        p.TS0:hover, p.TS1:hover { cursor: pointer; background-color: #fef; }

                        div.TFL0 { display: none;} 
                        div.TFL1 { display: block; padding: 4px; border-left: 4px solid #aa5; } 
                        p.TFL0, p#TFL { border-left: 4px solid #aa5; } 
                        p.TFL1 { border-left: 4px solid #aa5; background-color: #ffd;} 
                        p.TFL0:hover, p.TFL1:hover, p#TFL:hover { background-color: #ffd; }
                        p.TFL0:hover, p.TFL1:hover { cursor: pointer; }
                        
                        div.TFI0 { display: none;} 
                        div.TFI1 { display: block; padding: 4px; border-left: 4px solid #8a8; } 
                        p.TFI0, p#TFI { border-left: 4px solid #8a8; } 
                        p.TFI1 { border-left: 4px solid #8a8; background-color: #efe;} 
                        p.TFI0:hover, p.TFI1:hover, p.TFIL:hover, p#TFI:hover { background-color: #efe; }
                        p.TFI0:hover, p.TFI1:hover, p.TFIL:hover { cursor: pointer; }
                        
                        div.TFE0 { display: none;} 
                        div.TFE1 { display: block; padding: 4px; border-left: 4px solid #8aa; } 
                        p.TFE0, p#TFE { border-left: 4px solid #8aa; } 
                        p.TFE1 { border-left: 4px solid #8aa; background-color: #eff;} 
                        p.TFE0:hover, p.TFE1:hover, p#TFE:hover { background-color: #eff; }
                        p.TFE0:hover, p.TFE1:hover { cursor: pointer; }
                        
                        div.TFM0 { display: none;} 
                        div.TFM1 { display: block; padding: 4px; border-left: 4px solid #a88; } 
                        p.TFM0, p#TFM { border-left: 4px solid #a88; } 
                        p.TFM1 { border-left: 4px solid #a88; background-color: #fee;} 
                        p.TFM0:hover, p.TFM1:hover, p#TFM:hover { background-color: #fee; }
                        p.TFM0:hover, p.TFM1:hover { cursor: pointer; }
                        
                        span.L1 { padding: 2px 4px 2px 4px; 2px; margin: 0px 2px 0px 2px; border: 1px solid #ccc; }
                        span.L2 { padding: 2px 4px 2px 4px; 2px; margin: 0px 2px 0px 2px; border: 1px solid #ddd; }
                        span.L1:hover, span.L2:hover { cursor: pointer; border: 1px solid #bdf; }
                        
                        p.L1 { padding: 2px 4px 2px 4px; margin: 4px 0px 4px 0px; border-left: 4px solid #aaa; }
                        p.L1:hover { background-color: #eee; }
                        
                        p.L2 { padding: 2px 14px 2px 8px; margin: 2px 0px 0px 8px; }
                        
                        pre { margin:0px; }

                </style>
            </head>
            <body>
    '; $content =~ s|^\s{12}||; $html .= $content;

    # Header
    $content = "<h1>Generic Flow History</h1>\n";
    # $content .= "<h2>$r_count runs, $t_count tasks</h2>\n";
    
    # Control banner
    $content .= "<div id=control>\n";

    $content .= "<p class=L1>";
        # $content .= "<input type=checkbox id=cbR autocomplete='off' onclick=\"if (this.checked) {click_class('p.R0');} else {click_class('p.R1');};\"/>";
        # $content .= "<span class=L1 onclick=\"click_class('p.R0');\">&#9660;</span>";
        # $content .= "<span class=L1 onclick=\"click_class('p.R1');\">&#8689;</span>";
        $content .= "<span class=L1 onclick=\"set_class_visibility('p.R0',false);\">&#10006;</span>";
        $content .= "<span class=L1 onclick=\"set_class_visibility('p.R0',true);\">&#10226;</span>";
    $content .= " Runs</p>\n";

    $content .= "<p id=R class=L2>";
        $content .= "<input type=checkbox id=cbTG autocomplete='off' onclick=\"if (this.checked) {click_class('p.R0');} else {click_class('p.R1');};\"/>";
    $content .= " All</p>\n";

    $content .= "<p class=L1>";
        # $content .= "<input type=checkbox id=cbT autocomplete='off' onclick=\"if (this.checked) {click_class('p.TG0');click_class('p.TR0');} else {click_class('p.TG1');click_class('p.TR1');};\"/>";
        # $content .= "<span class=L1 onclick=\"click_class('p.TG0');click_class('p.TR0');\">&#9660;</span>";
        # $content .= "<span class=L1 onclick=\"click_class('p.TG1');click_class('p.TR1');\">&#8689;</span>";
        $content .= "<span class=L1 onclick=\"set_class_visibility('p.TG0',false);set_class_visibility('p.TR0',false);\">&#10006;</span>";
        $content .= "<span class=L1 onclick=\"set_class_visibility('p.TG0',true);set_class_visibility('p.TR0',true);\">&#10226;</span>";
    $content .= " Tasks</p>\n";

    $content .= "<p id=TG class=L2>";
        $content .= "<input type=checkbox id=cbTG autocomplete='off' onclick=\"if (this.checked) {click_class('p.TG0');} else {click_class('p.TG1');};\"/>";
    $content .= " Done</p>\n";

    $content .= "<p id=TR class=L2>";
        $content .= "<input type=checkbox id=cbTR autocomplete='off' onclick=\"if (this.checked) {click_class('p.TR0');} else {click_class('p.TR1');};\"/>";
    $content .= " Failed</p>\n";

    # $content .= "<p id=TS class=L2>";
    #     $content .= "<span class=L2 onclick=\"click_class('p.TS0');\">&#9660;</span>";
    #     $content .= "<span class=L2 onclick=\"click_class('p.TS1');\">&#8689;</span>";
    #     $content .= "<span class=L2 onclick=\"set_class_visibility('p.TS0',false);\">&#10006;</span>";
    #     $content .= "<span class=L2 onclick=\"set_class_visibility('p.TS0',true);\">&#10226;</span>";
    # $content .= " Statuses</p>\n";

    $content .= "<p class=L1>";
        # $content .= "<span class=L1 onclick=\"click_class('p.TFL0');click_class('p.TFI0');click_class('p.TFE0');click_class('p.TFM0');\">&#9660;</span>";
        # $content .= "<span class=L1 onclick=\"click_class('p.TFL1');click_class('p.TFI1');click_class('p.TFE1');click_class('p.TFM1');\">&#8689;</span>";
        $content .= "<span class=L1 onclick=\"set_class_visibility('p.TS0',false);set_class_visibility('p.TFL0',false);set_class_visibility('p.TFI0',false);set_class_visibility('p.TFE0',false);set_class_visibility('p.TFM0',false);\">&#10006;</span>";
        $content .= "<span class=L1 onclick=\"set_class_visibility('p.TS0',true);set_class_visibility('p.TFL0',true);set_class_visibility('p.TFI0',true);set_class_visibility('p.TFE0',true);set_class_visibility('p.TFM0',true);\">&#10226;</span>";
    $content .= " Files</p>\n";

    # $content .= "<p id=TFL class=L2>";
    #     $content .= "<span class=L2 onclick=\"click_class('p.TFL0');\">&#9660;</span>";
    #     $content .= "<span class=L2 onclick=\"click_class('p.TFL1');\">&#8689;</span>";
    #     $content .= "<span class=L2 onclick=\"set_class_visibility('p.TFL0',false);\">&#10006;</span>";
    #     $content .= "<span class=L2 onclick=\"set_class_visibility('p.TFL0',true);\">&#10226;</span>";
    # $content .= " Analyzed</p>\n";
    # 
    # $content .= "<p id=TFI class=L2>";
    #     $content .= "<span class=L2 onclick=\"click_class('p.TFI0');\">&#9660;</span>";
    #     $content .= "<span class=L2 onclick=\"click_class('p.TFI1');\">&#8689;</span>";
    #     $content .= "<span class=L2 onclick=\"set_class_visibility('p.TFI0',false);\">&#10006;</span>";
    #     $content .= "<span class=L2 onclick=\"set_class_visibility('p.TFI0',true);\">&#10226;</span>";
    # $content .= " Internal</p>\n";
    # 
    # $content .= "<p id=TFE class=L2>";
    #     $content .= "<span class=L2 onclick=\"click_class('p.TFE0');\">&#9660;</span>";
    #     $content .= "<span class=L2 onclick=\"click_class('p.TFE1');\">&#8689;</span>";
    #     $content .= "<span class=L2 onclick=\"set_class_visibility('p.TFE0',false);\">&#10006;</span>";
    #     $content .= "<span class=L2 onclick=\"set_class_visibility('p.TFE0',true);\">&#10226;</span>";
    # $content .= " External</p>\n";
    # 
    # $content .= "<p id=TFM class=L2>";
    #     $content .= "<span class=L2 onclick=\"click_class('p.TFM0');\">&#9660;</span>";
    #     $content .= "<span class=L2 onclick=\"click_class('p.TFM1');\">&#8689;</span>";
    #     $content .= "<span class=L2 onclick=\"set_class_visibility('p.TFM0',false);\">&#10006;</span>";
    #     $content .= "<span class=L2 onclick=\"set_class_visibility('p.TFM0',true);\">&#10226;</span>";
    # $content .= " Missing</p>\n";

    $content .= "<p id=TS class=L2>";
        $content .= "<input type=checkbox id=cbTS autocomplete='off' onclick=\"if (this.checked) {click_class('p.TS0');} else {click_class('p.TS1');};\"/>";
    $content .= " Statuses</p>\n";

    $content .= "<p id=TFL class=L2>";
        $content .= "<input type=checkbox id=cbTFL autocomplete='off' onclick=\"if (this.checked) {click_class('p.TFL0');} else {click_class('p.TFL1');};\"/>";
    $content .= " Analyzed</p>\n";

    $content .= "<p id=TFI class=L2>";
        $content .= "<input type=checkbox id=cbTFI autocomplete='off' onclick=\"if (this.checked) {click_class('p.TFI0');} else {click_class('p.TFI1');};\"/>";
    $content .= " Internal</p>\n";

    $content .= "<p id=TFE class=L2>";
        $content .= "<input type=checkbox id=cbTFE autocomplete='off' onclick=\"if (this.checked) {click_class('p.TFE0');} else {click_class('p.TFE1');};\"/>";
    $content .= " External</p>\n";

    $content .= "<p id=TFM class=L2>";
        $content .= "<input type=checkbox id=cbTFM autocomplete='off' onclick=\"if (this.checked) {click_class('p.TFM0');} else {click_class('p.TFM1');};\"/>";
    $content .= " Missing</p>\n";

    $content .= "</div>\n";

    # Directory creation order
    my %stat = ();
    foreach my $run (keys %tasks) {
        if (-e $run) {
            my $stat = stat($run);
            $stat{$run} = $stat->mtime;
        }
    }
    
    # Runs
    my $r_counter = 0;
    my %history = ();
    my @history = sort {$files[$files{$a}]{M}<=>$files[$files{$b}]{M}} keys %tasks;
    foreach my $run (@history) {
        $history{$run} = 1;

        $r_counter++;
        my $t_counter = 0;

        # Run
        $content .= "<p id=RP_$files{$run} class=R0 onclick=\"toggle_id_class('R','$files{$run}');\"><span class=N>$r_counter</span>";
        if ($run =~ m|^(.*/)([^/]+)$|) {
            $content .= "$1<b>$2</b>";
        } else {
            $content .= "$run";
        }
        $content .= "</p>\n";
        
        # Tasks
        $content .= "<div id=RD_$files{$run} class=R0>\n";
        foreach my $task (sort {$tasks{$run}{$a}<=>$tasks{$run}{$b}} keys %{$tasks{$run}}) {
            $t_counter++;

            # Task name
            my $task_id = $tasks{$run}{$task};
            my $record = $tasks[$task_id];
            my $class = "TR"; my $value = 0;
            if ($$record{M} eq "done") {
                $class = "TG";
                $value = 0;
            }
            $content .= "<p id=TP_$task_id class=${class}${value} onclick=\"toggle_id_class('T','$task_id');\"><span class=N>$r_counter.$t_counter</span>$task - $$record{M}</p>\n";

            # Task content
            $content .= "<div id=TD_$task_id class=${class}${value}>\n";
            
            # # Task logs
            # foreach my $log_id (@{$$record{L}}) {
            #     $content .= "<p id=TLP_${task_id}_${log_id} class=TL1 onclick=\"toggle_id_class('TL','${task_id}_${log_id}');\">Log: $files[$log_id]{F}</p>\n";
            #     $content .= "<div id=TLD_${task_id}_${log_id} class=TL1>\n";
            #     $content .= "<p id=TIFP_${task_id}_${_} class=TIF>$files[$_]{F}</p>\n" foreach (sort keys %{$files[$log_id]{IF}});
            #     $content .= "<p id=TEFP_${task_id}_${_} class=TEF>$files[$_]{F}</p>\n" foreach (sort keys %{$files[$log_id]{EF}});
            #     $content .= "<p id=TIRP_${task_id}_${_} class=TIR onclick=\"toggle_id_class('R','".$files{$files[$_]{F}}."',1,1);\">$files[$_]{F}</p>\n" foreach (sort keys %{$files[$log_id]{R}});
            #     $content .= "</div>\n";
            # }
            
            # # Parent runs
            # foreach my $log_id (@{$$record{L}}) {
            #     my %runs = ();
            #     foreach (sort keys %{$files[$log_id]{R}}) {
            #         $runs{$_} = 1 if ($files[$_]{F} ne $run);
            #     }
            #     if (keys %runs > 0) {
            #         $content .= "<p id=TIRP_${task_id}_${log_id} class=TIR1 onclick=\"toggle_id_class('TIR','${task_id}_${log_id}');\"><span class=N>".(keys %runs)."</span>Parent runs: $files[$log_id]{F}</p>\n";
            #         $content .= "<div id=TIRD_${task_id}_${log_id} class=TIR1>\n";
            #         $content .= "<p id=TIRL_${task_id}_${_} class=TIRL onclick=\"toggle_id_class('R','".$files{$files[$_]{F}}."',1,1);window.location.href='#RP_".$files{$files[$_]{F}}."';\">$files[$_]{F}</p>\n" foreach (sort keys %runs);
            #         $content .= "</div>\n";
            #     }
            # }

            # Task status
            if ($$record{S} eq "") {
                $content .= "<p id=TSP_$task_id class=TSN);\">Log: $$record{F}</p>\n";
            } else {
                $content .= "<p id=TSP_$task_id class=TS0 onclick=\"toggle_id_class('TS','$task_id');\">Status: $$record{F}</p>\n";
                $content .= "<div id=TSD_$task_id class=TS0><pre>$$record{S}</pre></div>\n";
            }

            # Run files
            my %grouped_files = ();
            foreach my $log_id (@{$$record{L}}) {
                $grouped_files{L}{$log_id}++;
                foreach my $file_id (keys %{$files[$log_id]{IF}}) {
                    if ($files[$file_id]{M} > 0) {
                        $grouped_files{I}{$file_id}++;
                    } else {
                        $grouped_files{M}{$file_id}++;
                    }
                }
                foreach my $file_id (keys %{$files[$log_id]{EF}}) {
                    if ($files[$file_id]{M} > 0) {
                        $grouped_files{E}{$file_id}++;
                    } else {
                        $grouped_files{M}{$file_id}++;
                    }
                }
            }
            
            # Log files
            if (keys %{$grouped_files{L}}) {
                $content .= "<p id=TFLP_${task_id} class=TFL0 onclick=\"toggle_id_class('TFL','${task_id}');\"><span class=N>".(keys %{$grouped_files{L}})."</span>Analyzed run files</p>\n";
                $content .= "<div id=TFLD_${task_id} class=TFL0>\n";
                foreach my $file_id (sort {$files[$a]{M} <=> $files[$b]{M}} keys %{$grouped_files{L}}) {
                    $content .= "<p id=TFLL_${task_id}_${file_id} class=TFLN>$files[$file_id]{F}</p>\n";
                }
                $content .= "</div>\n";
            }
            
            # Internal files
            if (keys %{$grouped_files{I}}) {
                $content .= "<p id=TFIP_${task_id} class=TFI0 onclick=\"toggle_id_class('TFI','${task_id}');\"><span class=N>".(keys %{$grouped_files{I}})."</span>Internal flow files</p>\n";
                $content .= "<div id=TFID_${task_id} class=TFI0>\n";
                foreach my $file_id (sort {$files[$a]{M} <=> $files[$b]{M}} keys %{$grouped_files{I}}) {
                    my $file_run = $files[$file_id]{F};
                    my $file_task = $files[$file_id]{F};
                    if ($file_run =~ s:/(in|out|tasks|logs|scripts)/(.*)$::) {
                        $file_task = $2;
                        $file_task =~ s:/.*$::g;
                        1 while ($file_task =~ s:\.[a-z]\w*$::gi);
                    }
                    if (defined $files{$file_run}) {
                        if (defined $tasks{$file_run}{$file_task}) {
                            $content .= "<p id=TFIL_${task_id}_${file_id} class=TFIL onclick=\"toggle_id_class('R','".$files{$file_run}."',1,1);toggle_id_class('T', '".$tasks{$file_run}{$file_task}."',1,1)\">$files[$file_id]{F}</p>\n";
                        } else {
                            $content .= "<p id=TFIL_${task_id}_${file_id} class=TFIL onclick=\"toggle_id_class('R','".$files{$file_run}."',1,1);\">$files[$file_id]{F}</p>\n";
                        }
                    } else {
                            $content .= "<p id=TFIL_${task_id}_${file_id} class=TFIN>$files[$file_id]{F}</p>\n";
                    }
                }
                $content .= "</div>\n";
            }
            
            # External files
            if (keys %{$grouped_files{E}}) {
                $content .= "<p id=TFEP_${task_id} class=TFE0 onclick=\"toggle_id_class('TFE','${task_id}');\"><span class=N>".(keys %{$grouped_files{E}})."</span>External project files</p>\n";
                $content .= "<div id=TFED_${task_id} class=TFE0>\n";
                foreach my $file_id (sort {$files[$a]{M} <=> $files[$b]{M}} keys %{$grouped_files{E}}) {
                    $content .= "<p id=TFEL_${task_id}_${file_id} class=TFEN>$files[$file_id]{F}</p>\n";
                }
                $content .= "</div>\n";
            }
            
            # Missing files
            if (keys %{$grouped_files{M}}) {
                $content .= "<p id=TFMP_${task_id} class=TFM0 onclick=\"toggle_id_class('TFM','${task_id}');\"><span class=N>".(keys %{$grouped_files{M}})."</span>Missing files</p>\n";
                $content .= "<div id=TFMD_${task_id} class=TFM0>\n";
                foreach my $file_id (sort {$files[$a]{F} cmp $files[$b]{F}} keys %{$grouped_files{M}}) {
                    $content .= "<p id=TFML_${task_id}_${file_id} class=TFMN>$files[$file_id]{F}</p>\n";
                }
                $content .= "</div>\n";
            }

            # Task content
            $content .= "</div>\n";
        }
        $content .= "</div>\n";
    }
    $html .= $content;

    $content = '
        <script>
            function click_class (query_class_name) {
                var elements = document.querySelectorAll(query_class_name);
                var i;
                for (i = 0; i < elements.length; i++) {
                    if (!elements[i].hidden) {
                        elements[i].click();
                    }
                }
            }
            function set_class_visibility (query_class_name, is_visible) {
                var elements = document.querySelectorAll(query_class_name);
                var i;
                for (i = 0; i < elements.length; i++) {
                    elements[i].hidden = !is_visible;
                }
            }
            function toggle_id_class (id_prefix, id_number,value="",go=0) {
                var p = document.getElementById(id_prefix + "P_" + id_number);
                var d = document.getElementById(id_prefix + "D_" + id_number);
                var class_prefix = p.className.substring(0,p.className.length-1);
                if (value == "") {
                    if (p.className.substring(p.className.length-1,p.className.length) == "0") {
                        value = "1";
                    } else {
                        value = "0";
                    }
                }
                p.className = class_prefix + value;
                d.className = class_prefix + value;
                if (go == 1) {
                    window.location.href = "#" + id_prefix + "P_" + id_number;
                }
            }
        </script>
    '; $content =~ s|^\s{20}||; $html .= $content;
    
    $content = '
            </body>
        </content>
    '; $content =~ s|^\s{12}||; $html .= $content;

    # Check not included runs
    my %dirs = ();
    my @other = ();
    foreach my $run (@history) {
        my $dir = $run;
        $dir =~ s|/[^/]+$||;
        if (!defined $dirs{$dir}) {
            if (opendir DIR, $dir) {
                foreach my $name (readdir DIR) {
                    next if (($name eq ".") || ($name eq ".."));
                    if (!defined $history{"$dir/$name"}) {
                        $history{"$dir/$name"}++;
                        push @other, "$dir/$name";
                    }
                }
                closedir DIR;
            }
        }
        $dirs{$dir}++;
    }

    # Runs not included into history
    if ($#other >= 0) {
        print "Runs not in the history: ".($#other+1)."\n\n";
        print "  $_\n" foreach (sort @other);
        print "\n";
    }

    # Runs not included into history
    if ($#history >= 0) {
        print "Runs in the history: ".($#history+1)."\n\n";
        print "  $_\n" foreach (@history);
        print "\n";
    } else {
        print STDERR "No runs in the history.\n";
        exit(1);
    }

    # Print HTML content
    if ($file ne "") {
        if (open FILE, ">".$file) {
            print FILE $html;
            close FILE;
            print "HTML report ".abs_path($file)." written.\n";

        # Html file creation error
        } else {
            print STDERR "Cannot open file ".$file." for write.\n";
        }
    }
}

# Quene runs from command line arguments
my $key = "";
my $html = "";
foreach (@ARGV) {
    if ($key eq "-html") {
        $html = $_;
        $key = "";
    } elsif ($_ eq "-html") {
        $key = $_;
    } else {
        if (-d $_) {
            next_run($_);
        } else {
            print STDERR "Cannot open directory ".$_."\n";
        }
    }
}

# Perform parsing
print "\n";
parse();

# Print flow history HTML
print_html($html);
print "\n";
