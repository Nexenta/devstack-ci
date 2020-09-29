import os
import site

user_packages = site.getusersitepackages()
site_packages = site.getsitepackages()
site_packages.append(user_packages)

host_packages = []

for path in site_packages:
    if os.path.isdir(path):
        host_packages.append(path)

packages = " ".join(host_packages)

print(packages)
