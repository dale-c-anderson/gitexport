#!/bin/bash

## Simple wrapper to tar up the git repo, and optionally push it to a remote server.
## Takes one mandatory argument: the hash of the commit that you want to export changes since.
## And one optional argument: the name of the SSH server you want to push the archive to.

# Required argument: The hash to compare against the HEAD.
SINCEWHEN="$1"
if [ $# -eq 0 ]; then
  echo ""
  echo "You need to supply what hash to reference."
  echo ""
  exit 1
fi

# Optional argument: Remote host to push files to
HOST="$2"


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
REPO=${PWD##*/}
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

# Export the files changed since <hash> and now: Skip listing deleted or the old names of files if they were renamed.
if [ -f "$EXCLUSIONS" ]; then
  echo "Excluding paths from $EXCLUSIONS"
  git diff --diff-filter=ACMRT --name-only "$SINCEWHEN" HEAD| tar -T - -cf "$TARFILE" --exclude-from="$EXCLUSIONS"
else
  git diff --diff-filter=ACMRT --name-only "$SINCEWHEN" HEAD| tar -T - -cf "$TARFILE"
fi
echo "Saved to $TARFILE"

# Deleted files:
DELETED_FILES=$(git diff --name-only --diff-filter=D "$SINCEWHEN" HEAD)
DELETED_FILE_COUNT=$(echo -n "$DELETED_FILES"|wc -l)
if [ $DELETED_FILE_COUNT -gt 0 ]; then
  echo ""
  echo "#########"
  echo "The following files have been deleted from the repo and will need to be removed manually from the server:"
  echo "$DELETED_FILES"
  echo ""
fi

# If the HOST argument is supplied, the push the repository up to my home directory on that server.
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
