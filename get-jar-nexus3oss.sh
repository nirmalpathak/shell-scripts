#!/bin/sh

read -p "Enter Artifact Name: " ARTIFACT_ID
echo $ARTIFACT_ID

wget --user=myuser --password='password' 'https://nexus.mycompany.com/repository/maven/com/mycomapny/'${ARTIFACT_ID}'/maven-metadata.xml' -O baseVersion.xml --no-check-certificate

BASE_VERSION=$(grep -m 1 \<version\> ./baseVersion.xml | sed -e 's/<version>\(.*\)<\/version>/\1/' | sed -e 's/ //g')
BASE=$(echo $BASE_VERSION |cut -d'-' -f1)
#echo "$BASE_VERSION"

wget --user=myuser --password='password' 'https://nexus.mycompany.com/repository/maven-snapshots/com/mycompany/'${ARTIFACT_ID}'/'${BASE_VERSION}'/maven-metadata.xml' -O artifactVersion.xml --no-check-certificate

TIME_STAMP=$(grep -m1 \<timestamp\> ./artifactVersion.xml | sed -e 's/<timestamp>\(.*\)<\/timestamp>/\1/' | sed -e 's/ //g')
#echo "$TIME_STAMP"

BUILD=$(grep -m1 \<buildNumber\> ./artifactVersion.xml | sed -e 's/<buildNumber>\(.*\)<\/buildNumber>/\1/' | sed -e 's/ //g')
#echo $BUILD

echo $BASE_VERSION $BASE $TIME_STAMP $BUILD

wget --user=myuser --password='password' 'https://nexus.mycompany.com/repository/maven-snapshots/com/mycompany/'${ARTIFACT_ID}'/'${BASE_VERSION}'/kernel-'${BASE}'-'${TIME_STAMP}'-'${BUILD}'.jar' --no-check-certificate
