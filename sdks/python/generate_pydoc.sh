#!/bin/bash
#
#    Licensed to the Apache Software Foundation (ASF) under one or more
#    contributor license agreements.  See the NOTICE file distributed with
#    this work for additional information regarding copyright ownership.
#    The ASF licenses this file to You under the Apache License, Version 2.0
#    (the "License"); you may not use this file except in compliance with
#    the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

# This script will run sphinx to create documentation for python sdk
#
# Use "generate_pydocs.sh" to update documentation in the docs directory.
#
# The exit-code of the script indicates success or a failure.

# Quit on any errors
set -e

# Create docs directory if it does not exist
mkdir -p target/docs
rm -rf target/docs/*

mkdir -p target/docs/source

# Exclude internal/experimental files from the documentation.
excluded_internal_code=(
    apache_beam/examples/
    apache_beam/internal/clients/
    apache_beam/io/gcp/internal/clients/
    apache_beam/runners/api/
    apache_beam/runners/test/
    apache_beam/runners/portability/
    apache_beam/runners/worker/
    apache_beam/runners/dataflow/internal/clients/
    apache_beam/testing/data/)

python $(type -p sphinx-apidoc) -f -o target/docs/source apache_beam \
    "${excluded_internal_code[@]}" "*_test.py"

# Remove Cython modules from doc template; they won't load
sed -i -e '/.. automodule:: apache_beam.coders.stream/d' \
    target/docs/source/apache_beam.coders.rst

# Create the configuration and index files
cat > target/docs/source/conf.py <<'EOF'
import os
import sys

sys.path.insert(0, os.path.abspath('../../..'))

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.napoleon',
    'sphinx.ext.viewcode',
]
master_doc = 'index'
html_theme = 'sphinxdoc'
project = 'Apache Beam'
EOF
cat > target/docs/source/index.rst <<'EOF'
.. include:: ./modules.rst
EOF

# Build the documentation using sphinx
# Reference: http://www.sphinx-doc.org/en/stable/man/sphinx-build.html
python $(type -p sphinx-build) -v -a -E -q target/docs/source \
  target/docs/_build -c target/docs/source \
  -w "target/docs/sphinx-build.warnings.log"

# Message is useful only when this script is run locally.  In a remote
# test environment, this path will be removed when the test completes.
echo "Browse to file://$PWD/target/docs/_build/index.html"

# Fail if there are errors or warnings in docs
! grep -q "ERROR:" target/docs/sphinx-build.warnings.log
! grep -q "WARNING:" target/docs/sphinx-build.warnings.log
