#!/bin/bash

# # # # #
#
# This script connects to a Gitlab self-hosted instance and cleans a user specified container
# registry.  Gitlab has lifecycle rules for registries now, which can accomplish
# much the same thing, but this script is useful when you want to bulk delete
# items immediately.
#
# Configure options for this script in the config.sh file.  A sample config file is provided.
#
# Unknown if this works or applies to Gitlab.com.
#
# Author:      10up, Inc.
# Author URI:  https://10up.com
# Version:     1.0.0
# License:     MIT
# License URI: https://opensource.org/licenses/MIT
#
# # # # #

set -e
set -u
set -o pipefail


#
# Get options from the config file
#

# Define the path to the config file relative to the main script and include it
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/config.sh"

# If expiration is set less than 1 day, set the seconds to 1 to make all the rest of the math work
if [ ${EXPIRATION_DAYS} -lt 1 ]
then
  EXPIRATION_SECONDS=1
fi

# Check if the required variables are set, or if they are the default values
if [ -z ${GITLAB_URL} ]
then
  echo 'ERROR: Required variable GITLAB_URL not set in the config.sh file'
  exit 1
fi
if [ ${GITLAB_URL} == 'https://gitlab.example.com' ]
then
  echo 'ERROR Required variable GITLAB_URL detected to be the default value in the config.sh file'
  exit 1
fi
if [ -z ${GITLAB_AUTH_TOKEN} ]
then
  echo 'ERROR: Required variable GITLAB_AUTH_TOKEN not set in the config.sh file'
  exit 1
fi
if [ ${GITLAB_AUTH_TOKEN} == 'xxxxxxxxxxxxx' ]
then
  echo 'ERROR: Required variable GITLAB_AUTH_TOKEN detected to be the default value in the config.sh file'
  exit 1
fi
if [ -z ${GITLAB_PROJECT_ID} ]
then
  echo 'ERROR: Required variable GITLAB_PROJECT_ID not set in the config.sh file'
  exit 1
fi
if [ ${GITLAB_PROJECT_ID} == '<project-id-number>' ]
then
  echo 'ERROR: Required variable GITLAB_PROJECT_ID detected to be the default value in the config.sh file'
  exit 1
fi
if [ -z ${GITLAB_REGISTRY_ID} ]
then
  echo 'ERROR: Required variable GITLAB_REGISTRY_ID not set in the config.sh file'
  exit 1
fi
if [ ${GITLAB_REGISTRY_ID} == '<registry-id-number>' ]
then
  echo 'ERROR: Required variable GITLAB_REGISTRY_ID detected to be the default value in the config.sh file'
  exit 1
fi
if [ -z ${EXPIRATION_DAYS} ]
then
  echo 'ERROR: Required variable EXPIRATION_DAYS not set in the config.sh file'
  exit 1
fi
if [ ${EXPIRATION_DAYS} == '###' ]
then
  echo 'ERROR: Required variable EXPIRATION_DAYS detected to be the default value in the config.sh file'
  exit 1
fi
# Convert DRY_RUN variable to upper case for eaiser comparison
DRY_RUN=$(echo ${DRY_RUN} | tr [a-z] [A-Z])

if [ ${DRY_RUN} == 'TRUE' ]
then
  echo "~~ Running in dry-run simulation mode ~~"
  echo ""
fi

#
# Convert expiration time into seconds
#

EXPIRATION_SECONDS=$(expr ${EXPIRATION_DAYS} \* 86400)

echo "Tags / images older than ${EXPIRATION_SECONDS} seconds (${EXPIRATION_DAYS}) will be deleted"

#
# Get a list of container names (aka tags), put in an array
#

