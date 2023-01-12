#!/bin/bash -e
# Creates a systemd-nspawn container with Arch Linux
# MIRROR=ftp://u318793-sub1:wwNAhsZxcx4zp9fY@u318793-sub1.your-storagebox.de
MIRROR="file:///var/arch-repo-grug/public"
REPO_FOLDER="/var/arch-repo-grug"

if [ $UID -ne 0 ]; then
	echo "run this script as root" >&2
	exit 1
fi

mkdir -p /var/arch-repo-grug/public/mirror/archlinux/
rsync --progress -rlptH --safe-links --delete-delay --delay-updates rsync://mirror.f4st.host/archlinux/ /var/arch-repo-grug/public/mirror/archlinux/

dest="/tmp/aur_build_$(sha1sum build_aur_packages.sh setup.sh | sha1sum  | sed 's/\s.*$//')"

if [ ! -d $dest ]; then
    if [ ! -f "archlinux-bootstrap-x86_64.tar.gz" ]; then
        curl -LO "$MIRROR/mirror/archlinux/iso/latest/archlinux-bootstrap-x86_64.tar.gz"
    fi
    mkdir -p $dest
    tar -xzf "archlinux-bootstrap-x86_64.tar.gz" -C $dest --strip-components=1

    # Set mirror
    printf 'Server = %s/$repo/os/$arch\n' "$MIRROR/mirror/archlinux" > $dest/etc/pacman.d/mirrorlist

    # TODO: switch to passwd
    sed '/^root:/ s|\*||' -i $dest/etc/shadow # passwordless login
    rm $dest/etc/resolv.conf # systemd configures this
    # https://github.com/systemd/systemd/issues/852
    [ -f $dest/etc/securetty ] && printf 'pts/%d\n' $(seq 0 10) >> $dest/etc/securetty
    cp setup.sh $dest/setup.sh
    systemd-nspawn -q -D $dest bash /setup.sh

    # Automatically login
    mkdir -p $dest/etc/systemd/system/console-getty.service.d
    cp autologin.conf $dest/etc/systemd/system/console-getty.service.d/override.conf

    # Automatically tail journal when logging in
    printf "\njournalctl -f\n" >> $dest/root/.profile
fi

cp repo_sync.service $dest/etc/systemd/system/repo_sync.service
cp repo_sync.sh $dest/repo_sync.sh
systemctl enable repo_sync --root=$dest

systemd-nspawn -q -b -D $dest --bind=$REPO_FOLDER:/var/arch-repo-grug --bind=$(pwd)/gitrepos.packages:/gitrepos.packages --bind=$(pwd)/aur.packages:/aur.packages --bind=$(pwd)/aur_missing.packages:/aur_missing.packages --bind=$(pwd)/pacman_missing.packages:/pacman_missing.packages --bind=$(pwd)/remote.packages:/remote.packages --bind=$(pwd)/keys:/keys

pacman --noconfirm -Syu && paccache -rk1 && paccache -ruk0
