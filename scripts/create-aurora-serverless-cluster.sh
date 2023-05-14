#!/bin/bash
echo "Create RDS cluster"
REGION=ap-northeast-1
echo "Region: $REGION"

# select environment
echo "select environment"
echo "1: dev, 2: stg, 3: prod"
read ENV_NUM
if [ $ENV_NUM == 1 ]; then
  ENV=dev
elif [ $ENV_NUM == 2 ]; then
  ENV=stg
elif [ $ENV_NUM == 3 ]; then
  ENV=prod
else
  echo "invalid number"
  exit 1
fi

# .envからUSERNAME, COMPLEX_PASSWORD, DB_CLUSTER_IDを読み込む
USERNAME=$(grep USERNAME .env.$ENV | cut -d '=' -f 2)
COMPLEX_PASSWORD=$(grep COMPLEX_PASSWORD .env.$ENV | cut -d '=' -f 2)
DB_CLUSTER_ID=$(grep DB_CLUSTER_ID .env.$ENV | cut -d '=' -f 2)

echo $USERNAME
echo $COMPLEX_PASSWORD

echo "input aws profile"
read PROFILE

echo "Creating RDS cluster"

aws rds create-db-cluster --db-cluster-identifier $DB_CLUSTER_ID  --master-username $USERNAME \
--master-user-password $COMPLEX_PASSWORD --engine aurora-mysql --engine-version 5.7.mysql_aurora.2.08.3 --engine-mode serverless \
--region $REGION \
--profile $PROFILE > /dev/null

if [ $? -ne 0 ]; then
  echo "Failed to create RDS cluster"
  exit 1
fi

echo "RDS cluster created"

echo "Creating RDS cluster secret"
aws secretsmanager create-secret \
    --name RDSSecret-$ENV \
    --secret-string "{\"username\":\"$USERNAME\",\"password\":\"$COMPLEX_PASSWORD\"}" \
    --region $REGION \
    --profile $PROFILE > /dev/null

if [ $? -ne 0 ]; then
  echo "Failed to create RDS cluster secret"
  exit 1
fi

echo "RDS cluster secret created"

# Get RDS Cluster ARN
echo "Getting RDS cluster ARN"
RDS_ARN=$(aws rds describe-db-clusters --db-cluster-identifier $DB_CLUSTER_ID --region $REGION --profile $PROFILE | jq -r '.DBClusters[].DBClusterArn')
RDS_CLUSTER_ID=$(aws rds describe-db-clusters --db-cluster-identifier $DB_CLUSTER_ID --region $REGION --profile $PROFILE | jq -r '.DBClusters[].DBClusterIdentifier')

# Get RDS Cluster Secret ARN
echo "Getting RDS cluster secret ARN"
RDS_SECRET_ARN=$(aws secretsmanager describe-secret --secret-id RDSSecret-$ENV --region $REGION --profile $PROFILE | jq -r '.ARN')

echo "---------------------------------------------------"
echo "RDS cluster ARN: $RDS_ARN"
echo "RDS cluster secret ARN: $RDS_SECRET_ARN"
echo "---------------------------------------------------"

# Wait for DB Cluster to become available
echo "Waiting for DB cluster to become available"
while true; do
  CLUSTER_STATUS=$(aws rds describe-db-clusters --db-cluster-identifier $DB_CLUSTER_ID --region $REGION --profile $PROFILE | jq -r '.DBClusters[].Status')
  echo "DB cluster status: $CLUSTER_STATUS"
  if [ "$CLUSTER_STATUS" == "available" ]; then
    break
  fi
  echo "Waiting for 30 seconds"
  sleep 30
done
echo "DB cluster is now available"

# Enable Data API
echo "Enabling Data API"
aws rds modify-db-cluster \
  --db-cluster-identifier $DB_CLUSTER_ID --enable-http-endpoint --region $REGION --profile $PROFILE > /dev/null

if [ $? -ne 0 ]; then
  echo "Failed to enable Data API"
  exit 1
fi

echo "Data API enabled"

RDS_DATA_API_ARN=$(aws rds describe-db-clusters --db-cluster-identifier $DB_CLUSTER_ID --region $REGION --profile $PROFILE | jq -r '.DBClusters[].DBClusterArn')

# Create database
echo "Creating database"
aws rds-data execute-statement --resource-arn $RDS_DATA_API_ARN \
  --secret-arn $RDS_SECRET_ARN  \
  --region $REGION --profile $PROFILE --sql "CREATE DATABASE IF NOT EXISTS TESTDB" > /dev/null

if [ $? -ne 0 ]; then
  echo "Failed to create database"
  exit 1
fi

echo "Database created"

