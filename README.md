# GitExport (aka Poor man's deploy)

## Pre-requisites

- Sudo access on your remote server (preferably passwordless)
- @Todo: List other prerequisites


## Installation

1) Place the local scripts into your bin dir and make them executable:
   ```
   cp ./{gitexport-latest-only.sh,gitexport-whole-repo.sh,gitexport-deploy.sh,gitexport-since-when.sh} ~/bin/
   chmod +x ~/bin/{gitexport-latest-only.sh,gitexport-whole-repo.sh,gitexport-deploy.sh,gitexport-since-when.sh}
   ```
   Assuming `~/bin/` exists, and is in your `$PATH` environment variable.

2) Also put the exclusions file in place (it lives with the scripts, but doesn't need to be executable):
   ```
   cp -i gitexport.exclusions.example ~/bin/gitexport.exclusions
   ```
 
3) Install the remote script on any servers you want to be able to deploy to:
   ```
   ssh REMOTEHOST 'test -d ~/bin/ || mkdir ~/bin/'
   scp ./deploy-local.sh REMOTEHOST:~/bin/
   ssh REMOTEHOST 'chmod +x ~/bin/deploy-local.sh'
   ```
 
## The Scripts
- `gitexport-latest-only.sh [remotehost]`
    - Exports only the files changed in the most recent commit

- `gitexport-since-when.sh <hash-value> [remotehost]`
    - Exports all the files modified or added since the specified hash value.

- `gitexport-whole-repo.sh [remotehost]`
    - Exports the entire repo, minus any paths matched in the exclusions file.

- `gitexport-deploy.sh <remotehost>`
    - Called by the above 3 scripts to push the tar file up to the remote server, and optionally put the files in place on the remote host.

- `deploy-local.sh <@args>`:
    - Executed by `gitexport-deploy.sh` on the remote host.

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
DEPLOY_DIR=/parent/path/of/repo # Required *** See note about paths below ***
DEPLOY_USER=correctowner        # Required
DEPLOY_HOST=server.example.com  # Optional: Use this if the hostname of your target does not match the hostname you
                                # specify or if you want deployment to happen automatically without having to specify a
                                # hostname.
```
If a `.gitexport.deploysettings.REMOTEHOST` file is found in a repository root, and
`REMOTEHOST` matches the name of the remote host used in the gitexport command, that
file will be used instead of the generic deploysettings file.

## Paths (pay attention; you'll probably get this wrong)
The `DEPLOY_DIR` is **NOT** the path to the root of the repository. It is the **PARENT** of the repository on the remote host.

If your local repository and remote final destination paths look like this:
```
/home/me/repos/company_a/project_1  <-- path to local repo root
/home/company_a/www/project_1       <-- corresponding remote path
```
Then, THIS is the `DEPLOY_DIR` you need to use:
```
/home/company_a/www                 <-- THIS is the correct DEPLOY_DIR you need to use
```

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
  me@local:~/repo$ echo "DEPLOY_DIR=/home/someuser/www" > .gitexport.deploysettings.REMOTEHOST
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



## TODO
1) Merge both 'deploy' files in to a single script to reduce the confusion.
   The same script will live on local and remote machines, but will behave differently
   depending on the context. The name of the script that lives on the remote end is a little misleading;
   You'd think 'deploy-local.sh' is a script that should live on your machine, but
   in fact 'local' refers to the fact that it doesn't reach out to any remote hosts.

2) Deal with / fix the paths issue. It's confusing as hell.

3) After merging the deploy files, change deploy so it uploads itself, execute, and then removes itself
   as part of the deploy process, so it doesnt need to live on the remote server.
