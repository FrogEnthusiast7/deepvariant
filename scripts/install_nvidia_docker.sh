#!/bin/bash
# Copyright 2019 Google LLC.
# This script is used to install nvidia docker on Ubutun 16.04.
# For different Linux distributions and versions, modifications might be needed.

set -euo pipefail

APT_ARGS=(
"-qq"
"-y"
)

# Installing nvidia docker to use deepvariant_gpu Docker image.
# (1) Install nvidia driver:
# https://github.com/NVIDIA/nvidia-docker/wiki/Frequently-Asked-Questions#how-do-i-install-the-nvidia-driver
sudo apt-get "${APT_ARGS[@]}" update
# From: https://docs.docker.com/install/linux/docker-ce/ubuntu/#set-up-the-repository
sudo apt-get "${APT_ARGS[@]}" install \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common

# https://www.tensorflow.org/install/gpu?hl=en#ubuntu_1604_cuda_101
echo "Installing CUDA..."
if ! dpkg-query -W cuda-10-1 ; then
  echo "Installing CUDA..."
  CUDA_DEB="cuda-repo-ubuntu1604_10.1.243-1_amd64.deb"
  curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/${CUDA_DEB}
  sudo -H apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
  sudo -H dpkg -i "./${CUDA_DEB}"
  sudo -H apt-get update "${APT_ARGS[@]}" > /dev/null
  sudo apt-get install "${APT_ARGS[@]}" cuda-10-1 > /dev/null
fi

# (2) Install Docker CE:
# https://docs.docker.com/engine/install/ubuntu/
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
 "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) \
 stable"
sudo apt-get "${APT_ARGS[@]}" update
sudo apt-get "${APT_ARGS[@]}" install docker-ce docker-ce-cli containerd.io

# (3) Install nvidia docker:
# https://github.com/NVIDIA/nvidia-docker#ubuntu-160418042004-debian-jessiestretchbuster
# Add the package repositories
distribution=$(. /etc/os-release;echo "$ID$VERSION_ID")
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L "https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list" | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install "${APT_ARGS[@]}" nvidia-container-toolkit
sudo systemctl restart docker

#### Test nvidia-smi with the latest official CUDA image
sudo docker run --gpus 1 nvidia/cuda:10.1-base nvidia-smi
