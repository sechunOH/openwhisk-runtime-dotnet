#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -ex

# Build script for Travis-CI.

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../.."
WHISKDIR="$ROOTDIR/../openwhisk"
UTILDIR="$ROOTDIR/../openwhisk-utilities"

export OPENWHISK_HOME=$WHISKDIR

# run scancode using the ASF Release configuration
cd $UTILDIR
scancode/scanCode.py --config scancode/ASF-Release.cfg $ROOTDIR

# Upgrade dpkg avoid problems installing dotnet 3.0
# https://github.com/travis-ci/travis-ci/issues/9361#issuecomment-408431262
sudo apt-get install -y --force-yes -q -qq dpkg
# Install dotnet
wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get install -y apt-transport-https
sudo apt-get -y update -qq
sudo apt-get install -y dotnet-sdk-3.0

# Build OpenWhisk deps before we run tests
cd $WHISKDIR
TERM=dumb ./gradlew install
# Mock file (works around bug upstream)
echo "openwhisk.home=$WHISKDIR" > whisk.properties
echo "vcap.services.file=" >> whisk.properties

# Build runtime and dependencies
cd $ROOTDIR

# Build runtime & test dependencies
TERM=dumb ./gradlew distDocker
