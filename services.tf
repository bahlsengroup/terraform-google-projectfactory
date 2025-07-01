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
  services = toset(
    distinct(
      concat(
        # 1. These base APIs are always enabled
        # projectcfg module
        [
          "cloudresourcemanager.googleapis.com",
          "serviceusage.googleapis.com",
          "iam.googleapis.com",
        ],
        # 2. All services provided by the user
        var.enabled_services
      )
    )
  )
}

resource "google_project_service" "this" {
  for_each = local.services

  project            = data.google_project.this.project_id
  service            = each.key
  disable_on_destroy = var.enabled_services_disable_on_destroy
}
