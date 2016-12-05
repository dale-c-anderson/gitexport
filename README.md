# GitExport (aka Poor man's deploy)

## What is it?
A quick way to tar up a bundle of committed files from your local repository, and optionally scp them up and extract them to the right place and with the right ownership on a development, staging, or production server. There are 3 export options currently available:
 - Export only the files affected in the most recent commit
 - Export only the files affected after the commit you specify
 - Export all the files in the repo

## Pre-requisites
- Deploying requires SSH and Sudo access on your remote server. I have only used this in passwordless enviornments. Can't say what will happen if you need to supply a password.
- If all you're doing is exporting to tgz files, then you shouldn't need anything else.

## Compatibility 
- I've used this to deploy from Ubuntu 14, to Ubuntu 12, Ubuntu 14 and RHEL 6 servers. If you have good experience in other environments, let me know.

## Installation
1) Download or clone this repo, and cd into the dir:
```
git clone git@github.com:dale-c-anderson/gitexport.git gitexport
cd gitexport
```

2) Copy local files into your path and make them executable (assuming you have a `~/bin/`, and it's in your `$PATH`):

If you have `make`:
```
make -s install
```

If you don't have `make`:
```
cp ./{gitexport-latest-only.sh,gitexport-whole-repo.sh,gitexport-deploy.sh,gitexport-since-when.sh} ~/bin/
chmod +x ~/bin/{gitexport-latest-only.sh,gitexport-whole-repo.sh,gitexport-deploy.sh,gitexport-since-when.sh}
cp -i gitexport.exclusions.example ~/bin/gitexport.exclusions
```

## The Scripts
- `gitexport-latest-only.sh [remotehost]`
    - Exports only the files changed in the most recent commit

- `gitexport-since-when.sh <hash-value> [remotehost]`
    - Exports all the files modified or added AFTER the commit of the specified hash value

- `gitexport-whole-repo.sh [remotehost]`
    - Exports the entire repo, minus any paths matched in the exclusions file.

- `gitexport-deploy.sh <remotehost>`
    - Is called by the above 3 scripts to push the tar file and remote tool up to the remote server, and optionally puts the files in place on the remote end.

- `gitexport-remote-deploy-tool.sh <@args>`:
    - Gets uploaded to the remote server and executed by `gitexport-deploy.sh` on the remote host. Is not actually used locally.

## General behaviour
- Scripts need to be executed from the root of whatever repository they're operating on.
- Scripts will exclude paths specified in `~/bin/gitexport.exclusions`.
- Scripts operate only on the currently checked out branch.
- Scripts export their subset of files into a tar file just above the repository root.
- Run each script without arguments to see what the script needs.
- Scripts will not operate on a dirty repo; You must commit your changes before the export can occur.

# Deploying to remote hosts

All of the scripts accept a hostname as a final argument. If a hostname is provided,
the script will attempt to upload the exported tar file to the server. If the uplaod is
successful, the local tar file is removed.

## Configuration
If a `.gitexport.deploysettings` file is found in your local repository root, the config
values in it will be used to move files into place and set ownerhsip on the
remote server.

A `.gitexport.deploysettings` is a bash include, so white space is not trivial. It should contain the following:
```
DEPLOY_DIR=/destination/path    # Required
DEPLOY_USER=correctowner        # Required
DEPLOY_HOST=server.example.com  # Optional: Use this if the hostname of your target does not match the hostname you
                                # specify or if you want deployment to happen automatically without having to specify a
                                # hostname.
```
If a `.gitexport.deploysettings.REMOTEHOST` file is found in a repository root, and
`REMOTEHOST` matches the name of the remote host used in the gitexport command, that
file will be used instead of the generic deploysettings file.

## Usage examples
- Tar up the changes since the specified commit on the current branch, and place the tar file above the root of the repo:
  ```
  me@local:~/repo$ gitexport-sincewhen.sh c329b5dd4d3cabaae5c3d09ba313f4a506f3281a
  ```

- Tar & upload the archive to your home directory on the remote host:
  ```
  me@local:~/repo$ gitexport-sincewhen.sh c329b5dd4d3cabaae5c3d09ba313f4a506f3281a REMOTEHOST
  ```

- Tar, upload, and deploy the files (with their correct location & ownership) on the remote host:
  ```
  me@local:~/repo$ echo "DEPLOY_DIR=/home/someuser/www/project" > .gitexport.deploysettings.REMOTEHOST
  me@local:~/repo$ echo "DEPLOY_USER=someuser" >> .gitexport.deploysettings.REMOTEHOST
  me@local:~/repo$ gitexport-sincewhen.sh c329b5dd4d3cabaae5c3d09ba313f4a506f3281a REMOTEHOST
  ```
  When a .gitexport.deploysettings or .gitexport.deploysettings.REMOTEHOST file is found in the dir where gitexport-sincewhen.sh was executed, the tar file will be moved in to place on the server and extracted as the specified user.


## Removal

Uninstalling is just the reverse of installation:
```
rm ~/bin/{gitexport-latest-only.sh,gitexport-whole-repo.sh,gitexport-deploy.sh,gitexport-since-when.sh,gitexport.exclusions}
ssh REMOTEHOST 'rm ~/bin/deploy-local.sh'
```



## TODOs
- Store settings in git config instead of using (and having go ignore).gitexport* files

- Change since-when to be inclusive of the specified commit
