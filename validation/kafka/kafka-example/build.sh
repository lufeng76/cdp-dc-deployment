#!/bin/bash

set +x

source ../../common.properties

if [ $# -ne 1 ]; then
    echo "Usage: build.sh [ clean | compile | package ]"
    exit -1
fi

PATH=$JAVA_HOME/bin:$PATH

# To convert to maven pom
# sbt makePom

# clean, compile, package
sbt $1
