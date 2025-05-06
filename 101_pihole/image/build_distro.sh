#!/bin/bash
sudo -E distrobuilder build-lxc alpine.yaml
sudo chmod 666 ./*.tar.xz