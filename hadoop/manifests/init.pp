# /etc/puppet/modules/hadoop/manifests/init.pp

class hadoop($slaves = 'localhost', $master = 'localhost', $mapTaskOpts = '-Xmx1G', $reduceTaskOpts = '-Xmx2G', $mapTasks = '2', $reduceTasks = '2', $jobReduceTasks = '1', $interface = 'default')  {

        $user = "hadoop"
        $group = "synapse"
        $version = "1.1.1"

        $base = "/opt/hadoop/"
  
        $dataroot = "/data/"

        $data = "$dataroot/hadoop" 

        $logs = "/data/logs/hadoop"
 
	if defined(Group[$group]) == false {
            group { "$group":
                ensure  => present
            }
        }

	if defined(File[$dataroot]) == false {
            file { "$dataroot":
                ensure  => present
		ensure => "directory",
		owner => $user, 
		group => $group, 
		alias => "dataroot",
		require => [ User["$user"], Group["$group"] ]
            }
        }

        user { "$user":
                ensure => present,
                password => "!!",
                gid => $group,
                groups => $group,
                shell => "/bin/bash",
                home => "/home/$user",
                require => Group["$group"],
        }

	file { "/home/$user":
		ensure => "directory",
		owner => $user, 
		group => $group, 
		alias => "hadoop-home",
		require => [ User["$user"], Group["$group"] ]
	}

        file { "$base":
                mode => 0777,
		ensure => "directory",
		owner => "$user",
		group => "$group",
		alias => "hadoop-base"
	}

        $data_dirs = ["$data", "$data/hdfs/", "$data/mapred", "$data/hdfs/name/", 
                      "$data/hdfs/name/current","$data/hdfs/data","$data/hdfs/namesecondary",]

        file { "$data":
    		ensure => "directory",
    		owner  => $user,
    		group  => $group,
    		mode   => 0755,
		require => File["$dataroot"]
	}

        file { "$data/hdfs":
    		ensure => "directory",
    		owner  => $user,
    		group  => $group,
    		mode   => 0755,
		require => File["$data"]
	}

        file { "$data/hdfs/name":
    		ensure => "directory",
    		owner  => $user,
    		group  => $group,
    		mode   => 0755,
		require => File["$data/hdfs"]
	}

        file { "$data/hdfs/name/current":
    		ensure => "directory",
    		owner  => $user,
    		group  => $group,
    		mode   => 0755,
		require => File["$data/hdfs/name"]
	}

        file { "$data/hdfs/data":
    		ensure => "directory",
    		owner  => $user,
    		group  => $group,
    		mode   => 0755,
		require => File["$data/hdfs"]
	}

        file { "$data/hdfs/namesecondary":
    		ensure => "directory",
    		owner  => $user,
    		group  => $group,
    		mode   => 0755,
		require => File["$data/hdfs"]
	}

        file { "$data/mapred":
    		ensure => "directory",
    		owner  => $user,
    		group  => $group,
    		mode   => 0755,
		require => File["$data"]
	}

        file { "$logs":
    		ensure => "directory",
    		owner  => $user,
    		group  => $group,
    		mode   => 0775,
	}


	exec { "hadoop-dir-owner" :
        	command  => "/bin/chown $user.$group -R ${data}hdfs && /bin/chown $user.$group -R ${data}mapred",
		require  => [File[$data_dirs],User[$user],Group[$group]]
	}

	file { "/home/$user/.ssh/":
		owner => "$user",
		group => "$group",
		mode => "700",
		ensure => "directory",
		alias => "hadoop-ssh-dir",
                require => File["hadoop-home"]
	}

	file { "/home/$user/.ssh/id_rsa.pub":
		ensure => present,
		owner => "$user",
		group => "$group",
		mode => "644",
		source => "puppet:///modules/hadoop/id_rsa.pub",
		require => File["hadoop-ssh-dir"],
	}

	file { "/home/$user/.ssh/id_rsa":
		ensure => present,
		owner => "$user",
		group => "$group",
		mode => "600",
		source => "puppet:///modules/hadoop/id_rsa",
		require => File["hadoop-ssh-dir"],
	}

	file { "/home/$user/.ssh/authorized_keys":
		ensure => present,
		owner => "$user",
		group => "$group",
		mode => "644",
		source => "puppet:///modules/hadoop/id_rsa.pub",
		require => File["hadoop-ssh-dir"],
	}	
        
	file { "${base}/hadoop-${version}.tar.gz":
		mode => 0777,
		owner => $user,
		group => $group,
		source => "puppet:///modules/hadoop/hadoop-${version}.tar.gz",
		alias => "hadoop-source-tgz",
		before => Exec["untar-hadoop"],
		require => File["hadoop-base"]
	}
        	
	exec { "untar hadoop${version}.tar.gz":
		command => "/bin/tar -zxf hadoop-${version}.tar.gz; chown -R ${user}.${group} $base/hadoop-${version}",
		cwd => $base,
		creates => "${base}/hadoop$-{version}",
		alias => "untar-hadoop",
		refreshonly => true,
		subscribe => File["hadoop-source-tgz"],
                require => File["hadoop-source-tgz"]
	}

	# start temporary to tidy up slf4j 1.4.3 deps
	exec { "rm slf4j-1.4.3":
		command => "/bin/rm -f $base/hadoop-${version}/lib/slf4j-api-1.4.3.jar $base/hadoop-${version}/lib/slf4j-log4j12-1.4.3.jar",
		alias => "rm-slf4j-1.4.3",
		refreshonly => true,
		subscribe => Exec["untar-hadoop"],
                require => Exec["untar-hadoop"]
	}
	# end temporary to tidy up slf4j 1.4.3 deps

       file { "/etc/profile.d/set_hadoop_home.sh":
                ensure => present,
                content => template('hadoop/set_hadoop_home.erb')
       }

       file { "${base}/hadoop-${version}/conf/hadoop-env.sh":
                ensure => present,
                content => template('hadoop/hadoop-env.erb'),
                require => Exec["untar-hadoop"]
       }

       file { "${base}/hadoop-${version}/conf/core-site.xml":
                ensure => present,
                owner => "$user",
                group => "$group",
                mode => "644",
                content => template('hadoop/core-site.erb'),
                alias => "site-config",
                require => Exec["untar-hadoop"],
       }

       file { "${base}/hadoop-${version}/conf/hdfs-site.xml":
                ensure => present,
                owner => "$user",
                group => "$group",
                mode => "644",
                content => template('hadoop/hdfs-site.erb'),
                alias => "ns-config",
                require => Exec["untar-hadoop"],
       }
    
       file { "${base}/hadoop-${version}/conf/mapred-site.xml":
                ensure => present,
                owner => "$user",
                group => "$group",
                mode => "644",
                content => template('hadoop/mapred-site.erb'),
                alias => "map-config",
                require => Exec["untar-hadoop"],
       }

      file { "/etc/init.d/hadoop-jobtracker":
                mode => 0744,
                ensure => present,
                content => template('hadoop/hadoop-service-jobtracker.erb')
      }

      file { "/etc/init.d/hadoop-master":
                mode => 0744,
                ensure => present,
                content => template('hadoop/hadoop-service-master.erb')
      }

      file { "${base}/hadoop-${version}/conf/slaves":
               mode => 0744,
               ensure => present,
               content => template('hadoop/slaves.erb'),
               require => Exec["untar-hadoop"]
      }

      file { "${base}/hadoop-${version}/conf/masters":
               mode => 0744,
               ensure => present,
               content => template('hadoop/masters.erb'),
               alias => "masters",
               require => Exec["untar-hadoop"]
      }

 
}
