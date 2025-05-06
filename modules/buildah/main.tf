terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}

variable "dockerfile" {
  type = string
}

variable "tag" {
  type = string
}

variable "keep_locally" {
  type    = bool
  default = true
}

variable "keep_remotely" {
  type    = bool
  default = false
}

variable "triggers" {
  type = map(string)
  default = {}
}

locals {
  create_script = "${path.module}/create.sh"
  delete_script = "${path.module}/delete.sh"
}

resource "null_resource" "build_image" {
  triggers = merge(var.triggers, {
    hashes = jsonencode([
      filesha512(local.create_script),
      filesha512(var.dockerfile)
    ])
    create_script = local.create_script
    delete_script = local.delete_script
    tag           = var.tag
    keep_locally  = var.keep_locally
    keep_remotely = var.keep_remotely
  })

  provisioner "local-exec" {
    command = templatefile(abspath(local.create_script), {
      tag  = var.tag,
      keep = var.keep_locally
    })
    working_dir = dirname(var.dockerfile)
  }
  provisioner "local-exec" {
    when = destroy
    command = templatefile(abspath(self.triggers.delete_script), {
      tag  = self.triggers.tag,
      keep = self.triggers.keep_remotely
    })
  }
}

output "hash" {
  value = sha512(jsonencode(null_resource.build_image.triggers))
}

output "tag" {
  depends_on = [
    null_resource.build_image
  ]
  value = null_resource.build_image.triggers.tag
}