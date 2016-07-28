#!/bin/bash

## Simple wrapper to tar up the git repo, and optionally push it to a remote server.

# Optional argument: Remote host to push files to
HOST="$1"

# Make sure we're in the working tree
git rev-parse --is-inside-work-tree > /dev/null 2>&1 || {
	echo "I am not inside a git working tree. There is nothing to do."
	exit 1
}

# Make sure we're in the root of a repository
if [ ! -d .git  ]; then
	echo "Move to the root of the repository before continuing."
	exit 1
fi


# Give a warning if there are unstaged or uncommitted changes to the working tree.
# @TODO: Detect only files that would actually be affected; this hammer is too big.
WARN=0
git diff-files --quiet || {
  # files have been modified but not staged.
  WARN=1
}
git diff-index --quiet --cached HEAD || {
  # files have been staged but not committed.
  WARN=1
}
if [ "$WARN" -eq 1 ]; then
  if [[ "$HOST" ]]; then
    # Remote host was specified - bail out now.
    echo "** There are uncommitted or unstaged changes to the working tree. Aborting now to avoid deploying dirty files."
    exit 1
  else
    echo "** This repository is not in a clean state. Your deploy bundle may contain unintended changes."
  fi
fi


# Use the current directory as the name of the repo to tar up.
REPO="${PWD##*/}"
TARFILE="../$REPO-HEAD.tar"
SCRIPTDIR="$(dirname "$0")"
EXCLUSIONS="$SCRIPTDIR/gitexport.exclusions"

# Get rid of any previous garbage lying around
# @TODO: Should we ask before removing files?
if [ -f "$TARFILE" ]; then
  echo "Removing old $TARFILE"
  rm "$TARFILE"
fi
if [ -f "$TARFILE.gz" ]; then
  echo "Removing old $TARFILE.gz"
  rm "$TARFILE.gz"
fi

# export the entire git repository
if [ -f "$EXCLUSIONS" ]; then
  echo "Excluding paths from $EXCLUSIONS"
  git ls-tree --name-only --full-tree -r HEAD| tar -T - -cf "$TARFILE" --exclude-from="$EXCLUSIONS"
else
  git ls-tree --name-only --full-tree -r HEAD| tar -T - -cf "$TARFILE"
fi
echo "Saved to $TARFILE"


# If the HOST argument is supplied, push the repository up to user's home directory of that server.
if [[ "$HOST" ]]; then
  gzip "$TARFILE"
  DEPLOY=0
  if type gitexport-deploy.sh > /dev/null 2>&1; then
    if [ -f ".gitexport.deploysettings" ] || [ -f ".gitexport.deploysettings.$HOST" ]; then
      # The deploy script is in the path, and there is a settings file in place.
      DEPLOY=1
    fi
  fi
  if [ $DEPLOY -eq 1 ]; then
    echo "Deploying $TARFILE.gz to $HOST..."
    gitexport-deploy.sh "$TARFILE.gz" "$HOST"
  else
    echo ""
    echo "If you create a '.gitexport.deploysettings' or '.gitexport.deploysettings.$HOST' file in the current directory, "
    echo "this script can deploy the bundle on the remote server for you when you upload it."
    echo "The following Bash variables need to be defined in the settings file:"
    echo "DEPLOY_HOST=server.example.com  # if hostname of your target does not match the host you specified"
    echo "DEPLOY_DIR=/parent/path/of/repo # required"
    echo "DEPLOY_USER=correctowner        # required"
    echo ""
    echo "Uploading $TARFILE.gz to $HOST ..."
    scp "$TARFILE.gz" "$HOST":~/ || {
      echo "upload failed."
      exit 1
    }
  fi
  rm "$TARFILE.gz"
  echo "Removed $TARFILE.gz"
fi
