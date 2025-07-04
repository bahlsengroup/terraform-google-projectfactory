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

locals {
  # Check if ANY given service account has a GitHub action repository configured
  github_actions_enabled = length(compact([
    for sa, config in var.service_accounts : sa if length(config.github_action_repositories) > 0
  ])) > 0 ? 1 : 0

  # We also need to enable some services to make the Workload Identity Federation setup possible
  # if we have any usage of the service
  wif_needed_services = local.github_actions_enabled > 0 ? toset([
    "cloudresourcemanager.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com"
  ]) : toset([])
}

resource "google_project_service" "wif" {
  project  = data.google_project.this.project_id
  for_each = local.wif_needed_services
  service  = each.key

  # The user may enable/use the needed services somewhere else, too!
  # Hence, we are never disabling them again, even if we initially enabled them here.
  # Keeping the service enabled is way less dangerous than disabling them, even if
  # we do not have a reason to keep them enabled any longer. Users can still disable
  # via CLI / UI if needed.
  disable_on_destroy = false
}
