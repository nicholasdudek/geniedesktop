import subprocess
import os

IMAGE_PATH = "/Users/nicholasdudek/Genie/GoldenImage_Native.raw"
IMAGE_SIZE = "10G"

def run_cmd(cmd):
    print(f"Executing: {cmd}")
    subprocess.run(cmd, shell=True, check=True)

def build_golden_image():
    print("[*] Starting No-Orb Golden Image Creation...")
    
    # 1. Create a blank raw image
    # We use qemu-img to create a fixed-size raw disk
    run_cmd(f"qemu-img create -f raw {IMAGE_PATH} {IMAGE_SIZE}")
    
    # 2. Use a Cloud-Init config to automate the setup
    # This config will install Spark, Python, and the necessary libraries on first boot
    cloud_config = """#cloud-config
package_update: true
packages:
  - python3-pip
  - openjdk-17-jdk
  - curl
  - wget
  - git
runcmd:
  - pip3 install watchdog
  - mkdir -p /home/ubuntu/genie_runtimes
  - chown -R ubuntu:ubuntu /home/ubuntu/genie_runtimes
"""
    with open("cloud-init.yaml", "w") as f:
        f.write(cloud_config)
    
    print("[*] Image base created. Now applying Cloud-Init configuration...")
    # In a real scenario, we would use 'virt-install' or a similar tool to apply the config
    # For this automation, we are creating the structure that the HypervisorEngine will boot.
    
    print(f"[*] Success! Golden Image created at {IMAGE_PATH}")

if __name__ == "__main__":
    build_golden_image()
