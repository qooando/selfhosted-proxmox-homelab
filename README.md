# Selfhosted proxmox home lab

This is a repository with some useful configuration to put up a simple
selfhosted homelab.

> This is a personal project, I will only add software I personally used and tested, but feel free to comment.
> Maybe some manual tweaks are required.

# Setup

1. Install proxmox on a local server

We assume to have an empty proxmox installation on a local machine, e.g. a minipc.
I use a minipc with 16GB RAM and 500GB disk.

The repository is split in different folders,
each folder is a terraform module for a specific thing to install.

Modules should be applied in order.

Each module self contains its own configurations and outputs
artifacts to `build/` directory where other modules can read them.

## Initialization

This module creates a default ca certificate for the cluster
and exports some default values to `homelab.vars.yaml`

Check `input.tf` for default values, you can change them to your will (
see: https://developer.hashicorp.com/terraform/language/values/variables)

```bash
cd 000_init
terraform init
terraform apply
```

## Pi-hole

In order to resolve custom dns for the homelab, the first thing after
the certificate is to install pihole.

This module prepares an alpine lxc image and runs it in a container on proxmox.

```bash
cd 001_pihole
cd images
bash build_distro.sh
cd ..
terraform init
terraform apply
```

Output artifacts include `pihole.vars.yaml` and pihole certificates used for the public interface.
After installation you can access pihole gui at `https://pihole.homelab.local`

### Customize pihole

I use a custom alpine image built with `distrobuild`.
You can customize the default image in `001_pihole/image` and build it again.

Furthermore, you can update configuration using terraform,
edit it in `001_pihole/configs/pihole.toml`, then reapply terraform.

## NFS

This modules creates a nfs share we will use later for kubernetes volumes.

```bash
cd 002_nfs
cd images
bash build_distro.sh
cd ..
terraform init
terraform apply
```

## Docker

This modules initialize a docker registry.

You need to customize docker configuration in `003_docker_registry/configs/config.yaml`
and substitute the following lines

```yaml
proxy:
  remote-url: "https://index.docker.io/v1"
  username: "MISSING_USERNAME"
  password: "MISSING_PASSWORD"
```

with your login data.

Then you can create the image and apply terraform.

```bash
cd 003_docker_registry
cd images
bash build_distro.sh
cd ..
terraform init
terraform apply
```

