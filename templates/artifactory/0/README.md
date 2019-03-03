# Artifactory

Artifactory is a universal Binary Repository Manager for use by build tools (like Maven and Gradle), dependency management tools (like Ivy and NuGet) and build servers (like Jenkins, Hudson, TeamCity and Bamboo).

Repository managers serve two purposes: they act as highly configurable proxies between your organization and external repositories and they also provide build servers with a deployment destination for your internally generated artifacts.

This catalog launches JFrog Artifactory PRO Application.  

## Usage

* Select Enable HA. if you wish to launch arifactory with HA mode, selct true.
* Select Artifactory DNS. If you need to map the Artifactory app to DNS name, select true. 
* Set Artifactory Hostname. If you have selected 'Artifactory DNS' as true, this value will be considered as hostname to publish artifactory app. If you have selected 'Artifactory DNS' as false, ignore this field.
* Domain to register. If you have selected 'Artifactory DNS' as true, this value will be considered as domain to register the hostname. If you have selected 'Artifactory DNS' as false, ignore this field.
* Set Postgres DB Username.
* Set Postgres DB Password.
* Select Volume Driver where you wish to persist artifactory and postgres data.

## Notes

* You need a certificate imported in rancher enviroment before deploy this package.
* If you use self signed certificates, you should implement self-signed-certificates in your hosts.
* If you use http schema, you should implement [insecure-registry][insecure-registry] in your hosts.
* KNOWN LIMITATION: "SSL certificate" is required for http and https publish schema.

## How to use

TBD

## SUPPORT

TBD


