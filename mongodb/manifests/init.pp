class mongodb($primary,$secondaries,$arbiter,$replicaset = "undefined", $disablenuma = "undefined") {

  	$version = "2.2.2"
        $arch =  "linux-x86_64"
        $user = "mongodb"
	$group = "mongodb"
        $basedir = "/opt/mongodb"
        $datadir = "/datadb/mongodb"

        $installdir = "${basedir}/mongodb-$arch-$version"
	$mongo_tgz = "mongodb-${arch}-${version}.tgz"

	$log_path = "$datadir/logs/mongo.log"

        group { "$group":
        	ensure  => present
	}

	user{ "$user": 
        	ensure  => present, 
                gid   => "$group",
        	shell   => "/sbin/nologin" 
	} 

	$basedirs = ["$basedir", "$installdir", "$installdir/conf"]
	
        file { $basedirs:
		ensure => "directory",
		owner => "$user",
		group => "$group",
		require => [ User["$user"], Group["$group"] ]
	}


        file { "$installdir/conf/mongo.conf":
                mode => 0744,
                ensure => present,
		alias => "mongodb-config-file",
                content => template('mongodb/mongodb.conf.erb'),
        }

        file { "$installdir/bin/create-replica.sh":
                mode => 0755,
		owner => "$user",
		group => "$group",
                ensure => present,
		require => [Exec["untar-mongo"]],
                content => template('mongodb/create-replica.erb'),
        }
        
        $datadirs = [ "/datadb", "$datadir", "$datadir/logs" ]

        file { $datadirs: 
		ensure => "directory",
		owner => "$user",
		group => "$group",
        }

        file { "$datadir/logs/mongo.log":
		ensure => "present",
		owner => "$user",
		group => "$group",
		alias => "mongo-logfile",
		require => File[$datadirs]
        }
   
	file { "${basedir}/${mongo_tgz}" :
		mode   => 0744,
		ensure => present,
		owner  => "$user",
		group  => "$group",
		alias  => "mongo_tgz",
                before => Exec["untar-mongo"],
		source => "puppet:///modules/mongodb/${mongo_tgz}",
                require => File[$basedirs],
	}

	exec { "untar ${mongo_tgz}":
                command => "/bin/tar xvf ${basedir}/${mongo_tgz}  && chown -R $user.$group $basedir",
		cwd => $basedir,
                alias => "untar-mongo",
                refreshonly => true,
                subscribe => File["mongo_tgz"],
        }
      
        file { "/etc/init.d/mongodb":
                mode => 0744,
                ensure => present,
		alias  => "init-script",
                content => template('mongodb/mongodb.erb')
        }

        file { "/etc/profile.d/set_mongo_path.sh":
                ensure => present,
		alias  => "mongo_path",
                content => template('mongodb/set_mongo_path.erb')
        }

	service { "mongodb":
		ensure  => running,
		require => [File["mongodb-config-file"],File["mongo_path"],Exec["untar-mongo"],File[$basedirs],File[$datadirs],File["init-script"]]
	}

}
