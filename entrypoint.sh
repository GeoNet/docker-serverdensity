#!/bin/bash
trap "exit" INT TERM EXIT


function configure_agent() {
    echo "Configuring agent"

    cat - > /etc/sd-agent/config.cfg <<EOF
#
# Server Density Agent Config
#
[Main]
# The Server Density account where this device is used.
# Only the account name, e.g. abc not abc.serverdensity.io
sd_account: $ACCOUNT
# The Server Density agent key to associate your Agent's data with a device
# on your account.
agent_key: $AGENTKEY
#
# Custom Plugins
#
# Leave blank to ignore.
# See https://support.serverdensity.com/hc/en-us/articles/213074438-Information-about-Custom-Plugins
#
plugin_directory:
# ========================================================================== #
# Logging
# See https://support.serverdensity.com/hc/en-us/articles/213093038-Log-levels-agent-debug-mode
# ========================================================================== #
# log_level: INFO
# collector_log_file: /var/log/sd-agent/collector.log
# forwarder_log_file: /var/log/sd-agent/forwarder.log
# if syslog is enabled but a host and port are not set, a local domain socket
# connection will be attempted
#
# log_to_syslog: yes
# syslog_host:
# syslog_port:
EOF

echo "Agent Configured ..."
}

function get_existing_device() {

    RESULT=$(curl -v "https://api.serverdensity.io/inventory/resources/?token=$1&filter=$2")
    exit_status=$?

    # an exit status of 1 indicates an unsupported protocol. (e.g.,
    # https hasn't been baked in.)
    if [[ "$exit_status" -eq "1" ]]; then
        echo "Your local version of curl has not been built with HTTPS support: $(command -v curl)"
        exit 1

    # if the exit code is 7, that means curl could not connect so we can bail
    elif [[ "$exit_status" -eq "7" ]]; then
        echo "Could not connect to create server"
        exit 1

    # it appears that an exit code of 28 is also a can't connect error
    elif [[ "$exit_status" -eq "28" ]]; then
        echo "Could not connect to create server"
        exit 1

    elif [[ "$exit_status" -ne "0" ]]; then
        echo "Error connecting to api.serverdensity.io; status $exit_status."
        exit 1
    fi

    AGENTKEY=$(echo "$RESULT" | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w agentKey | cut -d"|" -f2| sed -e 's/^ *//g' -e 's/ *$//g')

    if [[ "$AGENTKEY" = "401" ]]; then
        echo "Authentication error: $OUTPUT"
        echo "Verify that you have passed in the correct account URL and API token"
        exit 1 

    elif [[ "$AGENTKEY" = "403" ]]; then
        echo "Forbidden error: $OUTPUT"
        echo "Verify that you have passed in the correct account URL and API token"
        exit 1
    fi
}

if [[ -z "$ACCOUNT" ]]; then
    echo "Account name is missing."
    echo ""
	exit 1
fi

if [[ -z "$AGENTKEY" ]]; then

    if [[ "${API_KEY}" = "" ]]; then 
        echo "If you don't pass an agent key (with -k) you must pass an API token (with -t)"
        echo "See https://support.serverdensity.com/hc/en-us/articles/214862137-Automatic-agent-installation-Shell-script-API"
        echo ""
        exit 1
    fi

    if [[ "${HOSTNAME}" = "" ]]; then
        echo "Host does not appear to have a hostname set!"
        exit 1
    fi

    echo ""
    echo "Using API key $API_KEY to automatically create device with hostname ${HOSTNAME}"
    echo ""

    TAG_ARG=""
    GROUP_ARG=""
    CLOUD_ARG=""

    if [[ "${TAGNAME}" != "" ]]; then

        TAGS=$(curl --silent -X GET https://api.serverdensity.io/inventory/tags?token="${API_KEY}")

        # very messy way to get the tag ID without using any json tools
        TAGID=$(echo "$TAGS" | sed -e $'s/},{/\\\n/g'| grep -i "$TAGNAME" | sed 's/.*"_id":"\([a-z0-9]*\)".*/\1/g')

        if [[ ! -z "$TAGID" ]]; then
            echo "Found $TAGNAME, using tag ID $TAGID"

        else

            MD5=$(command -v md5sum)
            HEX="#$(echo -n "$TAGNAME" | "$MD5" | cut -c1-6)"

            echo "Creating tag $TAGNAME with random hex code $HEX"
            TAGS=$(curl --silent -X POST https://api.serverdensity.io/inventory/tags?token="$API_KEY" --data "name="$TAGNAME"&color="$HEX"")

            TAGID=$(echo "$TAGS" | grep -i "$TAGNAME" | sed 's/.*"_id":"\([a-z0-9]*\)".*/\1/g')
            echo "Tag cretated, using tag ID $TAGID"

        fi
        TAG_ARG="&tags=[\"${TAGID}\"]"
    fi

    if [[ "${GROUPNAME}" != "" ]]; then
        GROUP_ARG="&group=${GROUPNAME}"
    fi

	FILTER="\{\"name\":\"${HOSTNAME}\",\"type\":\"device\"\}"
	get_existing_device "${API_KEY}" "${FILTER}"

    if [[ "${AGENTKEY}" = "" ]]; then
        RESULT=$(curl --silent https://api.serverdensity.io/inventory/devices/?token="${API_KEY}" --data "name=${HOSTNAME}${GROUP_ARG}${TAG_ARG}${CLOUD_ARG}")
        exit_status=$?

        # an exit status of 1 indicates an unsupported protocol. (e.g.,
        # https hasn't been baked in.)
        if [[ "$exit_status" -eq "1" ]]; then
            echo "Your local version of curl has not been built with HTTPS support: $(command -v curl)"
            exit 1

        # if the exit code is 7, that means curl couldnt connect so we can bail
        elif [[ "$exit_status" -eq "7" ]]; then
            echo "Could not connect to create server"
            exit 1

        # it appears that an exit code of 28 is also a can't connect error
        elif [[ "$exit_status" -eq "28" ]]; then
            echo "Could not connect to create server"
            exit 1

        elif [[ "$exit_status" -ne "0" ]]; then
            echo "Error connecting to api.serverdensity.io; status $exit_status."
            exit 1
        fi

        AGENTKEY=$(echo "$RESULT" | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w agentKey | cut -d"|" -f2| sed -e 's/^ *//g' -e 's/ *$//g')

        if [[ "$AGENTKEY" = "" ]]; then
            echo "Unknown error communicating with api.serverdensity.io: $OUTPUT"
            exit 1

        elif [[ "$AGENTKEY" = "401" ]]; then
            echo "Authentication error: $OUTPUT"
            echo "Verify that you have passed in the correct account URL and API token"
            exit 1

        elif [[ "$AGENTKEY" = "403" ]]; then
            echo "Forbidden error: $OUTPUT"
            echo "Verify that you have passed in the correct account URL and API token"
            exit 1
        fi
    fi
fi


configure_agent

rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi

export PATH="/usr/share/python/sd-agent/bin:$PATH"
exec "$@"
