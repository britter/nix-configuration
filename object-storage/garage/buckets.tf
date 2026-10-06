# State buckets for the other tofu projects
resource "garage_bucket" "project_state_buckets" {
  for_each     = toset(var.managed_tofu_projects)
  global_alias = "tofu-states-${each.key}"
}

# One bucket per restic service: Garage keys are bucket-scoped, so the
# minIO-style prefix isolation inside restic-backups is not reproducible.
resource "garage_bucket" "restic_buckets" {
  for_each     = toset(var.restic_backups)
  global_alias = "restic-${each.key}"
}
