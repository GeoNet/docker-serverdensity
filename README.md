# Docker with ServerDensity agent (sd-agent)

[![Docker Repository on Quay](https://quay.io/repository/geonet/serverdensity/status "Docker Repository on Quay")](https://quay.io/repository/geonet/serverdensity)

This is a CentOS-7 based Docker image with an installed sd-agent. Use it if you want to monitor your server with [ServerDensity.io](https://www.serverdensity.com/).

Borrowed heavily from [DataDog/docker-dd-agent](https://github.com/DataDog/docker-dd-agent) after starting with [million12/serverdensity](https://github.com/million12/docker-serverdensity).

## Customise with environmental variables 

##### ACCOUNT
The name of your organization account, i.e. https://ACCOUNT.serverdensity.io
  
##### API_KEY  
API key for the account. Note: this is an *API key*, **not** an *agent key* (the latter is per-device). Generate your API key under:  
ServerDensity panel -> Preferences -> Security -> API tokens.

##### GROUPNAME (optional)  
Group name in ServerDensity. If not provided, server will be listed in the 'Ungrouped' group.


## Usage

`docker run -d --net=host --env="API_KEY=api-key" --env="ACCOUNT=name" quay.io/geonet/serverdensity

Note 2: `--net=host` gives access to all host network interfaces (and inside the container sets the hostname to the same as hosts' hostname). This is to allow sd-agent reporting about network traffic. Read the Docker doc about potential security issues with it.


