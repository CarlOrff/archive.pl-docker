#!/bin/bash

# Services get stopped after build.
/etc/init.d/tor start
xvfb-run firefox &

#systemctl --type=service
netstat -natup

perl -le 'eval "require $ARGV[0]" and print "LWP " . $ARGV[0]->VERSION' LWP
perl proxytest.pl

perl archive.pl -v
perl archive.pl -h


