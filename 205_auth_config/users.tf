data authentik_group "admins" {
  name = "authentik Admins"
}

locals {
  users_list = [
    {
      name     = "Admin"
      username = "admin"
      email    = "admin@example.com"
      groups = [
        data.authentik_group.admins.id
      ]
    },
    {
      name     = "SuperUser1"
      username = "superuser1"
      email    = "user1@example.com"
      groups = [
        data.authentik_group.admins.id
      ]
    },
    {
      name     = "User2"
      username = "user2"
      email    = "user2@example.com"
    }
  ]
}

locals {
  users = {for x in local.users_list : x.username => x}
}

resource "random_password" "user-passwords" {
  for_each = local.users
  length   = 16
}

resource "authentik_user" "users" {
  for_each = local.users
  username = each.value.username
  password = random_password.user-passwords[each.key].result
  email    = each.value.email
  name = lookup(each.value, "name", each.value.username)
  groups = lookup(each.value, "groups", [])
}

locals {
  users_with_pass = {
    for x in local.users_list : x.username => merge(x, { password = random_password.user-passwords[x.username].result })
  }
}