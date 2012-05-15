# /etc/puppet/modules/java/manifests/params.pp

class mongodb::params {

        $version = "2.0.4" 

        $arch =  "linux-x86_64" 

        $base = "/opt/mongodb/" 

        $data = "/data/mongodb/" 
}
