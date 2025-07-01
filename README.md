# Bahlsen Project Factory Module

[FAQ] | [CONTRIBUTING] | [CHANGELOG]

This module allows you to configure a Google Cloud Platform project. It aims to
provide reasonable defaults for Workload Identity Federation Pools (for
authentication from GitHub actions) and provides a centralized management for
service accounts and the project-level IAM policy.

> [!NOTE]
> This module is a copy from v3 of
> [METRO's mdoule](https://github.com/metro-digital/terraform-google-cf-projectcfg).
> It has a reduced feature set to better fit our requirements.

<!-- mdformat-toc start --slug=github --no-anchors --maxlevel=6 --minlevel=2 -->

- [Getting Started](#getting-started)
- [Usage](#usage)
- [Features](#features)
  - [IAM](#iam)
- [License](#license)

<!-- mdformat-toc end -->

## Getting Started

The easiest way to get started is to use the module's bootstrapping
functionality. Bootstrapping a project leverages the Google principal you are
locally authenticated as to provision the minimum amount of resources required
for Terraform to take over the project's management and generate Terraform code
which you can use as the basis for all further project management.

To find out how to bootstrap a project, check out the dedicated
[bootstrapping documentation][bootstrap].

## Usage

```hcl
module "projectcfg" {
  source  = "bahlsengroup/projectfactory/google"
  version = "~> 0.1"

  project_id = "some-example-project"
}
```

> [!TIP]
> A detailed description of input variables and output values can be found
> [here](./docs/TERRAFORM.md).

See the [FAQ] for simple examples of using Workload Identity Federation with
GitHub and other tools.

## Features

### IAM

This module acts authoritative on the project IAM policy. It aims to configure
the project-level IAM policy and service account (including the IAM policy on
the service account itself) related resources in a central place for easy review
and adjustments. All active roles are fetched initially and compared with the
roles given via roles input.

All roles [listed for service agents][service agent roles] (like for example
`roles/dataproc.serviceAgent`) are ignored, so if a service gets enabled the
default permissions granted automatically by Google Cloud Platform to the
related service accounts will stay in place. Those excludes are configured in
[project-iam.tf](./project-iam.tf) - look for a local variable called
`project_iam_non_authoritative_roles`.

## License

This project is licensed under the terms of the [Apache License 2.0](LICENSE)

This [terraform] module depends on providers from HashiCorp, Inc. which are
licensed under MPL-2.0. You can obtain the respective source code for these
providers here:

- [`hashicorp/google`](https://github.com/hashicorp/terraform-provider-google)
- [`hashicorp/external`](https://github.com/hashicorp/terraform-provider-external)

This [terraform] module uses pre-commit hooks which are licensed under MPL-2.0.
You can obtain the respective source code here:

- [`terraform-linters/tflint`](https://github.com/terraform-linters/tflint)
- [`terraform-linters/tflint-ruleset-google`](https://github.com/terraform-linters/tflint-ruleset-google)

[bootstrap]: ./bootstrap/README.md
[changelog]: ./docs/CHANGELOG.md
[contributing]: docs/CONTRIBUTING.md
[faq]: ./docs/FAQ.md
[service agent roles]: https://cloud.google.com/iam/docs/service-agents
[terraform]: https://terraform.io/
