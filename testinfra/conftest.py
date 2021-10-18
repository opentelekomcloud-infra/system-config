import os
import pytest
import yaml

@pytest.fixture
def zuul_data():

    data = {}

    with open('/home/zuul/src/github.com/opentelekomcloud-infra/system-config/inventory/base/gate-hosts.yaml') as f:
        inventory = yaml.safe_load(f)
        data['inventory'] = inventory

    zuul_extra_data_file = os.environ.get('TESTINFRA_EXTRA_DATA')
    if os.path.exists(zuul_extra_data_file):
        with open(zuul_extra_data_file, 'r') as f:
            extra = yaml.safe_load(f)
            data['extra'] = extra

    return data
