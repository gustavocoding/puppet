# /etc/puppet/modules/mongodb/manifests/init.pp

class mongodb($replicaset = "undefined", $numa = "undefined") {

        require mongodb::params

	$mongo_tgz = "mongodb-${mongodb::params::arch}-${mongodb::params::version}.tar.gz"
        $base_dir = "${mongodb::params::base}"
        $data_dir = "${mongodb::params::data}"

        group { "mongodb":
        	ensure  => present
	}

	user{ "mongodb": 
        	ensure  => present, 
                gid   => "mongodb",
        	shell   => "/sbin/nologin" 
	} 
	
        file { "$base_dir":
		ensure => "directory",
		owner => "mongodb",
		group => "mongodb",
		alias => "mongo-base"
	}
        
       file { "/data": 
		ensure => "directory",
		owner => "mongodb",
		group => "mongodb",
                alias => "data-root"
	}

        file { "$data_dir": 
		ensure => "directory",
		owner => "mongodb",
		group => "mongodb",
                alias => "mongo-data",
                require => File["data-root"]
	}

        file { "$data_dir/logs": 
		ensure => "directory",
		owner => "mongodb",
		group => "mongodb",
                alias => "mongo-logs"
	}

        file { "$data_dir/logs/mongo.log":
		ensure => "present",
		owner => "mongodb",
		group => "mongodb",
		alias => "mongo-logfile"
	}

        file { "$base_dir/${mongo_tgz}":
                mode => 0644,
                owner => mongodb,
                group => mongodb,
                source => "puppet:///modules/mongodb/${mongo_tgz}",
                alias => "mongodb-source-tgz",
                before => Exec["untar-mongo"],
                require => File["mongo-base"]
        }

	exec { "untar ${mongo_tgz}":
                command => "/bin/tar -zxf ${mongo_tgz}",
                cwd => "$base_dir",
                creates => "$base_dir/mongodb",
                alias => "untar-mongo",
                refreshonly => true,
                subscribe => File["mongodb-source-tgz"],
        }
      
        file { "/etc/init.d/mongodb":
                mode => 0744,
                ensure => present,
                content => template('mongodb/mongodb.erb')
       }

        file { "/etc/profile.d/set_mongo_path.sh":
                ensure => present,
                content => template('mongodb/set_mongo_path.erb')
       }




}
