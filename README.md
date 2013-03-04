puppet-deployinator
===================

Deploys things with puppet.

Right now just a shell of what I want to eventually do with this module. Right 
now deployinator::git:deploy_repo does a capistrano-style deploy by checking the
repo out to $path/releases/REVISION, then symlinking $path/current to this path.

In the future, I'd like to have other subclasses that rely on the git module and
insert their own actions, such as restarting unicorn, etc.