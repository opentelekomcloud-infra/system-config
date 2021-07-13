# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import sys
import warnings

# -- General configuration ----------------------------------------------------
# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
sys.path.insert(0, os.path.abspath('.'))

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom ones.
extensions = [
    'custom_roles',
    'zuul_sphinx'
]

# We have roles split between zuul-suitable roles at top level roles/*
# (automatically detected by zuul-sphinx) and playbook-specific roles
# (might have plugins, etc that make them unsuitable as potential zuul
# roles).  Document both.
zuul_role_paths = ['playbooks/roles']

# The suffix of source filenames.
source_suffix = '.rst'

# The master toctree document.
master_doc = 'index'

# General information about the project.
project = u'Open Telekom Cloud Ecosystem Infra'
copyright = u'2021, Various members of the OpenTelekomCloud'

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'sphinx'

# Locations to exclude when looking for source files.
exclude_patterns = ['_build']

# -- Options for HTML output ----------------------------------------------

html_theme = 'alabaster'

# Grouping the document tree into LaTeX files. List of tuples
# (source start file, target name, title, author, documentclass
# [howto/manual]).
latex_documents = [
    ('index',
     '%s.tex' % project,
     u'%s Documentation' % project,
     u'OpenTelekomCloud', 'manual'),
]
