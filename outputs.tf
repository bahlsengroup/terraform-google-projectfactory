# Copyright 2025 Bahlsen GmbH & Co. KG
# Copyright 2025 METRO Digital GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

output "project_id" {
  description = "GCP project ID"
  value       = data.google_project.this.project_id
}

output "service_accounts" {
  description = <<-EOD
    **Map of created service accounts and their attributes.**

    ```
    Key:   Same key as given for the `service_accounts` input variable.
    Value: Attributes of the managed service accounts.

      email:     The e-mail address of the service account.
      id:        An identifier for the resource in the format `projects/{{project}}/serviceAccounts/{{email}}`.
      member:    The identity of the service account in the form `serviceAccount:{email}`.
                 This value is often used to refer to the service account when granting IAM permissions.
      unique_id: The unique ID of the service account.
    ```
  EOD
  value = {
    for name, data in google_service_account.service_accounts : name => {
      email     = data.email
      id        = data.id
      member    = data.member
      unique_id = data.unique_id
    }
  }
}

output "custom_roles" {
  description = <<-EOD
    **Map of created custom roles and their attributes.**

    ```
    Key:   Same key as given for the `custom_roles` input variable.
    Value: Attributes of the managed custom roles.

      id:    An identifier for the resource in the format `projects/{{project}}/roles/{{role_id}}`.
      stage: The current launch stage of the role.
    ```
  EOD
  value = {
    for name, data in google_project_iam_custom_role.custom_roles : name => {
      id    = data.id
      stage = data.stage
    }
  }
}
