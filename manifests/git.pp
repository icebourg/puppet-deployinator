# Do a capistrano-style deploy out of a git repo

class deployinator::git {

  define deploy_repo (
    $path,
    $repo,
    $deploy_key,
    $branch	= "master",
  )
  {
    # Deploy to $path/releases/REVISION
    # where revision is the tag of the latest commit to the branch $revision
    exec { "deploy-$title":
      command => "mkdir -p $path/releases/$(git ls-remote $repo $branch | cut -f1) && git clone $repo $path/releases/$(git ls-remote $repo $branch | cut -f1)",
      unless  => "test -d $path/releases/$(git ls-remote $repo $branch | cut -f1)",
      path    => ["/usr/bin/", "/bin"],
      notify  => Exec["set-symlink-$title"]
    }
  
    # now link current to the directory above
    # this is exec so we can catch the output of REVISION
    # we also do this here so we can in other classes set a dependency on restarting some service...
    # We do an ln with current_tmp and use mv to make the switch atomic -- see this post for details:
    # http://blog.moertel.com/posts/2005-08-22-how-to-change-symlinks-atomically.html
    exec { "set-symlink-$title":
      command     => "ln -s $path/releases/$(git ls-remote $repo $branch | cut -f1) $path/current_tmp && mv -Tf $path/current_tmp $path/current",
      refreshonly => true,
      path        => ["/usr/bin/", "/bin"],
    }
  }
  
}
