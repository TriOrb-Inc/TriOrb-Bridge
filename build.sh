#!/bin/bash
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author: TriOrb Inc.
#
cd $(dirname $0)
. ./lib/getoptions.sh

VERSION=$(cat VERSION)
parser_definition() {
    setup   REST help:usage -- "Usage: $(basename "$0") [options]" ''
    msg -- 'Options:'
    param   DOCKER_FILE -f --file init:="./docker/Dockerfile" -- "Path to the Dockerfile (Defaults to ./docker/Dockerfile)"
    param   IMAGE_TAG -t --tag init:="triorb/connecter:${VERSION}-$(uname -m)" -- "Tag for the Docker image (Defaults to triorb/connecter:${VERSION}-$(uname -m))"
    param   INSTALL_DIR -d --dir init:="./install" -- "Directory to install the robot software (Defaults to ./install)"
    param   BUILD_TYPE --build-type init:="Release" -- "Build type for the ROS packages (Defaults to Release)"
    disp    :usage  -h --help
    disp    VERSION    --version
}
eval "$(getoptions parser_definition) exit 1"

echo "Building Docker image with tag: $IMAGE_TAG"
docker build -f "$DOCKER_FILE" -t "$IMAGE_TAG" .
if [ $? -ne 0 ]; then
    echo "Docker build failed."
    exit 1
fi
echo "Docker image built successfully: $IMAGE_TAG"

echo "Building ROS packages and installing to $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
docker run -it --rm --name build-connector \
                -v BUILD_TYPE=${BUILD_TYPE} \
                -v ${INSTALL_DIR}:/install \
                -v $(pwd):/ws \
                -w /ws \
                ${IMAGE_TAG} /bin/bash -c '\
                colcon build --cmake-args -DCMAKE_BUILD_TYPE=${BUILD_TYPE} --install-base /install --base-paths ./src'
