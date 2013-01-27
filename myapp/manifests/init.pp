
class myapp($maven_repo,$version) {

        $base = "/opt"
 	$installDir = "$base/myapp"
	$artifact = "hadoop-sample"
	
        file { "$base":
                mode   => 0755,
		ensure => "directory",
		owner  => "root",
		group  => "root",
	}

 
	file { "${installDir}":
		owner  => "root",
		group  => "root",
		ensure => "directory",
		recurse => "remote",
		alias  => "install",
		source => "puppet:///modules/myapp/",
		require => File["$base"]
        }	


	maven { "download-artifact":
  		  groupid    => "com.gustavonalle",
    		  artifactid => "$artifact",
    		  version    => "1.0-SNAPSHOT",
    		  repos      => "${maven_repo}",
    		  directory  => "${installDir}",
		  require    => File["install"]
  	}


       file { "${installDir}/run-hadoop.sh":
    		ensure   => present,
                mode     => 755,
		content  => template('myapp/run-hadoop.erb'),
		require  => File["install"]
       }

}
