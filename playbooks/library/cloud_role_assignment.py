#!/usr/bin/python
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

DOCUMENTATION = '''
module: cloud_role_assignment
extends_documentation_fragment: opentelekomcloud.cloud.otc
description:
  - Batch role group project assignment
options:
  role:
    description: Role name
    type: str
    required: true
  projects:
    description: List of project names
    type: list
    elements: str
  groups:
    description: List of group names
    type: list
    elements: str
  state:
    description: Assignment state
    type: str
    choice: [present, absent]
    default: present
'''

RETURN = '''
'''

EXAMPLES = '''
'''

import itertools

from ansible_collections.opentelekomcloud.cloud.plugins.module_utils.otc import OTCModule


class CloudRoleAssignmentModule(OTCModule):
    argument_spec = dict(
        role=dict(required=True, type='str'),
        projects=dict(required=True, type='list', elements='str'),
        groups=dict(required=False, type='list', elements='str'),
        state=dict(type=str, choice=['present', 'absent'], default='present')
    )

    module_kwargs = dict(
        supports_check_mode=True
    )

    def run(self):
        role = self.conn.identity.find_role(name_or_id=self.params['role'])
        groups = {}
        projects = {}
        changed = False

        for group in self.params['groups']:
            grp = self.conn.identity.find_group(
                name_or_id=group
            )
            groups[grp.name] = grp.id

        for project in self.params['projects']:
            prj = self.conn.identity.find_project(
                name_or_id=project
            )
            projects[prj.name] = prj.id

        for pair in list(itertools.product(groups, projects)):
            res = self.conn.identity.validate_group_has_role(
                projects[pair[1]], groups[pair[0]], role)
            if self.params['state'] == 'present':
                if not res:
                    changed = True
                    if not self.ansible.check_mode:
                        self.conn.identity.assign_project_role_to_group(
                            projects[pair[1]],
                            groups[pair[0]],
                            role)
            else:
                if res:
                    changed = False
                    if not self.ansible.check_mode:
                        self.conn.identity.unassign_project_role_from_group(
                            projects[pair[1]],
                            groups[pair[0]],
                            role)

        self.exit_json(
            changed=changed,
            role=role.to_dict(),
            groups=groups,
            projects=projects
        )


def main():
    module = CloudRoleAssignmentModule()
    module()


if __name__ == '__main__':
    main()
