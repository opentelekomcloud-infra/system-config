import argparse
import sys

import yaml


def main():
    parser = argparse.ArgumentParser(prog="propose-pr", description="Propose PR to a GitHub")
    parser.add_argument("--path", type=str, help="Vars file path", required=True)
    parser.add_argument("--key", type=str, help="Key to change", required=True)
    parser.add_argument("--value", type=str, help="New value of the key", required=True)
    args = parser.parse_args()

    with open(args.path) as f:
        yaml_data = yaml.safe_load(f)

    update_yaml_value(yaml_data, args.key, args.value)

    with open(args.path, "w") as f:
        yaml.safe_dump(yaml_data, f)


def update_yaml_value(yaml_data, key: str, tag_value: str):
    keys = key.split(".")
    accessible = yaml_data
    for k in keys[:-1]:
        accessible = accessible[k]
    url_tag = accessible[keys[-1]].split(":")
    accessible[keys[-1]] = "{url}:{tag}".format(url=url_tag[0], tag=tag_value)


if __name__ == "__main__":
    sys.exit(main())
