#!/usr/bin/env sh
set -o errexit
cd /mnt

# makepkg
cat <<EOF | sudo tee -a ./etc/makepkg.conf > /dev/null
DLAGENTS=('ftp::/usr/bin/aria2c -UWget -s8 %u -o %o --max-connection-per-server=8 --min-split-size=1M'
          'http::/usr/bin/aria2c -UWget -s8 %u -o %o --max-connection-per-server=8 --min-split-size=1M'
          'https::/usr/bin/aria2c -UWget -s8 %u -o %o --max-connection-per-server=8 --min-split-size=1M'
          'rsync::/usr/bin/rsync -z %u %o'
          'scp::/usr/bin/scp -C %u %o')
EOF

# powepill
sed -i'' "
	s/\"--max-concurrent-downloads=[^\"]*\"/\"--max-concurrent-downloads=800\"/g;
	s/\"--max-connection-per-server=[^\"]*\"/\"--max-connection-per-server=16\"/g;
	s/\"--min-split-size=[^\"]*\"/\"--min-split-size=2M\"/g;
" /etc/powerpill/powerill.json

# services
sudo systemctl --root=. enable NetworkManager
sudo systemctl --root=. enable bumblebeed
sudo systemctl --root=. enable zfs-import-cache zfs-import.target
sudo systemctl --root=. enable zfs.target zfs-mount # better than fstab
sudo systemctl --root=. enable sshd

# create main user
echo '%wheel ALL=(ALL) NOPASSWD: ALL' | sudo tee -a ./etc/sudoers

# autologin
cat <<EOF | sudo tee ./etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin pedrohlc --noclear %I \$TERM
Type=simple
EOF


# google auth
sudo sed -i'' -e '3i auth required pam_google_authenticator.so' /etc/pam.d/sshd