#!/bin/bash

################################################################################
# Generic Flow v5.5.2 (February 2025)
################################################################################
#
# Copyright 2011-2025 Gennady Kirpichev (https://github.com/32xlr8/gflow.git)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################
# Filename: templates/project.2025/create_tsmc_vt_tables.sh
# Purpose:  Parse TSMC PDF files to extract dV/dT derates
################################################################################

script_name=$(basename "$0" .sh)

for arg in $@; do
    if [ -d "$arg" ]; then
        files+="$(find $arg -iname 'DB_*_TCBN*.pdf')"$'\n'
    else
        files+="$(readlink -m $arg)"$'\n'
    fi
done

if [ -z "$files" -a ! -e "./$script_name.data" ]; then
    files=$(find . -maxdepth 7 -iname 'DB_*_TCBN*.pdf')
fi

replace_in_library='
    s|^.*BWP|BWP|;
    s|CPDMB|CPD|;
    s|_.*_||g;
'

replace_in_corner='
    s/_//g;

    s/^ssgnp/ss /;
    s/^ffgnp/ff /;
    s/^ssg/ss /;
    s/^ffg/ff /;
    s/^tt/tt /;

    s/v(m?\d+)c/"v ".$1." "/e;

    s|( r?)cbestCCbestT\b|$1."cbt"|ei;
    s|( r?)cworstCCworstT\b|$1."cwt"|ei;
    s|( r?)cbestCCbest\b|$1."cb"|ei;
    s|( r?)cworstCCworst\b|$1."cw"|ei;
    s|( r?)cbest\b|$1."cb"|ei;
    s|( r?)cworst\b|$1."cw"|ei;
    s|( )typical\b|$1."ct"|ei;
'

