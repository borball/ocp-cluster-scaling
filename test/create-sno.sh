#!/bin/bash
#
# script to deploy a sno cluster with agent based installer
#

rm -rf sno-agent-based-installer
git clone git@github.com:borball/sno-agent-based-installer.git

cd sno-agent-based-installer

# LVM operator and MCE operator will be installed as day 1
./test-mce.sh
