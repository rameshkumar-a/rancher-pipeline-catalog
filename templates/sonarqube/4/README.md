## What is inside SonarQube Stack?
* [SonarQube Server](http://www.sonarqube.org/) + Sidekick for download and storing plugins
* Postgres Database + Sidekick for storing data

## Info
* In default SonarQube package will install alpine docker version and will create "sonar" postgres database, user and password. 
* Once SonarQube will start, make sure you setup correct information in setup page.
* For easy upgrades there are sidekicks for postgres data with dedicated storage. 


## First Start
* Use admin/admin to login to the SonarQube interface.
