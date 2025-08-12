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

FROM ros:humble

RUN apt update
RUN apt install -y \
    build-essential \
    cmake \
    git \
    python3-pip \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    tmux \
    nano

# Install Paho MQTT
RUN apt install -y libpaho-mqtt-dev libpaho-mqttpp-dev nlohmann-json3-dev
WORKDIR /tmp
RUN git clone https://github.com/eclipse/paho.mqtt.cpp
WORKDIR /tmp/paho.mqtt.cpp
RUN git checkout v1.5.2
RUN git submodule init && git submodule update
RUN cmake -Bbuild -H. -DPAHO_WITH_MQTT_C=ON -DPAHO_BUILD_EXAMPLES=ON -DPAHO_WITH_SSL=ON &&\
    cmake --build build/ --target install
RUN rm -rf /tmp/paho.mqtt.cpp
RUN python3 -m pip install paho-mqtt

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*