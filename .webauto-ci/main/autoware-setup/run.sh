#!/bin/bash -e

sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(source /etc/os-release && echo "$UBUNTU_CODENAME") main" | sudo tee /etc/apt/sources.list.d/ros2.list >/dev/null
sudo -E apt-get -y update
sudo -E apt-get -y install usbutils # For kvaser

ansible_args=()
ansible_args+=("--extra-vars" "prompt_install_nvidia=y")
ansible_args+=("--extra-vars" "prompt_download_artifacts=y")
ansible_args+=("--extra-vars" "data_dir=$HOME/autoware_data")
ansible_args+=("--extra-vars" "ros2_installation_type=ros-base")
ansible_args+=("--extra-vars" "install_devel=false")

# read amd64 env file and expand ansible arguments
source 'amd64.env'
while read -r env_name; do
    ansible_args+=("--extra-vars" "${env_name}=${!env_name}")
done < <(sed "s/=.*//" <amd64.env)

ansible-galaxy collection install -f -r "ansible-galaxy-requirements.yaml"
ansible-playbook "ansible/playbooks/universe.yaml" \
    "${ansible_args[@]}" \
    -e WORKSPACE_ROOT="$(pwd)" \
    --skip-tags vcs

# get installed ros distro
# shellcheck disable=SC2012
ROS_DISTRO=$(ls -1 /opt/ros | head -1)

# install cyclone dds
sudo -E apt-get -y install "ros-${ROS_DISTRO}-rmw-cyclonedds-cpp"
