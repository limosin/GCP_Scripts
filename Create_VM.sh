#!/bin/bash

name=$1

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

APIS="https://www.googleapis.com/auth/pubsub,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.full_control"


gcloud compute --project=$PROJECT instances create $name --zone=$ZONE --machine-type=$MACHINE --subnet=default \
--network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=$ACCOUNT --scopes=$APIS \
--image=$IMAGE --image-project=ubuntu-os-cloud --boot-disk-size=$DISKSIZE \
--boot-disk-type=$DISKTYPE --boot-disk-device-name=$name


echo "Making the external IP static"
EXTIPADD=$(gcloud compute instances describe $name --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone=$ZONE)
gcloud compute addresses create $name --addresses $EXTIPADD --region=$REGION
echo "Your External IP Address is :"
echo $EXTIPADD

# Changes have been done from here, please copy past the below part.
white=$2

#SQL=$name
SQL="<Your SQL name>"

if [[ -n "$white" ]]; then
    echo "Whitelisting the Address: $EXTIPADD"
    OLDPOOL=$(gcloud sql instances describe $SQL --format='get(settings.ipConfiguration.authorizedNetworks.value)')
    TEMPOOL="$OLDPOOL;$EXTIPADD"
    NEWPOOL=${TEMPOOL//;/,}
    gcloud sql instances patch $SQL --authorized-networks=$NEWPOOL --quiet
    echo "Successfully Whitelisted!!"
fi
