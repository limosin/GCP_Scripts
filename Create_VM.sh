#!/bin/bash

name=$1

white=$2

if [[ -n "$name" ]]; then
    echo "Creating VM"
else
    echo "argument error"
fi

PROJECT="<PROJECT NAME>"
MACHINE="n1-standard-1"
REGION="europe-west1"
ZONE="europe-west1-c"
ACCOUNT="<ACCOUNT NAME>"
IMAGE="ubuntu-1804-bionic-v20190612"
DISKTYPE="pd-ssd"
DISKSIZE="200GB"
SQL="<SQL INSTANCE NAME>"

APIS="https://www.googleapis.com/auth/pubsub,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.full_control"


gcloud compute --project=$PROJECT instances create $name --zone=$ZONE --machine-type=$MACHINE --subnet=default \
--network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=$ACCOUNT --scopes=$APIS \
--image=$IMAGE --image-project=ubuntu-os-cloud --boot-disk-size=$DISKSIZE \
--boot-disk-type=$DISKTYPE --boot-disk-device-name=$name


echo "Making the external IP static"

EXTIPADD=$(gcloud compute instances describe $name --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone=$ZONE)
gcloud compute addresses create $name --addresses $EXTIPADD --region=$REGION

if [[ -n "$white" ]]; then
    echo "Whitelisting the IP for SQL Server - $SQL"
    ACCESS_TOKEN="$(gcloud auth application-default print-access-token)"
    OLDPOOL="$(gcloud sql instances describe sqld2 --format='get(settings.ipConfiguration.authorizedNetworks)')"
    OLDPOOL=${OLDPOOL//;/,}
    OLDPOOL=${OLDPOOL//u\'/\"}
    OLDPOOL=${OLDPOOL//\'/\"}
    header='{"settings":{"ipConfiguration":{"authorizedNetworks":'
    stri="$header[{\"name\":\"$name\",\"value\":\"$EXTIPADD\",\"kind\":\"sql#aclEntry\"},$OLDPOOL]}}}"
    curl --header "Authorization: Bearer ${ACCESS_TOKEN}" --header 'Content-Type: application/json' --data "$stri" -X PATCH https://www.googleapis.com/sql/v1beta4/projects/yesbankdatathon/instances/sqld2
fi

echo "Your External IP Address is :"
echo $EXTIPADD
