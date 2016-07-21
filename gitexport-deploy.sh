#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage:  $(basename "$0") <gitExport.tar.gz> <targethost>"
  exit 0
fi

# base name of TGZ file, which is waiting to be deployed in your home dir on the remote server.
TGZFILE="$1"
if [[ ! "$TGZFILE" ]]; then
  echo "Error: deploy bundle filename was not specified."
  exit 1
fi

# Make sure we have something to deploy
if [ ! -f "$TGZFILE" ]; then
  echo "Deploy file does not exist: $TGZFILE"
  exit 1
fi

# live, uat, mss, etc.
DEPLOYTARGET="$2"
if [[ ! "$DEPLOYTARGET" ]]; then
  echo "No deploy target was specified. (user@servername, servername, live, staging, UAT, dev4, etc)"
  exit 1
fi

# Read in default settings
DEFAULTSETTINGS=".gitexport.deploysettings"
echo -n "Looking for $DEFAULTSETTINGS... "
if [ -f "$DEFAULTSETTINGS" ]; then
  # Read in DEPLOY_DIR, DEPLOY_USER from settings file
  echo "found."
  source "$DEFAULTSETTINGS"
else
  echo ""
fi

# Read in target-specific settings
SETTINGSFILE=".gitexport.deploysettings.$DEPLOYTARGET"
echo -n "Looking for $SETTINGSFILE..."
if [ -f "$SETTINGSFILE" ]; then
  # Read in DEPLOY_HOST, DEPLOY_DIR, and DEPLOY_USER from settings file to override generic settings
  echo "found."
  source "$SETTINGSFILE"
else
  echo ""
fi

if [[ ! "$DEPLOY_HOST" ]]; then
  echo "DEPLOY_HOST was not defined in settings. Using '$DEPLOYTARGET' instead."
  DEPLOY_HOST="$DEPLOYTARGET"
fi
if [[ ! "$DEPLOY_DIR" ]]; then
  echo "DEPLOY_DIR was not defined in any settings file. Cannot continue."
  exit 1
fi
if [[ ! "$DEPLOY_USER" ]]; then
  echo "DEPLOY_USER was not defined in any settings file. Cannot continue."
  exit 1
fi

# Try uploading the file
echo "Scp'ing..."
scp "$TGZFILE" "$DEPLOYTARGET":~/ || {
  echo "Upload failed."
  exit 1
}

# Let it rip!
ssh -t "$DEPLOY_HOST" "~/bin/deploy-local.sh '$(basename "$TGZFILE")' '$DEPLOY_DIR' '$DEPLOY_USER'"
SSHRESULT=$?
exit $SSHRESULT
