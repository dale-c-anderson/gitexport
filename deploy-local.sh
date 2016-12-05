#!/bin/bash

################################################################################
#
# If you change this file, you also need to update
# REMOTE_DEPLOY_TOOL_CHECKSUM in gitexport-deploy.sh
#
################################################################################

if [ $# -ne 3 ]; then
  echo "For deploying exported / archived git packages (or other prepared bundles) locally once they have been pushed via ssh"
  echo "Requires sudo privileges."
  echo "Moves the deploy file to the target dir, sets the correct owner, extracts the bundle, and then removes it."
  echo "Usage:   $(basename "$0") ./bundle-to-unpack.tar.gz /full/path/to/dest/dir/ owner"
  exit 0
fi

deployfile="$1"
if [ ! -f "$deployfile" ]; then
  echo "$(basename "$0") Err: Deploy file does not exist: $deployfile"
  exit 1
fi

# @TODO: IS_TGZ isn't actually used....
if [[ "$deployfile" == *.tar.gz ]]; then
  IS_TGZ=1
elif [[ "$deployfile" == *.tgz ]]; then
  IS_TGZ=1
else
  echo "$(basename "$0") Err: The deploy file is expected to be in .tgz or .tar.gz format."
  exit 1
fi

deploydir="$2"
if ! sudo test -d "$deploydir"; then
  echo "$(basename "$0") Err: deploy dir doesnt exist: $deploydir"
  exit 1
fi

deployuser="$3"
getent passwd "$deployuser" >/dev/null 2>&1 || {
  echo "$(basename "$0") Err: user doesn't exist: $deployuser"
  exit 1
}

## Moving and chowning isn't necessary for tar to work, but when we unpack it as the deploy user,
## they may not have permission to read it or get at it where we uploaded it to.
sudo mv -v "$deployfile" "$deploydir/" || {
  echo "$(basename "$0") Err: move failed"
  exit 1
}
sudo chown "$deployuser": "$deploydir/$deployfile"|| {
  echo "$(basename "$0") Err: Could not chown deploy file. Aborting."
  exit 1
}
sudo -u "$deployuser" -H sh -c "cd '$deploydir' && tar xzfv '$deployfile'" || {
  echo "$(basename "$0") Err: Could not extract deploy file to target. Deploy failed."
  exit 1
}

sudo rm "$deploydir/$deployfile" || {
  echo "$(basename "$0") Warn: Could not remove '$deployfile'. You'll need to remove it manually."
}
