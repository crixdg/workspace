### Scan Ubuntu
```shell
mkdir ~/ubuntu-scan
dpkg -l > ~/ubuntu-scan/dpkg-list.txt
apt-mark showmanual > ~/ubuntu-scan/manual-packages.txt
snap list > ~/ubuntu-scan/snap-list.txt
flatpak list > ~/ubuntu-scan/flatpak-list.txt
find /etc -type f > ~/ubuntu-scan/system-configs.txt
find ~/.config -type f > ~/ubuntu-scan/user-configs.txt
```