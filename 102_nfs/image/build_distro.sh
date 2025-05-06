#!/bin/bash
sudo -E distrobuilder build-lxc alpine.yaml
#sudo -E distrobuilder build-lxc debian.yaml
sudo chmod 666 ./*.tar.xz