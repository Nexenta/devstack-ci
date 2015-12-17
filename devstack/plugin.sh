#!/bin/bash

if [[ "$1" == "stack" && "$2" == "install" ]]; then
    cd /home/ubuntu
    git clone -b $NS_CINDER_BRANCH https://github.com/Nexenta/cinder.git
    cp -r cinder/cinder/volume/drivers/nexenta /opt/stack/cinder/cinder/volume/drivers
    cp cinder/cinder/exception.py /opt/stack/cinder/cinder/
    cp cinder/cinder/opts.py /opt/stack/cinder/cinder/
fi
