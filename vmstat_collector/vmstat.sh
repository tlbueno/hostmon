#!/usr/bin/env bash

sample=10 # in seconds
hostname="$(hostname -s)"

/usr/bin/vmstat 1 "$sample" | tail -"$sample" | sed -e 's/^ *//' | sed -e 's/   / /g;s/  / /g;s/  / /g' | sed -e 's/ /,/g' | perl -e '
    use strict;
    use warnings;
    use Data::Dumper;

    my @fields = qw ( r b swpd free buff cache si so bi bo in cs us sy id wa st );
    my $hostname = "'"$hostname"'";

    my $fields = {
        r => { name=> "running_queue", help => "The number of processes in a running state." },
        b => { name=> "wait_queue", help => "The number of processes in uninterruptible sleep state." },
        swpd => { name=> "virtual_memory", help => "the amount of virtual memory used." },
        free => { name=> "idle_memory", help => "the amount of idle memory." },
        buff => { name=> "buffer_memory", help => "the amount of memory used as buffers." },
        cache => { name=> "cached_memory", help => "the amount of memory used as cache." },
        si => { name=> "swap_in", help => "Amount of memory swapped in from disk (/s)." },
        so => { name=> "swap_out", help => "Amount of memory swapped to disk (/s)." },
        bi => { name=> "blocks_in", help => "Blocks received from a block device (blocks/s)." },
        bo => { name=> "blocks_out", help => "Blocks sent to a block device (blocks/s)." },
        in => { name=> "interrupts", help => "The number of interrupts per second, including the clock." },
        cs => { name=> "context_switches", help => "The number of context switches per second." }, 
        us => { name=> "usr_cpu", help => "User CPU time." },
        sy => { name=> "sys_cpu", help => "System CPU time." },
        id => { name=> "idle_cpu", help => "Time spent idle" },
        wa => { name=> "waiting_io", help => "Time spent waiting for I/O" },
        st => { name=> "time_stolen_from_vm", help => "Time stolen from a virtual machine" }
    };

    my $cons = {};
     
    while (<STDIN>){ chomp;
        my @input = split /,/;
        my $data = {};

        $data->{$_} = shift @input for @fields;

        for my $field (@fields){
            $cons->{$field}->{tot}++;
            $cons->{$field}->{sum}+=$data->{$field};
        }
    }

    for my $field (sort keys %$cons) {
        my $total = $cons->{$field}->{tot};
        my $value   = $cons->{$field}->{sum} / $total if $total;

        my $name = $fields->{$field}->{name};
        my $help = $fields->{$field}->{help};
        my $type = "gauge";
        my $key = "host=\"$hostname\"";

        getHeader("vmstat_$name", $type, $help);
        writeMetric("vmstat_$name",$key,$value);
    }

    sub getHeader {
        my ($name, $type, $help) = @_; 
        print <<EOF;
# HELP $name $help
# TYPE $name $type
EOF
    }

    sub writeMetric {
        my ($name, $key, $value) = @_; 
        printf "${name}{$key} $value\n";
    }
'
