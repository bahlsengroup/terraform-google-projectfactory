plugin "google" {
  enabled = true
  # deep check would require credentials for pre-commit to function
  # and only provides a check for disabled APIs (yet).
  # https://github.com/terraform-linters/tflint-ruleset-google/blob/master/docs/deep_checking.md
  deep_check = false
  version = "0.39.0"  # ensure to update this to latest version
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

plugin "terraform" {
  enabled = true
  preset = "all"
}

rule "terraform_unused_declarations" {
  enabled = false
}
rule "terraform_unused_required_providers" {
  enabled = false
}
