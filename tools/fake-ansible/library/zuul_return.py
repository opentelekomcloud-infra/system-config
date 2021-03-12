# This is a fake zuul_return to make ansible-lint happy
from ansible.module_utils.basic import AnsibleModule

def main():
    module = AnsibleModule(
        argument_spec=dict(
            data=dict(default=None),
            path=dict(default=None, type=str),
            file=dict(default=None, type=str),
        )
    )
