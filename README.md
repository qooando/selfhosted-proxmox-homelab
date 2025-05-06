# Selfhosted proxmox home lab

This is a repository with some useful configuration to put up a simple
selfhosted homelab.

> This is a personal project, I will only add software I personally used and tested, but feel free to comment.
> Maybe some manual tweaks are required.

## Setup

1. Install proxmox on a local server

We assume to have an empty proxmox installation on a local machine, e.g. a minipc.
I use a minipc with 16GB RAM and 500GB disk.

The repository is split in different folders,
each folder is a terraform module for a specific thing to install.

Modules should be applied in order.

Each module self contains its own configurations and outputs
artifacts to `build/` directory where other modules can read them.

### Initialization

This module creates a default ca certificate for the cluster
and exports some default values `homelab.vars.yaml`

```
cd 000_init
terraform apply
```


