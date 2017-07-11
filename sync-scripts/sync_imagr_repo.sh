#!/bin/bash

########################################
# Variables
########################################

# AWS Credentials
AWS_ACCESS_KEY_ID="$4"
AWS_SECRET_ACCESS_KEY="$5"
AWS_DEFAULT_REGION="us-west-2"

# Location of AWS CLI binary
aws_binary="/usr/local/bin/aws"

# Directory of local Imagr repo on server
imagr_path="/Library/Server/Web/Data/Sites/Default/imagr/"

# S3 bucket and path containing master Imagr repo
s3_bucket_url="$6"

########################################
# Functions
########################################

verify_binary () {

    # Check that the aws cli is installed

    if [[ ! -f "$aws_binary" ]]; then
        echo "Installing AWS CLI..."

        # Download AWS CLI zip file
        /usr/bin/curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "/tmp/awscli-bundle.zip"

        # Unzip the downloaded file
        /usr/bin/unzip /tmp/awscli-bundle.zip -d /tmp

        # Install unzip'd files
        /tmp/awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

        # Check again, exit if not found
        if [[ ! -f "$aws_binary" ]]; then
            echo "AWS CLI still not found. Exiting."
            exit 1
        fi
    fi
}

export_creds () {
    
    # Export AWS credentials for use with the
    # AWS CLI

    export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
    export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
    export AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION"
}

sync_repo () {

    # Sync the S3 directory to local fileshare and
    # delete deprecated images and pkgs.

    if [[ ! -d "$imagr_path" ]]; then
        /bin/mkdir "$imagr_path"
    fi

    "$aws_binary" s3 sync "$s3_bucket_url" "$imagr_path" --delete --quiet
}

update_config () {

    # Update the imagr_config.plist file
    # replacing {{SERVER_URL}} with the IP
    # of the local server
    
    # Find IP address
    serverIP=$(/usr/bin/facter ipaddress)

    if [[ ! -f "${imagr_path}config/imagr_config.plist" ]]; then
        echo "Config file is not found. Is the Data volume missing?"
        exit 1
    else
        # Replace {{SERVER_URL}} with actual IP of server
        /usr/bin/sed -i '' -e "s/{{SERVER_URL}}/${serverIP}/g" "${imagr_path}config/imagr_config.plist"
    fi
}

########################################
# Code Execution
########################################

verify_binary
export_creds
sync_repo
update_config

exit 0