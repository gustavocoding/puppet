MongoDB puppet manifest
-----------------------


Manifest to manage MongoDB. It supports only Linux, because I don't believe in running Windows or MacOS in production servers.


#### Configuration ####

Edit the file manifests/params.pp and specify mongoDB's version and linux architecture ( i686, x86_64 or i386 )

#### Usage

Just declare for your node:

	node "node.my.host"  {   
		class { 'mongodb':   
			numa => 'yes',  
			replicaset => 'myReplSet'  
		}   
	}   
	
Parameters:

* *numa* - Indicates if NUMA should be turned on|off (See http://www.mongodb.org/display/DOCS/NUMA for more details)
* *replicaset* - The name of the replicaSet that the server will be part (See http://www.mongodb.org/display/DOCS/Replica+Sets)
              
#### Scripts and Folders

* /etc/init.d/mongodb - Init script. MongoDB runs under 'mongodb' user and group
* /opt/mongodb        - Installation folder
* /data/mongodb       - data files
* /data/mongodb/logs  - log files
                      

