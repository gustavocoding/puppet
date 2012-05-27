Java Puppet Manifest
--------------------

Manifest to install java binaries from Oracle, compatible with jdk1.7.0_04 64bit. Make sure you accept the Oracle Binary Code License Agreement for the Java SE Platform 
before using this manifest. The license is located at http://www.oracle.com/technetwork/java/javase/terms/license/index.html

#### Usage

Just declare for your node:

    node "node.my.host"  {   
        include java
    }  

#### Scripts and folders

* /opt/java                         - The JAVA_HOME
* /etc/profile.d/set_java_home.sh   - Profile script to set JAVA_HOME and PATH