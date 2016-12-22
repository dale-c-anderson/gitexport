#!/bin/bash

################################################################################
#
# If you change this file, you also need to update
# REMOTE_DEPLOY_TOOL_CHECKSUM in gitexport-deploy.sh
#
################################################################################

function cerr() {
  >&2 echo "$@"
}

THIS_HOST="[$(hostname -f)]"

if [ $# -ne 3 ]; then
  cerr "For deploying exported / archived git packages (or other prepared bundles) locally once they have been pushed via ssh"
  cerr "Requires sudo privileges."
  cerr "Moves the deploy file to the target dir, sets the correct owner, extracts the bundle, and then removes it."
  cerr "Usage:   $(basename "$0") ./bundle-to-unpack.tar.gz /full/path/to/dest/dir/ owner"
  exit 0
fi

deployfile="$1"
if [ ! -f "$deployfile" ]; then
  cerr "${THIS_HOST}: Err: Deploy file does not exist: $deployfile"
  exit 21
fi

# @TODO: IS_TGZ isn't actually used....
if [[ "$deployfile" == *.tar.gz ]]; then
  : # OK
elif [[ "$deployfile" == *.tgz ]]; then
  : # OK
else
  cerr "${THIS_HOST}: Err: The deploy file is expected to be in .tgz or .tar.gz format."
  exit 31
fi

deployuser="$3"
getent passwd "$deployuser" >/dev/null 2>&1 || {
  cerr "${THIS_HOST}: Err: user doesn't exist: $deployuser"
  exit 44
}

deploydir="$2"
if ! sudo test -d "$deploydir"; then
  cerr "${THIS_HOST}: Deploy dir doesn't exist: '$deploydir'"
  sudo -u "$deployuser" mkdir -pv "$deploydir" || exit 49
fi


## Moving and chowning isn't necessary for tar to work, but when we unpack it as the deploy user,
## they may not have permission to read it or get at it where we uploaded it to.
sudo mv -v "$deployfile" "$deploydir/" || {
  cerr "${THIS_HOST}: Err: move failed"
  exit 51
}
sudo chown "$deployuser": "$deploydir/$deployfile"|| {
  cerr "${THIS_HOST}: Err: Could not chown deploy file. Aborting."
  exit 55
}
sudo -u "$deployuser" -H sh -c "cd '$deploydir' && tar xzfv '$deployfile'" || {
  cerr "${THIS_HOST}: Err: Could not extract deploy file to target. Deploy failed."
  exit 59
}

sudo rm "$deploydir/$deployfile" || {
  cerr "${THIS_HOST}: Warn: Could not remove '$deployfile'. You'll need to remove it manually."
}
