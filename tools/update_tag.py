import argparse
import os
import sys

import yaml
from git import Repo


def main():
    parser = argparse.ArgumentParser(prog="update-tag", description="Simple script for updating a tag in YAML")
    parser.add_argument("--path",
                        type=str,
                        help="Path to yaml file should be changed",
                        required=True)
    parser.add_argument("--key",
                        type=str,
                        help="Which key should be updated, every level separated with dot `.`",
                        required=True)
    parser.add_argument("--value",
                        type=str,
                        help="New tag value of image",
                        required=True)
    parser.add_argument("--token",
                        type=str,
                        help="Auth token")
    args = parser.parse_args()

    with open(args.path) as f:
        yaml_data = yaml.safe_load(f)

    update_yaml_value(yaml_data, args.key, args.value)

    with open(args.path, "w") as f:
        yaml.safe_dump(yaml_data, f)

    if args.token is not None:
        proposal_branch = get_proposal_branch_name(args.key, args.value)
        commit_changes(proposal_branch, args.path)


def get_proposal_branch_name(key: str, value: str):
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


def update_yaml_value(yaml_data, key: str, tag_value: str):
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
    if len(tag_value.split(":")) == 2:
        url = key_to_change[keys[-1]].split(":")[0]
        new_value = f"{url}:{tag_value}"
    else:
        new_value = tag_value

    key_to_change[keys[-1]] = new_value


def commit_changes(branch_name: str, path: str):
    """
    Commit a changed file in a new branch

    :param branch_name: Proposal branch
    :param path: Path to a changed file
    :return: None
    """
    repo = Repo(os.getcwd())
    repo.git.checkout("-b", branch_name)
    repo.index.add([path])
    repo.index.commit(f"Update {branch_name} version in `{path}`")


if __name__ == "__main__":
    sys.exit(main())
