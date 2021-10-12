#!/usr/bin/python3

import os
import yaml

import requests

from ansible.module_utils.basic import AnsibleModule


class ProposeModule():
    argument_spec = dict(
        repo_location=dict(type='str', required=True),
        path=dict(type='str', required=True),
        key=dict(type='str', required=True),
        value=dict(type='str', required=True),
        token=dict(type='str', required=False, no_log=True),
        username=dict(type='str', default='otcbot'),
        email=dict(
            type='str', default='otcbot@eco.tsi-dev.otc-service.com')
    )
    module_kwargs = {}

    def __init__(self):

        self.ansible = AnsibleModule(
            self.argument_spec,
            **self.module_kwargs)
        self.params = self.ansible.params
        self.module_name = self.ansible._name

    def update_yaml_value(self, yaml_data, key: str, tag_value: str):
        """
        Updates presented key value tag

        :param yaml_data: Parsed YAML file
        :param key: Indicates the key in YAML. Every level separated by dot. (some-key1.some-key2.required-key)
        :param tag_value: New value of key in YAML file
        :return: None
        """
        keys = key.split(".")
        key_to_change = yaml_data
        # Since we can have nested YAML key `some-key1.some-key2.required-key`
        # we need to go inside in order to get it.
        for k in keys[:-1]:
            key_to_change = key_to_change[k]
        # Now we need to understand if we have only new tag version
        # or we have full image url with tag in format `url:new_tag`
        if len(tag_value.split(":")) == 1:
            url = key_to_change[keys[-1]].split(":")[0]
            new_value = f"{url}:{tag_value}"
        else:
            new_value = tag_value

        key_to_change[keys[-1]] = new_value

    def get_proposal_branch_name(self, key: str, value: str):
        """
        Get proposal branch name in format `key_to_change-new version`

        :param key: Key in YAML file
        :param value: New value of the key
        :return: Proposal branch
        """
        new_value = value.split(":")
        if new_value == 0:
            return f"{key.split('.')[-1]}-{value}"
        else:
            return f"{key.split('.')[-1]}-{new_value[-1]}"

    def commit_changes(
        self, repo_location, branch_name: str, path: str,
        key: str, value: str,
        token: str
    ):
        """
        Commit a changed file in a new branch

        :param repo: Repository to make a commit
        :param branch_name: Proposal branch
        :param path: Path to a changed file
        :param key: Key name (to include in the commit message)
        :return: None
        """
        os.chdir(repo_location)
        os.system(f"git checkout -b {branch_name}")
        os.system(f"git add {path}")
        os.system(f"git commit -m 'Propose update of {key}'")
        os.system(f"git push --set-upstream origin {branch_name}")
        if token:
            response = requests.post(
                url="https://api.github.com/repos/opentelekomcloud-infra/system-config/pulls",
                headers={
                    'Authorization': f"token {token}"
                },
                json={
                    'title': f"[Automatic]: Update {key}",
                    'head': branch_name,
                    'base': 'main',
                    'maintainer_can_modify': True,
                    'body': f"Update {key} to {value}"
                }
            )
            if response.status_code >= 400:
                self.ansible.fail_json(
                    msg=f"Error during creating PR: {response.text}")


    def get_repo_and_set_config(self, username: str, email: str):
        """
        Get repository in current directory
        and fill up .gitconfig with required variables

        :param username: Git username
        :param email: Git email
        :return: repository
        """
        os.system(f"git config --global user.name {username}")
        os.system(f"git config --global user.email {email}")

    def __call__(self):
        repo_location = self.params['repo_location']
        path = self.params['path']
        key = self.params['key']
        value = self.params['value']
        username = self.params.get('username')
        email = self.params.get('email')
        token = self.params.get('token')

        with open(f"{repo_location}/{path}") as f:
             yaml_data = yaml.safe_load(f)

        self.update_yaml_value(
            yaml_data, key, value)

        with open(f"{repo_location}/{path}", "w") as f:
            yaml.safe_dump(yaml_data, f, sort_keys=False)

        if all(v is not None for v in (username, email)):
            proposal_branch = self.get_proposal_branch_name(key, value)
            repo = self.get_repo_and_set_config(username, email)
            self.commit_changes(
                repo_location, proposal_branch, path,
                key, value, token)

        self.ansible.exit_json(changed=True)


def main():
    module = ProposeModule()
    module()

if __name__ == '__main__':
    main()
