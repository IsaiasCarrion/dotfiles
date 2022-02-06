#!/usr/bin/env bash
set -e

patching(){
    sudo apt-get update -y;
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y;
};

patching;
