#! /bin/bash

### /!\ This script assumes docker and docker compose are already installed on the host

#TODO: remove when done testing
export BRANCH=db_perf_scripts

# Get Build ID
export BUILD_ID=$(extract_metadata build_id)

# Get user/password
export CLOUD_SQL_DB_USER=$(extract_metadata cromwell_db_user)
export CLOUD_SQL_DB_PASSWORD=$(extract_metadata cromwell_db_pass)

gcloud --project broad-dsde-cromwell-perf sql instances clone cromwell-perf-testing-base cromwell-perf-testing-$BUILD_ID
gcloud --project broad-dsde-cromwell-perf sql users create cromwell --instance=cromwell-perf-testing-db-$BUILD_ID --password=$CLOUD_SQL_DB_PASSWORD

set -x

# Make sure ip forwarding is enabled by default
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf

# Create the directory where everything is going
mkdir /app
cd /app

# Download the docker-compose script and cromwell configuration
curl -L https://raw.githubusercontent.com/broadinstitute/cromwell/$BRANCH/scripts/perf/vm_scripts/docker-compose.yml -o docker-compose.yml
mkdir cromwell
curl -L https://raw.githubusercontent.com/broadinstitute/cromwell/$BRANCH/scripts/perf/vm_scripts/cromwell/cromwell.conf -o cromwell/cromwell.conf

# Utility function to extract values from instance metadata
extract_metadata() {
  curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/$1" -H "Metadata-Flavor: Google"
}


# Get custom attributes from instance metadata
export CLOUD_SQL_INSTANCES=$(extract_metadata cloud_sql_instance)
export CROMWELL_VERSION_TAG=$(extract_metadata cromwell_version)
export CROMWELL_PROJECT=$(extract_metadata cromwell_project)
export CROMWELL_EXECUTION_ROOT=$(extract_metadata cromwell_bucket)
export CROMWELL_STATSD_HOST=$(extract_metadata cromwell_statsd_host)
export CROMWELL_STATSD_PORT=$(extract_metadata cromwell_statsd_port)
# Use the instance name as statsd prefix to avoid metrics collisions
export CROMWELL_STATSD_PREFIX=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/name" -H "Metadata-Flavor: Google")
docker-compose up -d
