terraform {
  source = "github.com/yegorovev/tf_aws_key_pair.git"
}


locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("common.hcl")).inputs
  profile         = local.env_vars.profile
  region          = local.env_vars.region
  bucket_name     = local.env_vars.bucket_name
  lock_table      = local.env_vars.lock_table
  key             = local.env_vars.key
  tags            = jsonencode(local.env_vars.tags)
  algorithm       = try(local.env_vars.algorithm, "RSA")
  rsa_bits        = try(local.env_vars.rsa_bits, 4096)
  key_name_prefix = local.env_vars.key_name_prefix
  local_path      = try(local.env_vars.local_path, get_terragrunt_dir())
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = local.bucket_name
    key            = local.key
    region         = local.region
    encrypt        = true
    dynamodb_table = local.lock_table
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  profile = "${local.profile}"
  region  = "${local.region}"
  default_tags {
    tags = jsondecode(<<INNEREOF
${local.tags}
INNEREOF
)
  }
}
EOF
}

inputs = {
  algorithm       = local.algorithm
  rsa_bits        = local.rsa_bits
  key_name_prefix = local.key_name_prefix
  local_path      = local.local_path
}