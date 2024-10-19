#!/usr/bin/python3

import apt

import os

current_file_path = os.path.abspath(__file__)
current_directory = os.path.dirname(current_file_path)
with open(current_directory + '/default_package', 'r') as file:
    default_packages = [line.strip() for line in file.readlines()]

cache = apt.cache.Cache()
current_packages = []
for package in cache:
    if (package.is_installed):
        current_packages.append(package.name)

set_default_packages = set(default_packages)
set_current_packages = set(current_packages)

print("==========================")

removed_packages = list(set_default_packages - set_current_packages)
if removed_packages:
    print("* Removed APT packages:")
    for package in removed_packages:
        print("**", package)
else:
    print("* No APT package removed")

print("==========================")

new_packages = list(set_current_packages - set_default_packages)
if new_packages:
    print("* New APT packages")
    for package in new_packages:
        print("**", package)
else:
    print("* No new APT packages")
