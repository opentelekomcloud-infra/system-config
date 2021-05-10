#!/usr/bin/python3
import os
import sys
from argparse import ArgumentParser

import requests as requests
import yaml

github_user = os.getenv('GITHUB_USER')
github_token = os.getenv('GITHUB_TOKEN')
headers = {
    'Authorization': f'token {github_token}',
    'Accept': 'application/vnd.github.luke-cage-preview+json'
}
bad_statuses = [400, 403, 404, 422]


def read_yaml_file(path, org=None, endpoint=None, repo_name=None):
    if endpoint in ['manage_collaborators', 'branch_protection', 'options']:
        path += f'{org}/repositories/{repo_name}.yml'
    with open(path, 'r') as file:
        data = yaml.safe_load(file)
    return data


def update_options(github_api, owner, repo_name, repo):
    output = ''
    options = repo[repo_name]
    options.update({'name': repo_name})
    res = requests.patch(
        f'{github_api}/repos/{owner}/{repo_name}',
        json=options,
        headers=headers,
        timeout=15)
    if res.status_code in bad_statuses:
        output += f'options change not applied: {res.status_code}, error is: {res.text}\n'
    return print(output, file=sys.stderr)


def manage_collaborators(github_api, owner, repo_name, repo):
    output = ''
    collaborators = repo[repo_name]['collaborators']
    teams = repo[repo_name]['teams']
    for permission, users in collaborators.items():
        if not users:
            continue
        for user in users:
            res = requests.put(
                f'{github_api}/repos/{owner}/{repo_name}/collaborators/{user}',
                json={'permission': permission},
                headers=headers,
                timeout=15)
            if res.status_code in bad_statuses:
                output += f'user {user} not created: {res.status_code}, error is: {res.text}\n'
    for permission, teams in teams.items():
        if not teams:
            continue
        for team in teams:
            res = requests.put(
                f'{github_api}/orgs/{owner}/teams/{team}/repos/{owner}/{repo_name}',
                json={'permission': permission},
                headers=headers,
                timeout=15)
            if res.status_code in bad_statuses:
                output += f'repo not added to team: {team}: {res.status_code}, error is: {res.text}\n'
    return print(output, file=sys.stderr)


def update_branch_protection(github_api, owner, repo_name, repo):
    output = ''
    rules = repo[repo_name]['protection_rules']
    if isinstance(rules, str):
        rules = {repo[repo_name]['default_branch']:
                 read_yaml_file(f'/home/zuul/src/github.com/opentelekomcloud-infra/system-config/playbooks/templates/github/{rules}.yaml')}
    branch_name = list(rules)[0]
    if 'who_can_push' in rules[branch_name]:
        rules[branch_name]['restrictions'] = rules[branch_name].pop('who_can_push')
    res = requests.put(
        f'{github_api}/repos/{owner}/{repo_name}/branches/{branch_name}/protection',
        json=rules[branch_name],
        headers=headers,
        timeout=15)
    if res.status_code in bad_statuses:
        output += f'branch protection rule not applied: {res.status_code}, error is: {res.text}\n'
    return print(output, file=sys.stderr)


if __name__ == '__main__':
    args_parser = ArgumentParser(prog='github_api', description='Multi-purpose github api script')
    args_parser.add_argument('--github_api_url', help='Github api base path', default='https://api.github.com')
    args_parser.add_argument('--endpoint', help='Selected github endpoint')
    args_parser.add_argument('--org', help='Repo owner')
    args_parser.add_argument('--repo', help='Repo data')
    args_parser.add_argument('--root', help='Root directory to fetch files', default='/home/zuul/src/github.com/opentelekomcloud-infra/gitstyring/orgs/')
    args = args_parser.parse_args()
    if args.endpoint == 'manage_collaborators':
        manage_collaborators(
            github_api=args.github_api_url,
            owner=args.org,
            repo_name=args.repo,
            repo=read_yaml_file(path=args.root, org=args.org, repo_name=args.repo, endpoint=args.endpoint)
        )
    if args.endpoint == 'branch_protection':
        update_branch_protection(
            github_api=args.github_api_url,
            owner=args.org,
            repo_name=args.repo,
            repo=read_yaml_file(path=args.root, org=args.org, repo_name=args.repo, endpoint=args.endpoint)
        )
    if args.endpoint == 'options':
        update_options(
            github_api=args.github_api_url,
            owner=args.org,
            repo_name=args.repo,
            repo=read_yaml_file(path=args.root, org=args.org, repo_name=args.repo, endpoint=args.endpoint)
        )
