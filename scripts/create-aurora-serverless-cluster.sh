#!/bin/bash
echo "Create RDS cluster"
REGION=ap-northeast-1
echo "Region: $REGION"

# .envからUSERNAME, COMPLEX_PASSWORDを読み込む
USERNAME=$(grep USERNAME .env | cut -d '=' -f 2)
COMPLEX_PASSWORD=$(grep COMPLEX_PASSWORD .env | cut -d '=' -f 2)

echo $USERNAME
echo $COMPLEX_PASSWORD

echo "input aws profile"
read PROFILE

echo "Creating RDS cluster"

# aws rds create-db-cluster --db-cluster-identifier http-endpoint-test  --master-username $USERNAME \
# --master-user-password $COMPLEX_PASSWORD --engine aurora --engine-mode serverless \
# --region $REGION \
# --profile $PROFILE > /dev/null

# echo "RDS cluster created"

# echo "Creating RDS cluster secret"
# aws secretsmanager create-secret \
#     --name HttpRDSSecret \
#     --secret-string "{\"username\":\"$USERNAME\",\"password\":\"$COMPLEX_PASSWORD\"}" \
#     --region $REGION \
#     --profile $PROFILE > /dev/null
# echo "RDS cluster secret created"

# Get RDS Cluster ARN
echo "Getting RDS cluster ARN"
RDS_ARN=$(aws rds describe-db-clusters --db-cluster-identifier http-endpoint-test --region $REGION --profile $PROFILE | jq -r '.DBClusters[].DBClusterArn')
RDS_CLUSTER_ID=$(aws rds describe-db-clusters --db-cluster-identifier http-endpoint-test --region $REGION --profile $PROFILE | jq -r '.DBClusters[].DBClusterIdentifier')

# Get RDS Cluster Secret ARN
echo "Getting RDS cluster secret ARN"
RDS_SECRET_ARN=$(aws secretsmanager describe-secret --secret-id HttpRDSSecret --region $REGION --profile $PROFILE | jq -r '.ARN')

echo "---------------------------------------------------"
echo "RDS cluster ARN: $RDS_ARN"
echo "RDS cluster secret ARN: $RDS_SECRET_ARN"
echo "---------------------------------------------------"

# Ebnable Data API
echo "Enabling Data API"
aws rds modify-db-cluster \
  --db-cluster-identifier http-endpoint-test \
  --enable-http-endpoint \
  --region $REGION --profile $PROFILE > /dev/null
echo "Data API enabled"

RDS_DATA_API_ARN=$(aws rds describe-db-clusters --db-cluster-identifier http-endpoint-test --region $REGION --profile $PROFILE | jq -r '.DBClusters[].DBClusterArn')

# Create database
echo "Creating database"
aws rds-data execute-statement --resource-arn $RDS_DATA_API_ARN \
  --secret-arn $RDS_SECRET_ARN  \
  --region $REGION --profile $PROFILE --sql "CREATE DATABASE IF NOT EXISTS TESTDB" > /dev/null
echo "Database created"

# Create table
echo "Creating table"
aws rds-data execute-statement --resource-arn $RDS_DATA_API_ARN \
  --secret-arn $RDS_SECRET_ARN \
  --region $REGION --profile $PROFILE \
  --sql "CREATE TABLE IF NOT EXISTS Pets(id varchar(200), type varchar(200), price float)" --database "TESTDB" > /dev/null
echo "Table created"