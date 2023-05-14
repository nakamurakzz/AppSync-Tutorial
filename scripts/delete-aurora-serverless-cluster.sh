#!/bin/bash
echo "Delete RDS resources"
REGION=ap-northeast-1
echo "Region: $REGION"

# select environment
echo "select environment"
echo "1: dev, 2: stg, 3: prod"
read ENV_NUM
if [ "$ENV_NUM" == "1" ]; then
  ENV=dev
elif [ "$ENV_NUM" == "2" ]; then
  ENV=stg
elif [ "$ENV_NUM" == "3" ]; then
  ENV=prod
else
  echo "invalid number"
  exit 1
fi

echo "input aws profile"
read PROFILE

# Get RDS Cluster ARN
echo "Getting RDS cluster ARN"
RDS_ARN=$(aws rds describe-db-clusters --db-cluster-identifier cluster-endpoint-$ENV --region $REGION --profile $PROFILE | jq -r '.DBClusters[].DBClusterArn')
DB_CLUSTER_ID=$(grep DB_CLUSTER_ID .env.$ENV | cut -d '=' -f 2)

# Get RDS Cluster Secret ARN
echo "Getting RDS cluster secret ARN"
RDS_SECRET_ARN=$(aws secretsmanager describe-secret --secret-id RDSSecret --region $REGION --profile $PROFILE | jq -r '.ARN')

# Set database and table names
DB_NAME=TESTDB
TABLE_NAME=todos

# Delete RDS cluster
echo "Deleting RDS cluster"
aws rds delete-db-cluster --db-cluster-identifier $DB_CLUSTER_ID --region $REGION --profile $PROFILE --skip-final-snapshot > /dev/null

if [ $? -ne 0 ]; then
  echo "Failed to delete RDS cluster"
  exit 1
fi

echo "RDS cluster deleted"

# Delete RDS cluster secret
echo "Deleting RDS cluster secret"
aws secretsmanager delete-secret --secret-id RDSSecret-$ENV --force-delete-without-recovery --region $REGION --profile $PROFILE > /dev/null

if [ $? -ne 0 ]; then
  echo "Failed to delete RDS cluster secret"
  exit 1
fi

echo "RDS cluster secret deleted"
