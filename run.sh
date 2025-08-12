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
    param   ROBOT_IP -i --ip init:="localhost" -- "IP address of the robot to connect to (Defaults to localhost)"
    param   MQTT_PORT -p --port init:=1883 -- "MQTT port of the robot to connect to (Defaults to 1883)"
    param   MQTT_PREFIX -m --mqtt init:="" -- "MQTT topic prefix (Defaults to empty)"
    param   ROS_PREFIX -r --ros init:="" -- "ROS topic prefix (Defaults to empty)"
    param   BRIDGE_CONFIG -c --config init:="./config/bridge.yaml" -- "Path to the bridge configuration file (Defaults to ./config/bridge.yaml)"
    param   IMAGE_TAG -t --tag init:="triorb/connecter:${VERSION}-$(uname -m)" -- "Tag for the Docker image (Defaults to triorb/connecter:${VERSION}-$(uname -m))"
    param   INSTALL_DIR --dir init:="./install" -- "Directory to install the robot software (Defaults to ./install)"
    param   ROS_LOCALHOST_ONLY --localhost-only init:=1 -- "Set ROS_LOCALHOST_ONLY environment variable (Defaults to 1)"
    param   ROS_DOMAIN_ID --domain-id init:=0 -- "Set ROS_DOMAIN_ID environment variable (Defaults to 0)"
    param   NODE_NAME --node-name init:="mqtt_client" -- "Name of the ROS node (Defaults to mqtt_client)"
    param   CONTAINER_NAME --container-name init:="connector" -- "Name of the Docker container (Defaults to connector)"
    disp    :usage  -h --help
    disp    VERSION    --version
}
eval "$(getoptions parser_definition) exit 1"

docker ps | grep ${CONTAINER_NAME} > /dev/null
if [ $? -ne 0 ]; then
    docker run -it --rm -d --name ${CONTAINER_NAME} --ipc=host --net=host \
                    --add-host=localhost:127.0.1.1 \
                    -e ROS_LOCALHOST_ONLY=$ROS_LOCALHOST_ONLY \
                    -e ROS_DOMAIN_ID=$ROS_DOMAIN_ID \
                    -v ${INSTALL_DIR}:/install \
                    -v $(pwd):/ws \
                    -w /ws \
                    ${IMAGE_TAG} /bin/bash
    echo "${CONTAINER_NAME} container started in background."
    sleep 1
else
    echo "${CONTAINER_NAME} container is already running."
fi


TMUX_NAME=${ROS_PREFIX/'/'/''}_$(echo "$ROBOT_IP" | sed 's/\./_/g')
docker exec connector tmux ls | grep ${TMUX_NAME} > /dev/null
if [ $? -eq 0 ]; then
    docker exec -it ${CONTAINER_NAME} tmux kill-session -t ${TMUX_NAME}
    echo "Killed existing tmux session: ${TMUX_NAME}"
    sleep 1
fi
docker exec -it ${CONTAINER_NAME} tmux new-session -s ${TMUX_NAME} -d "\
    source /install/setup.bash && \
    echo \"Starting ROS bridge with robot IP: ${ROBOT_IP}, MQTT port: ${MQTT_PORT}, MQTT prefix: ${MQTT_PREFIX}, ROS prefix: ${ROS_PREFIX}\" && \
    ros2 launch mqtt_client connect.launch.ros2.xml params_file:=${BRIDGE_CONFIG} broker_host:=${ROBOT_IP} broker_port:=${MQTT_PORT} prefix_mqtt:=\'${MQTT_PREFIX}\' prefix_ros:=\'${ROS_PREFIX}\' ; \
    /bin/bash"
echo "Started tmux session: ${TMUX_NAME} in container: ${CONTAINER_NAME}"
echo "ROS bridge with robot IP: ${ROBOT_IP}, MQTT port: ${MQTT_PORT}, MQTT prefix: ${MQTT_PREFIX}, ROS prefix: ${ROS_PREFIX}"