# Deal with pagination
thispage=1 #variable for tracking the page we are on
nextpage=1 #variable for tracking the next page (if exists)
declare -a imagenames
while [ ${nextpage} -gt 0 ]
do
  echo "Getting image names page ${thispage}..."
  # add items to the array
  oldifs="$IFS"
  IFS=$'\n'
  newimagenames=($(curl --silent --location --request GET "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/registry/repositories/${GITLAB_REGISTRY_ID}/tags/?per_page=500&page=${thispage}" --header "Authorization: Bearer ${GITLAB_AUTH_TOKEN}" | jq '.[].name'))
  oldifs="$IFS"
  imagenames=("${imagenames[@]-}" "${newimagenames[@]}")

  # Check if there's another page
  nextpage=$(curl -I --silent --location --request GET "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/registry/repositories/${GITLAB_REGISTRY_ID}/tags/?per_page=500&page=${thispage}" --header "Authorization: Bearer ${GITLAB_AUTH_TOKEN}" | grep -Fi X-Next-Page | sed -r 's/X-Next-Page:\ //' )
  nextpage="${nextpage//[$'\t\r\n ']}" #clean the variable of extraneous characters
  if [ -z ${nextpage} ]
  then
    nextpage=0
  fi
  thispage=${nextpage}

done


# Loop through array of image names
for imagename in "${imagenames[@]}"
do
  # Go to next iteration of loop if the imagename is blank
  if [ -z ${imagename} ]
  then
    continue
  fi

  # Trim quotes from variable
  imagename="${imagename%\"}"
  imagename="${imagename#\"}"

  # Get the date that the tag was created
  created_date=$(curl --silent --location --request GET "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/registry/repositories/${GITLAB_REGISTRY_ID}/tags/${imagename}" --header "Authorization: Bearer ${GITLAB_AUTH_TOKEN}" | jq '.created_at')

  # Trim quotes from variable
  created_date="${created_date%\"}"
  created_date="${created_date#\"}"

  # convert the tag date to seconds
  created_date_seconds=$( date -d "${created_date}" +%s )

  # get today's date in seconds
  today_date=$( date +%s )

  # get seconds between the dates
  seconds_between=$( expr ${today_date} - ${created_date_seconds} )

  # Find out if the image is older than our expiration date and delete if so
  if [ ${seconds_between} -gt ${EXPIRATION_SECONDS} ]
  then
       # Never delete the 'latest' tag
      if [ ${imagename} = "latest" ]
      then
        echo "** ${imagename} not deleted because 'latest' is always preserved **"
      # If an exclude regex is specified, use it
      elif [[ -n "${EXCLUDE_FROM_DELETION}" ]] && [[ ${imagename} =~ ${EXCLUDE_FROM_DELETION} ]]
      then
        echo "** ${imagename} excluded from deletion by user defined regex **"
      # If an include regex is specified, use it
      elif [[ -n "${INCLUDE_FOR_DELETION}" ]] && [[ ${imagename} =~ ${INCLUDE_FOR_DELETION} ]]
      then
        echo "** deleting image name ${imagename} created at ${created_date} as specified in user defined regex **"
        if [ DRY_RUN != TRUE ]
        then
          curl --silent --location --request DELETE "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/registry/repositories/${GITLAB_REGISTRY_ID}/tags/${imagename}" --header "Authorization: Bearer ${GITLAB_AUTH_TOKEN}"
        fi
      elif [[ -z "${EXCLUDE_FROM_DELETION}" ]] && [[ -z "${INCLUDE_FOR_DELETION}" ]]
      then
        echo "** deleting image name ${imagename} created at ${created_date} as no exclude or include regexes specified **"
        if [ DRY_RUN != TRUE ]
        then
          curl --silent --location --request DELETE "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/registry/repositories/${GITLAB_REGISTRY_ID}/tags/${imagename}" --header "Authorization: Bearer ${GITLAB_AUTH_TOKEN}"
        fi
      # By default, delete everything older than the expiration date
      elif [[ -n "${INCLUDE_FOR_DELETION}" ]] && ! [[ ${imagename} =~ ${INCLUDE_FOR_DELETION} ]]
      then
        echo "** image ${imagename} ignored as it doesn't match the INCLUDE regex"
      else
        echo "** deleting image ${imagename} as the default policy"
        if [ DRY_RUN != TRUE ]
        then
          curl --silent --location --request DELETE "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/registry/repositories/${GITLAB_REGISTRY_ID}/tags/${imagename}" --header "Authorization: Bearer ${GITLAB_AUTH_TOKEN}"
        fi
      fi
  fi


done

echo ""
echo 'Cleanup Complete.  Please run `sudo gitlab-ctl registry-garbage-collect -m` on the Gitlab instance'
echo "to reclaim the space used by these deleted tags and images."
echo ""
