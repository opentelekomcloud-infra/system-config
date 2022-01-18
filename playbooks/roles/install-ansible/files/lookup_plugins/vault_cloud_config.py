# GNU General Public License v3.0+ (see COPYING.GPL or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = """
  lookup: vault_cloud_config
  short_description: Get cloud config
  extends_documentation_fragment:
    - community.hashi_vault.connection
    - community.hashi_vault.connection.plugins
    - community.hashi_vault.auth
    - community.hashi_vault.auth.plugins
  options:
    user_path:
      description: Path to the user name
      required: True
    project_name:
      description: Cloud project name to use
    project_id:
      description: Cloud project id to use
    domain_id:
      description: Cloud domain id to use
    domain_name:
      description: Cloud domain name to use
    _terms:
      description: |
        Additional options to be set on the cloud config (root level).
      type: str
"""

from ansible.errors import AnsibleError
from ansible.utils.display import Display

from ansible_collections.community.hashi_vault.plugins.plugin_utils._hashi_vault_lookup_base import HashiVaultLookupBase
from ansible_collections.community.hashi_vault.plugins.module_utils._hashi_vault_common import HashiVaultValueError

display = Display()

HAS_HVAC = False
try:
    import hvac
    HAS_HVAC = True
except ImportError:
    HAS_HVAC = False


class LookupModule(HashiVaultLookupBase):
    def run(self, terms, variables=None, **kwargs):
        if not HAS_HVAC:
            raise AnsibleError("Please pip install hvac to use the vault_read lookup.")

        ret = []

        self.set_options(direct=kwargs, var_options=variables)
        self.process_deprecations()

        self.connection_options.process_connection_options()
        client_args = self.connection_options.get_hvac_connection_options()
        client = self.helper.get_vault_client(**client_args)

        try:
            self.authenticator.validate()
            self.authenticator.authenticate(client)
        except (NotImplementedError, HashiVaultValueError) as e:
            raise AnsibleError(e)

        user_path = self.get_option('user_path')
        auth_attrs = ['auth_url', 'user_domain_id', 'user_domain_name',
                      'username', 'password', 'token']
        cloud_config = {'auth': {}}
        user_data = None
        try:
            data = client.read(user_path)
            try:
                # sentinel field checks
                check_dd = data['data']['data']
                check_md = data['data']['metadata']
                # unwrap nested data
                auth = data['data']['data']
                for k, v in auth.items():
                    # We want only supported keys to remain under auth. All
                    # rest are placed as root props
                    if k in auth_attrs:
                        cloud_config['auth'][k] = v
                    else:
                        cloud_config[k] = v
            except KeyError:
                pass
        except hvac.exceptions.Forbidden:
           raise AnsibleError(
               "Forbidden: Permission Denied to path '%s'."
               % user_path)

        # We allow asking for specific project/domain
        for opt in ['domain_id', 'domain_name', 'project_name', 'project_id']:
            opt_val = self.get_option(opt)
            if opt_val:
                cloud_config['auth'][opt] = opt_val
        # Add all other options passed as terms
        for term in terms:
            try:
                dt = term.split('=')
                cloud_config[dt[0]] = dt[1]
            except IndexError:
                pass

        ret.append(cloud_config)

        return ret
