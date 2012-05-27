
class java {

 	$release = "7u4-b20"
        $arch = "jdk-7u4-linux-x64"
        $packaging = "tar.gz"
        $url = "http://download.oracle.com/otn-pub/java/jdk/7u4-b20/jdk-7u4-linux-x64.tar.gz"
        $base = "/opt/java"
        $extract = "jdk1.7.0_04"
	
        file { "$base":
                mode   => 0755,
		ensure => "directory",
		owner  => "root",
		group  => "root",
		alias  => "java-base"
	}

        exec {
               "download-java" :
               command  => "/usr/bin/wget --no-cookies --header 'Cookie: gpw_e24=oracle' http://download.oracle.com/otn-pub/java/jdk/${release}/${arch}.${packaging} -P $base/",
               alias    => "java-source-tgz",
               before   => Exec["untar-java"],
               timeout  => -1,
	       creates  =>  "$base/${arch}.${packaging}",
               require  => File["java-base"],
        }

        
	exec { "untar $base/${arch}.${packaging}":
		command     => "/bin/tar -zxf $base/${arch}.${packaging}",
		cwd         => "$base",
		alias       => "untar-java",
                require     => Exec["download-java"],
		#before     => File["java-app-dir"],
	}


       file { "/etc/profile.d/set_java_home.sh":
    		ensure   => present,
                mode     => 755,
                content  => template('java/set_java_home.erb') 
       }

}