filter_html='
    my $content = "";
    while (<STDIN>) {
        s/&nbsp;/ /g;
        s/&#160;/ /g;
        s/\<\/?br\/?>/\n/g;
        s/\<\/?hr\/?>/\n/g;
        s/\<\/?[^\>]+\>/ /g;
        s/\xc2/ /g;
        s/\xa0/ /g;
        s/(\d)\s+/$1\n/gm if (/^[\s\d\.]+$/);
        s/ +//g;
        next if (/security/i);
        next if (/^\s*$/i);
        $content .= $_;
    }
    $content =~ s/(\d\.)\s+(\d\n)/$1$2/gm;

    my $need_library = 0;
    my $section = ""; my $table = "";
    #my $value = "";
    my @data; my $data = -1; # $data[][]{C:,T:IR,T:dV,T:dT}
    my $corner_wrap = 0;
    foreach (split /\n/, $content) {
        if (/^([IXV]+)\./) {
            $section = "";
            $table = "";
            $section = "G" if (/GENERALINFO/);
            $section = "V" if (/VOLTAGEVAR/);
            $section = "T" if (/TEMPERATUREVAR/);
            $data++;
        } elsif ($section eq "G") {
            $table = "";
            if (s/^.*\bLibraryName\W+//i) {
                $need_library = "N";
            }
            if (s/^.*\bLibraryVer\w+\W+//i) {
                $need_library = "V";
            }
            if ($need_library ne "0") {
                if (/(\w+)/) {
                    $data[$data][$#{$data[$data]}+1]{"$need_library:"} = $1;
                    #print "$need_library:$1\n";
                    $need_library = 0;
                }
            }
        } elsif ($section ne "") {
            if (/^IRdrop/) {
                $table = "T:IR"; $corner_wrap = 0;
            } elsif (/^OCV/) {
                $table = "T:dV"; $corner_wrap = 0;
            } elsif (/^TemperatureOCV/) {
                $table = "T:dT"; $corner_wrap = 0;
            } elsif (/^\s*((ss|ff|tt)\S*\dv\S*)\s*$/) {
                $data[$data][$#{$data[$data]}+1]{"C:"} = $1;
                $corner_wrap = 3;
            } elsif ($#{$data[$data]} >= 0) {
                if (/^\s*(\d+\.\d+)\s*$/) {
                    $data[$data][$#{$data[$data]}]{$table} .= " ".$1;
                    $value .= " ".$1;
                } elsif ($corner_wrap) {
                    my $corner = $data[$data][$#{$data[$data]}]{"C:"}."$_";
                    $corner =~ s/\s.*$//g;
                    $data[$data][$#{$data[$data]}]{"C:"} = $corner;
                } else {
                    $data[$data][$#{$data[$data]}+1]{"?:"} .= $_;
                    #print "?:$_\n";
                }
            } elsif (!/^\s*corner\s*$/i) {
                $data[$data][$#{$data[$data]}+1]{"?:"} .= $_;
                $corner_wrap = 0;
            }
            $corner_wrap-- if ($corner_wrap);
        }
    }

    foreach my $section (@data) {
        foreach my $value (@$section) {
            foreach my $table ("N:", "V:", "C:", "T:IR", "T:dV", "T:dT", "?:") {
                print $table.$$value{$table}."\n"if (defined $$value{$table});
            }
        }
    }
'

process_data='
    my @data; my $data = -1;
    while (<STDIN>) {
        if (/^F:(.*?)\s*\{*\s*$/) {
            $data[++$data]{file} = $1;
            $data[$data]{content} = "";
        }
        $data[$data]{content} .= $_ if ($data >= 0);
    }

    my @file; my %file;
    foreach my $data (@data) {
        my $file = $$data{file};
        if (defined $file{$file}) {
            if ($file{$file} != $$data{content}) {
                 print STDERR "\e[33;43m \e[0m $file\n";
            } else {
                 print STDERR "\e[32;42m \e[0m $file\n";
            }
        } else {
            print STDERR "\e[34;44m \e[0m $file\n";
            push @file, $file;
        }
        $file{$file} = $$data{content};
    }

    foreach my $file (@file) {
        print $file{$file};
    }
'

export_gconfig_code='

    sub fix_library {
        $_ = shift;
        '"$replace_in_library"'
        return $_;
    }

    sub fix_corner {
        $_ = shift;
        '"$replace_in_corner"'
        my @corner = split /\s+/, $_;
        my $voltages = $corner[1]; $corner[1] = "";
        while ($voltages =~ s|^([\d+p]+)v||) {
            my $voltage = $1;
            $voltage =~ s|p|.|;
            $voltage = sprintf("%5.3f", $voltage)."v";
            $voltage =~ s|\.|p|;
            $corner[1] .= $voltage;
        }
        push @corner, "*" while ($#corner < 4);
        return "* ".join(" ", @corner);
    }

    my $file = ""; my $line = 0;
    my $node = "";
    my $library = ""; my $library_length = 0;
    my $version = "";
    my $corner = ""; my @corner; my %corner; my $last_corners = -3;
    while (<STDIN>) {
        s/\s*$//; $line++;

        if (/^F:(.+?)\s*\{*\s*$/) {
            if ($last_corners == -3) {
                $last_corners = -2;
            } else {
                $last_corners = $#corner if ($last_corners == -2);
                if ($#corner == $last_corners) {
                    print STDERR "  \e[32;42m \e[0m ".($#corner+1)." corners\n";
                } else {
                    if ($#corner >= 0) {
                        print STDERR "  \e[31;41m \e[0m ".($#corner+1)." corners\n";
                    } else {
                        print STDERR "  \e[33;43m \e[0m ".($#corner+1)." corners\n";
                    }
                }
                $last_corners = $#corner if ($#corner >= 0);
            }

            $file = $1;
            # my $print_file = $1;
            $line = 0;
            $node = "";
            $library = "";
            $version = "";
            $corner = ""; @corner = (); %corner = ();
            print STDERR "\e[34;44m \e[0m $file\n";

        } elsif (/^N:(.+)$/) {
            $library = $1;
            if ($library =~ s/^([^_]+)_?BWP/BWP/i) {
                $node = $1;
            }
            $library = fix_library($library);
            $library_length = length($library) if ($library_length < length($library));

        } elsif (/^V:(.+)$/) {
            $version = $1;

        } elsif (/^C:(.+)$/) {
            $corner = fix_corner($1);
            if (!defined $corner{$corner}) {
                push @corner, $corner;
                $corner{$corner} = $#corner;
            }

        } elsif (/^T:(\w+)\s+(.+?)\s*$/) {
            my $type = $1;
            my $value = $2;
            if ($file eq "") {
                print STDERR "  \e[31;41m \e[0m Empty file, $file: $line\n";
            } elsif ($node eq "") {
                print STDERR "  \e[31;41m \e[0m Empty process node, $file: $line\n";
            } elsif ($library eq "") {
                print STDERR "  \e[31;41m \e[0m Empty library name, $file: $line\n";
            } elsif ($version eq "") {
                print STDERR "  \e[31;41m \e[0m Empty library version, $file: $line\n";
            } elsif ($corner eq "") {
                print STDERR "  \e[31;41m \e[0m Empty corner, $file: $line\n";
            } else {
                 if (defined $data{$node}{$corner}{$library}{$version}{$type}) {
                    if ($data{$node}{$corner}{$library}{$version}{$type} ne $value) {
                        print STDERR "  \e[33;43m \e[0m ".$data{$node}{$corner}{$library}{$version}{F}.": ".$type." = (".$data{$node}{$corner}{$library}{$version}{$type}.") $library\n";
                        print STDERR "  \e[33;43m \e[0m ".$file.": ".$type." = (".$value.")\n";
                    }
                 }
                 $data{$node}{$corner}{$library}{$version}{F} = $file;
                 $data{$node}{$corner}{$library}{$version}{$type} = $value;
            }
        }
    }

    if ($#corner == $last_corners) {
        print STDERR "  \e[32;42m \e[0m ".($#corner+1)." corners\n";
    } else {
        if ($#corner >= 0) {
            print STDERR "  \e[31;41m \e[0m ".($#corner+1)." corners\n";
        } else {
            print STDERR "  \e[33;43m \e[0m ".($#corner+1)." corners\n";
        }
    }
    
    foreach my $node (sort keys %data) {
        print "    # TSMC $node voltage and vemperature OCV requirements\n";
        print "    # Derate tables: <cell pattern> <voltage-drop table> <dV derate table> <dT> <reference PDF>\n";
        print "    # Views mask is {<constraint_mode> <process> <voltage> <temperature> <rc_corner> <check>}\n";
        print "    # Run ./gflow/templates/project.2025/create_tsmc_vt_tables.sh ./TSMCHOME/digital/Front_End/SBOCV/ utility to get it from PDF\n";
        print "    gconfig::add_section {\n";
        # print "        # Process node: $node\n";
        my @corners;
        foreach (sort keys %{$data{$node}}) {push @corners, $_ if (!/v.*v/)}
        foreach (sort keys %{$data{$node}}) {push @corners, $_ if (/v.*v/)}
        foreach my $corner (@corners) {

            # print "        -views {$corner} {\n";
            # print "            \$cells_IR_dV_dT_table {\n";
            print "        -views {$corner} \$cells_IR_dV_dT_table {\n";
            foreach my $library (sort keys %{$data{$node}{$corner}}) {

                my @line; my $last_IR = ""; my $last_dV = ""; my $last_dT = "";
                foreach my $version (sort keys %{$data{$node}{$corner}{$library}}) {
                    my @IR = split /\s+/, $data{$node}{$corner}{$library}{$version}{IR};
                    my @dV = split /\s+/, $data{$node}{$corner}{$library}{$version}{dV};
                    my @dT = split /\s+/, $data{$node}{$corner}{$library}{$version}{dT};

                    my $IR = join " ", @IR;
                    my $dV = join " ", @dV;
                    my $dT = join " ", @dT;

                    if ($#IR != $#dV) {
                        print STDERR "\e[31;41m \e[0m ".$data{$node}{$corner}{$library}{$version}{F}." {$corner} - IR-drop and dV table dimensions do not match\n  IR = (".$IR.") dV = (".$dV.") \n";
                    } elsif ($#dV < 0) {
                        print STDERR "\e[31;41m \e[0m ".$data{$node}{$corner}{$library}{$version}{F}." {$corner} - dV table is empty\n";
                    } elsif ($#dT < 0) {
                        print STDERR "\e[31;41m \e[0m ".$data{$node}{$corner}{$library}{$version}{F}." {$corner} - dT table is empty\n";
                    } elsif (($IR eq $last_IR) && ($IR eq $last_IR) && ($IR eq $last_IR)) {
                        $line[$#line]{F} = $data{$node}{$corner}{$library}{$version}{F};
                        $line[$#line]{V} = $version;
                    } else {
                        $line[$#line+1]{F} = $data{$node}{$corner}{$library}{$version}{F};
                        $line[$#line]{V} = $version;
                        $line[$#line]{IR} = $IR;
                        $line[$#line]{dV} = $dV;
                        $line[$#line]{dT} = $dT;
                        $last_IR = $IR;
                        $last_dV = $dV;
                        $last_dT = $dT;
                    }
                }

                foreach my $line (@line) {
                    print "# $$line{F}\n" if ($#line>1);
                    # print "                ".sprintf("%-".(10+$library_length)."s", "{ *$library").sprintf("%-45s", " {".$$line{IR}."}").sprintf("%-40s", " {".$$line{dV}."}")." {".$$line{dT}."}    {".$$line{F}."} }\n";
                    print "            ".sprintf("%-".(10+$library_length)."s", "{ *$library").sprintf("%-45s", " {".$$line{IR}."}").sprintf("%-40s", " {".$$line{dV}."}")." {".$$line{dT}."}    {".$$line{F}."} }\n";
                }
            }
            # print "            }\n";
            print "        }\n";
        }
        print "    }\n";
        print "\n\n";
    }
'

>&2 echo -e "\n\e[36;46m \e[0m Reading PDF files ..."
mkdir -p .$script_name.tmp
last_dir=""
for file in $files; do
    dir=$(dirname "$file")
    if [ "$dir" != "$last_dir" ]; then
        >&2 echo -e "\n\e[32;42m \e[0m $dir/"
        last_dir="$dir"
    fi

    name=$(basename $file)
    echo "F:$name {" >> $script_name.data
    pdftohtml $file .$script_name.tmp/$name.html > /dev/null
    cat .$script_name.tmp/${name}s.html | perl -e "$filter_html" >> $script_name.data

    >&2 echo -e "  $(echo "$file" | sed -e "s|^$last_dir/||")"
    echo "}" >> $script_name.data
done
rm -Rf .$script_name.tmp

>&2 echo -e "\n\e[36;46m \e[0m Filtering $script_name.data ...\n"
mv $script_name.data $script_name.data.bkp
cat *.data $script_name.data.bkp 2> /dev/null | perl -e "$process_data" > $script_name.data

>&2 echo -e "\n\e[36;46m \e[0m Exporting $script_name.gf ...\n"
cat $script_name.data | perl -e "$export_gconfig_code" > $script_name.gf

>&2 echo -e "\n\e[32;42m \e[0m See ./$script_name.gf"
