terraform {
  source = "github.com/yegorovev/tf_aws_key_pair.git"
}


locals {
  common  = read_terragrunt_config(find_in_parent_folders("common.hcl")).inputs.common
  env     = local.common.env
  profile = local.common.profile
  region  = local.common.region

  common_tags = jsonencode(local.common.tags)

  kp                         = read_terragrunt_config(find_in_parent_folders("common.hcl")).inputs.key_pair
  kp_lock_table_remote_state = local.kp.kp_lock_table_remote_state
  kp_key_remote_state        = local.kp.kp_key_remote_state
  kp_backet_remote_state     = local.kp.kp_backet_remote_state
  algorithm                  = try(local.kp.algorithm, "RSA")
  rsa_bits                   = try(local.kp.rsa_bits, 4096)
  key_name_prefix            = local.kp.key_name_prefix
  local_path                 = try(local.kp.local_path, get_terragrunt_dir())
  tags                       = local.kp.tags
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = local.kp_backet_remote_state
    key            = local.kp_key_remote_state
    region         = local.region
    encrypt        = true
    dynamodb_table = local.kp_lock_table_remote_state
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
${local.common_tags}
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
  tags            = local.tags
}