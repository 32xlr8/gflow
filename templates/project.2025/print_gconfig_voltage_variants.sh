#!/usr/bin/perl

################################################################################
# Generic Flow v5.5.0 (December 2024)
################################################################################
#
# Copyright 2011-2024 Gennady Kirpichev (https://github.com/32xlr8/gflow.git)
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
# Filename: templates/project.2025/print_gconfig_voltage_variants.sh
# Purpose:  Print voltage variants for gconfig
################################################################################

my %voltages = ();

sub add_voltage {
    my $value = shift;
    my $name = sprintf("%0.3f", $value); $name =~ s/\./p/; $name .= "v";
    
    my $next = sprintf("%0.4f", $value);
    my @options = ();
    while ($next =~ s/\.?0$//) {
        my $option = $next;
        push @options, $option;
        push @options, $option if ($option =~ s/\./p/);
    }
    $voltages{$name} = "        -views {* * $name * * *} {\$pvt_v {$name ".join(" ",@options)."}}";
}

sub add_voltages {
    my $value = shift;
    add_voltage(0.9*$value);
    add_voltage($value);
    add_voltage(1.1*$value);
}

add_voltage(0.5); add_voltage(0.55); add_voltage(0.6);
add_voltages(0.6);
add_voltages(0.7);
add_voltages(0.75);
add_voltages(0.8);
add_voltages(0.85);
add_voltages(0.9);
add_voltage(0.9); add_voltage(1.0); add_voltage(1.05);
add_voltages(1.0);
add_voltages(1.1);
add_voltages(1.2);
add_voltage(1.1); add_voltage(1.2); add_voltage(1.3);
add_voltages(1.4);

foreach my $name (sort keys %voltages) {
    print "$voltages{$name}\n";
}
