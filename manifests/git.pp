# Do a capistrano-style deploy out of a git repo

class deployinator::git {

  define deploy_repo (
    $path,
    $repo,
    $deploy_key = false,
    $user   = "www-data",
    $group  ="www-data",
    $branch = "master",
  )
  {
    
    # create the user
    user { "${title}-user":
      name    => $user,
      home    => $path,
    }
    
    # and the group
    group { "${title}-group":
      name    => $group,
      require => User["${title}-user"]
    }
    
    # add the deploy key (if any)
    if $deploy_key {
      
       file {"${title}-path":
        ensure  => "directory",
        path    => "$path",
        owner   => $user,
        group   => $group,
        require => Group["${title}-group"],
      }
      
      $key_path = "$path/deploy_key"
      $ssh_wrapper = "$path/ssh-wrapper"
    
      file { "${title}-deploy-key":
        path    => $key_path,
        content => $deploy_key,
        mode    => "0600",
        owner   => $user,
        group   => $group,
        require => File["${title}-path"],
      }
      
      # install the ssh wrapper
      file { "${title}-wrapper":
        path    => $ssh_wrapper,
        content => template("deployinator/git-ssh-wrapper.sh.erb"),
        mode    => "0755",
        owner   => $user,
        group   => $group,
        require => File["${title}-deploy-key"],
      }
      
      # the next two execs seem like GREAT candidates for a definition
      # so we don't have to repeat them for just changing GIT_SSH
      
      exec { "deploy-with-key-$title":
        command     => "mkdir -p $path/releases/$(git ls-remote $repo $branch | cut -f1) && git clone $repo $path/releases/$(git ls-remote $repo $branch | cut -f1)",
        unless      => "test -d $path/releases/$(git ls-remote $repo $branch | cut -f1)",
        path        => ["/usr/bin/", "/bin"],
        notify      => Exec["set-symlink-$title"],
        require     => File["${title}-wrapper"],
        environment => ["GIT_SSH=$ssh_wrapper"],
        logoutput   =>  true,
      }
      
      # now link current to the deployed directory above
      # this is exec so we can catch the output of REVISION
      # we also do this here so we can in other classes set a dependency on restarting some service...
      # We do an ln with current_tmp and use mv to make the switch atomic -- see this post for details:
      # http://blog.moertel.com/posts/2005-08-22-how-to-change-symlinks-atomically.html
      exec { "set-symlink-$title":
        command     => "ln -s $path/releases/$(git ls-remote $repo $branch | cut -f1) $path/current_tmp && mv -Tf $path/current_tmp $path/current",
        refreshonly => true,
        path        => ["/usr/bin/", "/bin"],
        environment => ["GIT_SSH=$ssh_wrapper"],
        logoutput   =>  true,
      }
      
    } else {
      # don't use an ssh wrapper
      exec { "deploy-$title":
        command   => "mkdir -p $path/releases/$(git ls-remote $repo $branch | cut -f1) && git clone $repo $path/releases/$(git ls-remote $repo $branch | cut -f1)",
        unless    => "test -d $path/releases/$(git ls-remote $repo $branch | cut -f1)",
        path      => ["/usr/bin/", "/bin"],
        notify    => Exec["set-symlink-$title"],
        logoutput =>  true
      }
      
      # now link current to the deployed directory above
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
}
