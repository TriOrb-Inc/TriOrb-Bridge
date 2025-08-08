# TriOrb-Bridge
他のホストとTriOrb AMRの通信をブリッジするパッケージ

## Initial Setup
### Submodule Initialization
```bash
git submodule update --init --recursive
```
### Build docker image and ros2 package
```bash
sh build.sh
```

## Usage
### Create config file
Sample config file is provided in `config/bridge.yaml`. You can create your own config file by copying it and modifying the parameters as needed.

### Run package
```bash
sh run.sh -i <robot_ip> -r <ros_topic_prefix> -c <config_file>
```
#### Sample command
```bash
sh run.sh -i 192.168.25.79 -r /AGX -c config/bridge.yaml -d # This will run the bridge with the specified robot IP, ROS topic prefix, configuration file, on detached. (Port is set to 1883 by default, MQTT topic prefix is set to empty by default)
sh run.sh -i 192.168.25.78 -r /Orin -c config/bridge.yaml # Other host
```