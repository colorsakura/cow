#!/bin/bash
set -e

pacman -Sy tree --noconfirm

echo $PWD
tree .

init_path=$PWD
mkdir upload_packages
cp $local_path/*/*/*.tar.zst ./upload_packages/

tree .

if [ ! -f ~/.config/rclone/rclone.conf ]; then
    mkdir --parents ~/.config/rclone
    echo "[onedrive]" >> ~/.config/rclone/rclone.conf
    echo "type = onedrive" >> ~/.config/rclone/rclone.conf

    echo "client_id=$RCLONE_ONEDRIVE_CLIENT_ID" >> ~/.config/rclone/rclone.conf
    echo "client_secret=$RCLONE_ONEDRIVE_CLIENT_SECRET" >> ~/.config/rclone/rclone.conf
    echo "region=$RCLONE_ONEDRIVE_REGION" >> ~/.config/rclone/rclone.conf
    echo "drive_type=$RCLONE_ONEDRIVE_DRIVE_TYPE" >> ~/.config/rclone/rclone.conf
    echo "token=$RCLONE_ONEDRIVE_TOKEN" >> ~/.config/rclone/rclone.conf
    echo "drive_id=$RCLONE_ONEDRIVE_DRIVE_ID" >> ~/.config/rclone/rclone.conf
fi

if [ ! -z "$GPG_PRIVATE_KEY" ]; then
    echo "$GPG_PRIVATE_KEY" | gpg --import
fi

cd upload_packages || exit 1

tree .

repo-add "./${repo_name:?}.db.tar.gz" ./*.tar.zst

if [ ! -z "$GPG_PRIVATE_KEY" ]; then
    packages=( "*.tar.zst" )
    for name in $packages
    do
        gpg --detach-sig --yes $name
    done
    repo-add --verify --sign "./${repo_name:?}.db.tar.gz" ./*.tar.zst
fi
rclone copy ./ "onedrive:${dest_path:?}" --copy-links
