# GitExport (aka Poor man's deploy)

## Pre-requisites

- Sudo access on your remote server
- If you can't `make`, you'll need to just copy files in to place + chmod them
- @ToDo: List other prerequisites


## Installation

1) Install local scripts:
```
make -s install
```
If you can't `make`, just copy all the .sh files into your local `bin` dir and `chmod +x` them


2) Install the remote script:
```
ssh REMOTEHOST 'test -d ~/bin/ || mkdir ~/bin/'
scp ./deploy-local.sh REMOTEHOST:~/bin/
```
Do this for as many remote hosts as you need to be able to deploy to.


## Usage Examples
```
me@local:~/repo$ gitexport-sincewhen.sh c329b5dd4d3cabaae5c3d09ba313f4a506f3281a
```
Tars up the changes since the specified hash, and puts the tar file above the root of the repo.

```
me@local:~/repo$ gitexport-sincewhen.sh c329b5dd4d3cabaae5c3d09ba313f4a506f3281a REMOTEHOST
```
Does the same as the first example, then uploads the tar archive to the remote host.


## Removal

Uninstalling is just the reverse of the above:
```
cd path/to/this/repo
make -s uninstall
ssh REMOTEHOST 'rm ~/bin/deploy-local.sh'
```



## Misc
The name of the script that lives on the remote end is a little misleading;
You'd think 'deploy-local.sh' is a script that should live on your machine, but
in fact 'local' refers to the fact that it doesn't reach out to any remote hosts.

## TODO

Merge both 'deploy' files in to a single script to reduce the confusion.
The same script will live on local and remote machines, but will behave differently
depending on the context.
