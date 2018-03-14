#! /bin/bash

set -e

# should we verify that necessary variables are set?
source /deploy/conf

PROJECT_NAME=$GOOGLE_PROJECT_ID
CLUSTER=$CI_BRANCH
DEFAULT_ZONE=us-central1-a

echo project name: $PROJECT_NAME
echo cluster: $CLUSTER
echo default zone: $DEFAULT_ZONE

echo 'setting project'
gcloud config set project $PROJECT_NAME
echo 'setting zone'
gcloud config set compute/zone $DEFAULT_ZONE
echo $GOOGLE_AUTH_JSON > /tmp/keyfile.json
echo 'authenticating service account'
gcloud auth activate-service-account --key-file /tmp/keyfile.json --project $PROJECT_NAME

echo 'setting cluster'
gcloud config set container/cluster $CLUSTER
echo 'getting container creds'
gcloud container clusters get-credentials $CLUSTER

IMAGE_TAG=${CI_COMMIT_ID}
KUBERNETES_MASTER=k8s://https://35.184.11.111 # should be a map with staging/production keys

# clean up old job of the same name
# WARNING this grep is not smart, it will remove all jobs that contain JOB_NAME. This means
# we do currently support having a job named `facebook-ads` alongside `facebook-ads-metrics`
kubectl delete pod $(kubectl get pods -a | grep ${JOB_NAME} | awk '{print $1}')

echo 'starting spark job'
$SPARK_HOME/bin/spark-submit \
  --deploy-mode cluster \
  --class ${CLASS_NAME} \
  --master ${KUBERNETES_MASTER} \
  --conf spark.kubernetes.submission.waitAppCompletion=false \
  --conf spark.executor.instances=${EXECUTOR_INSTANCES} \
  --conf spark.app.name=${JOB_NAME} \
  --conf spark.kubernetes.container.image=gcr.io/uncoil-io/spark-job-images/${JOB_NAME}:${IMAGE_TAG} \
  local:///opt/spark/work-dir/${JOB_NAME}.jar