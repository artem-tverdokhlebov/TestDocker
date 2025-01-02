# Use the existing Docker-OSX latest image as the base
FROM sickcodes/docker-osx:latest

# Copy the pre-provided BaseSystem.img into the container
COPY Ventura-full.qcow2 /home/arch/OSX-KVM/BaseSystem.img

# Ensure permissions are set correctly for BaseSystem.img
RUN chmod 644 /home/arch/OSX-KVM/BaseSystem.img

# Create a fresh macOS HDD image (128GB) if not already created
RUN qemu-img create -f qcow2 /home/arch/OSX-KVM/mac_hdd_ng.img 128G

# Update CMD to use BaseSystem.img and prepare for a fresh installation
CMD [[ -e "/home/arch/OSX-KVM/mac_hdd_ng.img" ]] || qemu-img create -f qcow2 /home/arch/OSX-KVM/mac_hdd_ng.img 128G \
    ; [[ -e "/home/arch/OSX-KVM/BaseSystem.img" ]] || { echo "BaseSystem.img not found"; exit 1; } \
    ; ./enable-ssh.sh && /bin/bash -c ./Launch.sh