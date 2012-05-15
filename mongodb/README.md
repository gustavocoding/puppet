MongoDB puppet manifest
=======================

Simple manifest to install MongoDB  


Usage:  

node "node.my.host"  {  

    class { 'mongodb': 

         numa => 'yes',  

         replicaset => 'myReplSet'  

    }   

}  
