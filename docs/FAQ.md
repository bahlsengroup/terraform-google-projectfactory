# Frequently Asked Questions

# TODO: check and update

<!-- mdformat-toc start --slug=github --no-anchors --maxlevel=6 --minlevel=2 -->

- [Versioning](#versioning)
- [Terraform](#terraform)
  - [How to Prepare a New Generated Project for This Module?](#how-to-prepare-a-new-generated-project-for-this-module)
- [IAM](#iam)
  - [How to Import Existing IAM Policy](#how-to-import-existing-iam-policy)
  - [How to Grant Project Level Permissions to a Service Account](#how-to-grant-project-level-permissions-to-a-service-account)
  - [How Can I Allow Service Account Impersonation?](#how-can-i-allow-service-account-impersonation)
- [GitHub](#github)
  - [How to Use Workload Identity Federation With GitHub Actions](#how-to-use-workload-identity-federation-with-github-actions)
  - [`Error creating WorkloadIdentityPool - Error 403: Permission 'iam.workloadIdentityPools.create' denied on resource`](#error-creating-workloadidentitypool---error-403-permission-iamworkloadidentitypoolscreate-denied-on-resource)
  - [`Error creating WorkloadIdentityPool - Error 409: Requested entity already exists`](#error-creating-workloadidentitypool---error-409-requested-entity-already-exists)

<!-- mdformat-toc end -->

## Versioning

The module implements [Semantic Versioning], means non-breaking feature me be
added within the major release, but any breaking change will cause a new major
version.

> [!TIP]
> We clearly recommend to limit potential automatic updates of the module to the
> current major version you are using.

Assuming you are using the `v3` major version, you should dome something like
this:

```hcl
module "projectcfg" {
  source      = "bahlsengroup/projectfactory/google"
  version     = "~> 3.0"
  project_id  = "some-example-project"
}
```

Assuming a new, non-breaking feature was added in `v3.1.0` you are using, your
constraint should like this:

```hcl
module "projectcfg" {
  source      = "bahlsengroup/projectfactory/google"
  version     = "~> 3.1"
  project_id  = "some-example-project"
}
```

## Terraform

### How to Prepare a New Generated Project for This Module?

See our [bootstrap](../bootstrap/README.md)

## IAM

### How to Import Existing IAM Policy

If you want to manage an already existing project, this project very likely
already has some (more or less) complex IAM policy bound to it. To simplify the
migration towards our project, you can import the existing policy into your
terraform state before applying, this will result in terraform showing you all
the changes it would do to this policy. If you don't import the policy terraform
threads, the policy as non-existing and overwrites it without showing you the
differences.

**Option 1:** Import via command line:

```shell
terraform import 'module.project_factory.google_project_iam_policy.this' <your_project_id>
```

**Option 2:** Import block in terraform code

```hcl
import {
  to = module.project_factory.google_project_iam_policy.this
  id = "<your_project_id>"
}
```

### How to Grant Project Level Permissions to a Service Account

You can grant project level permissions to a service account using the
`project_iam_policy_roles` input

```hcl
module "project_factory" {
  source     = "bahlsengroup/projectfactory/google"
  project_id = "some-example-project"

  # Create a service account
  service_accounts = {
    bq-reader = {
      display_name = "BigQuery Reader"
      iam_policy          = [] # see comment below!
      # Grant this service account the BigQuery user role on project level.
      project_iam_policy_roles = [
        "roles/bigquery.user"
      ]
    }
    # ...
  }
  # ...
}
```

Please note the empty `iam_policy` parameter inside the service account
definition. This is used for IAM rules applied to the service account as a
resource. See
[How can I allow Service Account impersonation?](#how-can-i-allow-service-account-impersonation)
or
[Can I use GKE Workload Identify with this module?](#can-i-use-gke-workload-identify-with-this-module)
how to use this.

### How Can I Allow Service Account Impersonation?

You can grant some other member permissions to impersonate a specific service
account by granting the role `roles/iam.serviceAccountTokenCreator`.

This role can be granted on

- project level IAM policy
- resource level IAM policy

> [!TIP]
> Resource level IAM policy means the IAM policy assigned to a specific service
> account, considering the service account as a resource. **It's recommended to
> grant the role on resource level** to ensure the given member can only
> impersonate specific service accounts. Granting it on project level will allow
> the member to impersonate all service accounts within the project!

```hcl
module "project_factory" {
  source     = "bahlsengroup/projectfactory/google"
  project_id = "some-example-project"

  # Create a service account and allow a K8S SA to use it for WorkLoad Identity
  service_accounts = {
    # ...
    some-sa = {
      display_name = "Some example service account"
      iam_policy   = [
        {
          role    = "roles/iam.serviceAccountTokenCreator"
          members = [
            "group:example-group@metronom.com"
          ]
        }
      ]
    }
    # ...
  }

  # ...
}
```

## GitHub

### How to Use Workload Identity Federation With GitHub Actions

The module allows you to configure the authentication within GitHub actions
using Workload Identity Federation. To allow the use of a service account within
a GitHub workflow run, you need to set the repository as a parameter for the
service account:

```hcl
module "project_factory" {
  source     = "bahlsengroup/projectfactory/google"
  project_id = "some-example-project"

  # Create a service account and allow a GitHub actions to use
  # it via WorkLoad Identity Federation
  service_accounts = {
    # ...
    terraform-iac-pipeline = {
      display_name               = "Service account used in IaC pipelines"
      iam_policy                 = {}
      github_action_repositories = [
        "bahlsengroup/<your repository>"
      ]
    }
  }
}
```

**Remark:** You need to grant the role `roles/iam.workloadIdentityPoolAdmin` to
the principal that is executing the terraform code (most likely your service
account used in your pipeline) if you plan to use `github_action_repositories`.

Setting the `github_action_repositories` parameter will create a default
Workload Identity Pool named "github-actions" and a Workload Identity Pool
provider, named "GitHub". This is reflected in the code snippet below under
`workload_identity_provider`. You need to set the `permissions` block to grant
your id-token the intended permissions. After that, you can use this
[GitHub action](https://github.com/google-github-actions/auth) to authenticate
inside your flow:

```yaml
jobs:
  terraform:
    name: terraform
    runs-on: ubuntu-latest

    defaults:
      run:
        shell: bash
        working-directory: dev

    permissions:
      contents: 'read'
      id-token: 'write'

    steps:
      # ...
      - id: 'auth'
        name: 'Authenticate to Google Cloud'
        # Make sure to reference the most recent commit!
        uses: 'google-github-actions/auth@v0'
        with:
          workload_identity_provider: 'projects/<project number>/locations/global/workloadIdentityPools/github-actions/providers/github'
          service_account: 'terraform-iac-pipeline@some-example-project.iam.gserviceaccount.com'
      # ...
```

### `Error creating WorkloadIdentityPool - Error 403: Permission 'iam.workloadIdentityPools.create' denied on resource`

If you are facing an error similar to this:

```
Error creating WorkloadIdentityPool: googleapi: Error 403: Permission 'iam.workloadIdentityPools.create' denied on resource '//iam.googleapis.com/projects/<GCP PROJECT>/locations/global' (or it may not exist).
```

You may need to grant `roles/iam.workloadIdentityPoolAdmin` to your service
account. This is also the case if you grant the role via this module; even if
the pool itself has some dependency on the IAM permission, terraform may not
wait long enough. Please be aware Google Cloud Platform may need a few minutes
to pick up this IAM change; if you still see the error after granting the role,
please wait a few minutes and try again. If the error persists, feel free to
reach out to the Cloud Foundation team if needed.

### `Error creating WorkloadIdentityPool - Error 409: Requested entity already exists`

This usually happens if you created the pool via terraform and destroyed it
again. To solve the issue you need to:

1. Grant yourself `roles/iam.workloadIdentityPoolAdmin` on the project, and
   navigate to [workload identity pools].
1. Enable `Show deleted pools and providers`
1. Restore the pool with ID `github-actions`
1. Restore the pool provider with ID `github`

After you restore your pool and provider, you need to import them into your
terraform state:

```shell
export GCP_PROJECT_ID="<YOUR GOOGLE PROJECT ID>"
terraform import 'module.project_factory.google_iam_workload_identity_pool.github-actions[0]' $GCP_PROJECT_ID/github-actions
terraform import 'module.project_factory.google_iam_workload_identity_pool_provider.github[0]' $GCP_PROJECT_ID/github-actions/github
```

[semantic versioning]: https://semver.org/
[workload identity pools]: https://console.cloud.google.com/iam-admin/workload-identity-pools
