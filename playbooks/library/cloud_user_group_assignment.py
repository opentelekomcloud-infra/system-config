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
module: cloud_user_group_assignment
extends_documentation_fragment: opentelekomcloud.cloud.otc
description:
  - Batch user group assignment
options:
  group:
    description: Group name
    type: str
    required: true
  users:
    description: List of user names
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


class CloudUserGroupAssignmentModule(OTCModule):
    argument_spec = dict(
        group=dict(required=True, type='str'),
        users=dict(required=True, type='list', elements='str'),
        state=dict(type=str, choice=['present', 'absent'], default='present')
    )

    module_kwargs = dict(
        supports_check_mode=True
    )

    def run(self):
        group = self.conn.identity.find_group(name_or_id=self.params['group'])
        changed = False

        for user in self.params['users']:
            usr = self.conn.identity.find_user(
                name_or_id=user
            )
            is_in = self.conn.is_user_in_group(usr.id, group)
            if self.params['state'] == 'present':
                if not is_in:
                    changed=True
                    if self.ansible.check_mode:
                        self.conn.add_user_to_group(usr.id, group.id)
            else:
                if is_in:
                    changed=True
                    if self.ansible.check_mode:
                        self.conn.remove_user_from_group(usr.id, group.id)

        self.exit_json(
            changed=changed
        )


def main():
    module = CloudUserGroupAssignmentModule()
    module()


if __name__ == '__main__':
    main()
