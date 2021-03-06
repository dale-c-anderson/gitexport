#!/bin/bash

REMOTE_DEPLOY_TOOL="gitexport-remote-deploy-tool.sh"
REMOTE_DEPLOY_TOOL_SOURCE="https://raw.githubusercontent.com/dale-c-anderson/gitexport/master/$REMOTE_DEPLOY_TOOL"
REMOTE_DEPLOY_TOOL_CHECKSUM='f32beac3613d7e33b82e57052b5c2f77'

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

# Download the remote deploy script. Also check the sum for safety.
# We do this (instead of using the local version) because (1) the local version isn't
# actually used locally, and (2) we don't know where it was installed on the local machine.
echo "Grabbing $REMOTE_DEPLOY_TOOL..."
REMOTE_TOOL_TEMP_DIR="$(mktemp --directory)"
REMOTE_TOOL_TEMP="$REMOTE_TOOL_TEMP_DIR/$REMOTE_DEPLOY_TOOL"
if test -f "$REMOTE_DEPLOY_TOOL_SOURCE"; then
  REMOTE_TOOL_TEMP="$REMOTE_DEPLOY_TOOL_SOURCE"
  echo "REMOTE_DEPLOY_TOOL_SOURCE is a local file: $REMOTE_TOOL_TEMP"
elif [[ "$REMOTE_DEPLOY_TOOL_SOURCE" = "http"* ]]; then
  : # Get it from the web
  wget -O "$REMOTE_TOOL_TEMP" "$REMOTE_DEPLOY_TOOL_SOURCE"
else
  echo "Fatal: No valid REMOTE_DEPLOY_TOOL_SOURCE"
  exit 1
fi
CHECKSUM="$(md5sum "$REMOTE_TOOL_TEMP"| awk '{print $1}')"
if [[ "$CHECKSUM" != "$REMOTE_DEPLOY_TOOL_CHECKSUM" ]]; then
  echo -n "Warning: Checksum failed. Do you wish to continue? [y/N] "
  read -r CONFIRM
  if [[ "$CONFIRM" != "y" ]]; then
    echo "A failed checksum usually means there is an updated version of GitExport available from https://github.com/dale-c-anderson/gitexport"
    exit 0
  fi
fi

# Upload the bundle
echo "Scp'ing bundled files..."
scp "$TGZFILE" "$DEPLOYTARGET":~/ || {
  echo "Upload failed."
  exit 1
}

# Upload the remote deploy script
echo "Pushing up remote deploy tool..."
scp "$REMOTE_TOOL_TEMP" "$DEPLOYTARGET:~/$REMOTE_DEPLOY_TOOL" || {
  echo "Upload failed."
  exit 1
}

# Execute the remote deploy script, and then remove it.
# shellcheck disable=SC2088
# shellcheck disable=SC2029
if ssh -tq "$DEPLOY_HOST" "chmod +x './$REMOTE_DEPLOY_TOOL' && ./$REMOTE_DEPLOY_TOOL './$(basename "$TGZFILE")' '$DEPLOY_DIR' $DEPLOY_USER && rm './$REMOTE_DEPLOY_TOOL'"; then
  : # 'No news' is good news.
else
  SSHRESULT=$?
  echo "Remote deploy tool command exited with error code ${SSHRESULT}"
fi
exit $SSHRESULT
