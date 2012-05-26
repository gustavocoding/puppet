# /etc/puppet/modules/mongodb/manifests/init.pp

class mongodb($replicaset = "undefined", $disablenuma = "undefined") {

        require mongodb::params

	$mongo_tgz = "mongodb-${mongodb::params::arch}-${mongodb::params::version}.tgz"
        $base_dir = "${mongodb::params::base}"
        $data_dir = "${mongodb::params::data}"

	$log_path = "$data_dir/logs/mongo.log"

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

        file { "$base_dir/conf":
               ensure => "directory",
               owner => "mongodb",
               group => "mongodb",
               alias => "mongo-conf",
                require => File[$base_dir]
        }

        file { "$base_dir/conf/mongo.conf":
                mode => 0744,
                ensure => present,
                content => template('mongodb/mongodb.conf.erb')
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
   
        exec {
               "download-mongo" :
               command  => "/usr/bin/wget http://downloads.mongodb.org/linux/${mongo_tgz} -N -P $base_dir/ && chown -R mongodb.mongodb $base_dir",
               alias => "mongodb-source-tgz",
               before => Exec["untar-mongo"],
               require => File["mongo-base"],
        }

	exec { "untar ${mongo_tgz}":
                command => "/bin/tar -zxf ${mongo_tgz} && chown -R mongodb.mongodb $base_dir",
                cwd => "$base_dir",
                creates => "$base_dir/mongodb",
                alias => "untar-mongo",
                refreshonly => true,
                subscribe => Exec["mongodb-source-tgz"],
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
