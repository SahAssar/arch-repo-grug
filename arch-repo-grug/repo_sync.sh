#!/usr/bin/env bash
# Seems like this is needed for getting pod2man (required for ffmpeg) working https://archlinuxarm.org/forum/viewtopic.php?f=15&t=15568
source /etc/profile
set -euo pipefail

if [ ! -f "/var/arch-repo-grug/public/aur/aur.db.tar.gz" ]; then
    sudo --user build repo-add /var/arch-repo-grug/public/aur/aur.db.tar.gz
fi

if [ ! -f "/var/arch-repo-grug/public/grug/grug.db.tar.gz" ]; then
    sudo --user build repo-add /var/arch-repo-grug/public/grug/grug.db.tar.gz
fi

# TODO: Run a local arch sync first, then build aur packages, then sync local arch and aur to mnt-3.
# For mirror list have local (file://) first, then mnt-3 (via ftp), then a remote mirror (Server = https://mirror.f4st.host/archlinux/$repo/os/$arch)
# Probably don't package squashfs files, instead have them download the files (via rsync with the public user) at start.
# rsync --progress -rlptH --safe-links --delete-delay --delay-updates rsync://mirror.f4st.host/archlinux/ /var/arch-repo-grug/public/mirror/archlinux/

pacman --noconfirm -Syu && paccache -rk1 && paccache -ruk0

ADDITIONAL_PACKAGES="$(cat /remote.packages)"
INPUT_PACKAGES="$(cat /aur.packages)"
INPUT_MISSING_AUR_DEPENDENCIES="$(cat /aur_missing.packages)"
INPUT_MISSING_PACMAN_DEPENDENCIES="$(cat /pacman_missing.packages)"
AUR_KEYS="$(cat /keys)"
GIT_REPOS="$(cat /gitrepos.packages)"

packages_with_aur_dependencies="$(aur depends --pkgname $INPUT_PACKAGES $INPUT_MISSING_AUR_DEPENDENCIES)"

if [ -n "$INPUT_MISSING_PACMAN_DEPENDENCIES" ]; then
    echo "Additional Pacman packages to install: $INPUT_MISSING_PACMAN_DEPENDENCIES"
    pacman --noconfirm --needed -S $INPUT_MISSING_PACMAN_DEPENDENCIES
fi

# Required to initialize postgresql15
. /opt/postgresql15/bin/pgenv.sh

for key in $AUR_KEYS; do
    sudo --user build bash -c "gpg --list-keys $key || gpg --keyserver keys.gnupg.net --recv-keys $key"
done

# TODO: Check if --remove works here for removing old packages after a upgrade
sudo --user build \
    aur sync \
    --noconfirm \
    --noview \
    --nocheck \
    --upgrades \
    --remove \
    --database aur \
    --root /var/arch-repo-grug/public/aur \
    $packages_with_aur_dependencies

if [ -n "$ADDITIONAL_PACKAGES" ]; then
    (
        mkdir -p /var/arch-repo-grug/public/grug/additional
        cd /var/arch-repo-grug/public/grug/additional
        curl -L --remote-name-all -C - $ADDITIONAL_PACKAGES
        cd /var/arch-repo-grug/public/grug
        sudo --user build repo-add /var/arch-repo-grug/public/grug/grug.db.tar.gz additional/*
        cp -n additional/* .
    )
fi

(
    sudo --user build mkdir -p /home/build/gitrepos
    cd /home/build/gitrepos
    for gitrepo in $GIT_REPOS; do
        gitreponame=$(basename -s .git "$gitrepo")
        if [ -d "$gitreponame" ]; then
            cd /home/build/gitrepos/$gitreponame
            sudo --user build git fetch
            if [ $(sudo --user build git rev-list HEAD...origin/$(sudo --user build git rev-parse --abbrev-ref HEAD) --count) -ne '0' ]; then
                sudo --user build makepkg -crs --rmdeps --noconfirm
                sudo --user build repo-add /var/arch-repo-grug/public/grug/grug.db.tar.gz *.pkg.tar.*
                mv *.pkg.tar.* /var/arch-repo-grug/public/grug/
            fi
        else
            sudo --user build git clone "$gitrepo" "$gitreponame"
            cd /home/build/gitrepos/$gitreponame
            sudo --user build makepkg -crs --rmdeps --noconfirm
            sudo --user build repo-add /var/arch-repo-grug/public/grug/grug.db.tar.gz *.pkg.tar.*
            mv *.pkg.tar.* /var/arch-repo-grug/public/grug/
        fi
    done
)

# If we are still running the manually installed aurutils switch to the one tracked in our repo, it has now been built
if [ -d /home/build/aurutils ]; then
    pacman --noconfirm -Rcns aurutils
    rm -rf /home/build/aurutils
    pacman --noconfirm -S aurutils
fi
