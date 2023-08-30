#!/bin/bash
#
# script to deploy a campact cluster with agent based installer

rm -rf mno-with-abi
git clone git@github.com:borball/mno-with-abi.git

cd mno-with-abi

./test-compact.sh


