FROM sickcodes/docker-osx:latest

USER root

COPY --chown=arch:arch ./Ventura-full.qcow2 /home/arch/OSX-KVM/BaseSystem.img

RUN chmod 644 /home/arch/OSX-KVM/BaseSystem.img

USER arch

RUN qemu-img create -f qcow2 /home/arch/OSX-KVM/mac_hdd_ng.img 200G

CMD ./enable-ssh.sh && /bin/bash -c ./Launch.sh