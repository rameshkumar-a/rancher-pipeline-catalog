# GITLAB

GitLab is a web-based Git-repository manager with wiki, issue-tracking and CI/CD pipelines features, using an open-source license, developed by GitLab Inc

## Usage

* Select gitlab-ee from catalog.
* Select gitlab-ee version.
* Set the params

Click "launch"
## pre-requisites

* Should you configure send grid , create a send grid account
* Should you configure Azure Auth, configure azure auth in azure account.
    * note the following ID
        * client ID
        * Tenant ID
        * secret ID

## Rancher Catalog Description

* Installation of gitlab with additional configurations
    * PLANTUML
    * SENDGRID
    * AZURE AUTH
* To configure PLANTUML, The following values are necessary,
    *  Set the value as 'true' for the param 'PlantUML enabled'
    *  Set the port number in which PLANTUML should be exposed.
    *  Set the gilab root password
* To configure GitLab Pages, the following values are necessary
    * Set the value as 'true' for the param 'Enable Gitlab pages'
    * If enables, all the params related to GitLab pages are mandatory
* To configure SENDGRID, the following values are necessary
    * Set the value as 'true' for the param 'Sendgrid Email Enabled'
    * If enables, all the params related to sendgrid are mandatory
* To configure Azure Auth, the following values arw necessary,
    * Set the value as 'true' for the param 'Azure Auth Enabled'
    * Set the client ID
    * Set the cient secret
    * Set the tenant ID

## Detailed description of plantuml configurtion

* Ref: [Create Gitlab Personal Access Token using curl](https://gist.github.com/michaellihs/5ef5e8dbf48e63e2172a573f7b32c638)
* Access token is created using the gitlab root user and root password
* PlantUML configuration is modified using gitlab api call.
    * curl --request PUT --header "PRIVATE-TOKEN: private token" 'http://<gitlab-hostname>/api/v4/application/settings?plantuml_enabled=true&&plantuml_url=http://gitlab-hostname

## Link reference for send grid mail configuration

* Ref: [Send grid omnibus config](https://docs.gitlab.com/omnibus/settings/smtp.html)

