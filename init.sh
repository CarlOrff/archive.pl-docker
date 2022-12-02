#!/bin/bash

# Services get stopped after build.
/etc/init.d/tor start
xvfb-run firefox &

#systemctl --type=service
netstat -natup

perl archive.pl -v
perl archive.pl -h



