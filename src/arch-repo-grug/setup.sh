#!/usr/bin/env bash
pacman-key --init && pacman-key --populate archlinux
pacman --noconfirm --needed -Syu base-devel sudo git rsync pacman-contrib
useradd -m build
passwd -d build
mkdir -p /var/arch-repo-grug

echo 'build ALL=(ALL:ALL) ALL' >>/etc/sudoers
runuser -l build -c "git clone https://aur.archlinux.org/aurutils.git --depth 1 && cd aurutils && makepkg -crs --rmdeps --noconfirm"
pacman --noconfirm -U /home/build/aurutils/*.pkg.tar.*

echo "# AUR repo" >> /etc/pacman.conf && \
echo "[aur]" >> /etc/pacman.conf && \
echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf && \
echo "Server = file:///var/arch-repo-grug/public/aur" >> /etc/pacman.conf

echo "# grug repo" >> /etc/pacman.conf && \
echo "[grug]" >> /etc/pacman.conf && \
echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf && \
echo "Server = file:///var/arch-repo-grug/public/grug" >> /etc/pacman.conf
