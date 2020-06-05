#!/usr/bin/env raku

{
    CATCH {
        default {
            skip 'cannot trigger garbage collection';
            done-testing
            exit
        }
    }
    VM.request-garbage-collection;
}

use Test;
use Prometheus::Client :metrics;

my $THREADS = 20;
my $ROUNDS  = 2000;

{
    my $metric1;

    my $registry = METRICS {
        $metric1 = counter(
            name => 'm1',
            documentation => 'doc',
            label-names => ['label1']
        );
    };

    my @workers = (^$THREADS).map: -> $num {
        start {
            for ^$ROUNDS -> $counter {
                my $label1 = ($num + $THREADS * $counter).Str;
                $metric1.labels(:$label1).inc;
            }
        }
    };

    await @workers;
}


VM.request-garbage-collection;

pass 'no memory corruption when adding new labels';
done-testing

