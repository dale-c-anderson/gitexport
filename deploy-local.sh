#!/bin/bash

if [ $# -ne 3 ]; then
  echo "For deploying exported / archived git packages (or other prepared bundles) locally once they have been pushed via ssh"
  echo "Requires sudo privileges."
  echo "Moves the deploy file to the target dir, sets the correct owner, extracts the bundle, and then removes it."
  echo "Usage:   $(basename "$0") <deployfile.tar.gz> </full/path/to/dest/dir> <owner>"
  echo "Example: $(basename "$0") 'telecomstorebox-LATEST.tgz' '/home/acro/apps/telecomstorebox' 'acro'"
  exit 0
fi

deployfile="$1"
if [ ! -f "$deployfile" ]; then
  echo "Deploy file does not exist: $deployfile"
  exit 1
fi

# @TODO: IS_TGZ isn't actually used....
if [[ "$deployfile" == *.tar.gz ]]; then
  IS_TGZ=1
elif [[ "$deployfile" == *.tgz ]]; then
  IS_TGZ=1
else
  echo "The deploy file is expected to be in .tgz or .tar.gz format."
  exit 1
fi

deploydir="$2"
if [ ! -d "$deploydir" ]; then
  echo "Oops  - deploydir doesnt exist: $deploydir"
  exit 1
fi

deployuser="$3"
getent passwd "$deployuser" >/dev/null 2>&1 || {
  echo "It doesn't look like the user exists: $deployuser"
  exit 1
}

echo -n "Moving $deployfile to $deploydir/ ... "
sudo mv "$deployfile" "$deploydir/" || {
  echo "Could not move deploy file to target dir. Aborting."
  exit 1
}
echo "OK"

# @TODO: Is this step actually necessary? I think running tar as the specified user is what sets permissions as the files are being extracted.
echo -n "Setting ownership of $deployfile to $deployuser ... "
sudo chown "$deployuser": "$deploydir/$deployfile"|| {
  echo "Could not chown deploy file. Aborting."
  exit 1
}
echo "OK"

# @TODO: Moving the tar file isn't necessary - you can use the -C switch to extract contents to a different directory.
echo "Extracting $deployfile... "
sudo -u "$deployuser" -H sh -c "cd $deploydir && tar xzfv $deployfile" || {
  echo "Could not extract deploy file to target. Deploy failed."
  exit 1
}
echo "OK"

echo -n "Removing $deployfile... "
sudo rm "$deploydir/$deployfile" || {
  echo "Could not remove $deployfile. You'll need to remove it manually."
}
echo "OK"

echo "All done."
exit 0
