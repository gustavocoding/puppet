MongoDB puppet manifest
-----------------------


Manifest to manage MongoDB. It supports only Linux, because I don't believe in running Windows or MacOS in production servers.


#### Configuration ####

Edit the file manifests/params.pp and specify mongoDB's version and linux architecture ( i686, x86_64 or i386 )

#### Usage

Just declare for your node:

	node "node.my.host"  {   
		class { 'mongodb':   
			disablenuma => 'yes',  
			replicaset => 'myReplSet'  
		}   
	}   
	
Parameters:

* *disablenuma* - Indicates if NUMA should be turned off (See http://www.mongodb.org/display/DOCS/NUMA for more details)
* *replicaset* - The name of the replicaSet that the server will be part (See http://www.mongodb.org/display/DOCS/Replica+Sets)
              
#### Scripts and Folders

* /etc/conf/mongodb.conf  - Configuration file. For a detailed syntax see
* /etc/init.d/mongodb     - Init script. MongoDB runs under 'mongodb' user and group
* /opt/mongodb            - Installation folder
* /data/mongodb           - data files
* /data/mongodb/logs      - log files
                          
#### TODO

* Make the init script generic - currently is for Suse Linux only
* Support sharding
* Externalise the version as a parameter

