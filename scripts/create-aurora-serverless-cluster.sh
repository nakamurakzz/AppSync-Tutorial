#!/bin/bash
printf "Create RDS cluster\n"
REGION=ap-northeast-1
printf "Region: $REGION\n"

# select environment
printf "select environment\n"
printf "1: dev, 2: stg, 3: prod\n"
read ENV_NUM
if [ $ENV_NUM == 1 ]; then
  ENV=dev
elif [ $ENV_NUM == 2 ]; then
  ENV=stg
elif [ $ENV_NUM == 3 ]; then
  ENV=prod
else
  printf "invalid number\n"
  exit 1
fi

# .envからUSERNAME, COMPLEX_PASSWORDを読み込む
eval "$(grep 'USERNAME\|COMPLEX_PASSWORD' .env.$ENV)"

printf "$USERNAME\n"
printf "$COMPLEX_PASSWORD\n"

printf "input aws profile\n"
read PROFILE

printf "Creating RDS cluster\n"

aws rds create-db-cluster --db-cluster-identifier cluster-endpoint-$ENV  --master-username $USERNAME \
--master-user-password $COMPLEX_PASSWORD --engine aurora --engine-mode serverless \
--region $REGION \
--profile $PROFILE > /dev/null

printf "RDS cluster created\n"

printf "Creating RDS cluster secret\n"
aws secretsmanager create-secret \
    --name RDSSecret \
    --secret-string "{\"username\":\"$USERNAME\",\"password\":\"$COMPLEX_PASSWORD\"}" \
    --region $REGION \
    --profile $PROFILE > /dev/null
printf "RDS cluster secret created\n"

# Get RDS Cluster ARN
printf "Getting RDS cluster ARN\n"
RDS_ARN=$(aws rds describe-db-clusters --db-cluster-identifier cluster-endpoint-$ENV --region $REGION --profile $PROFILE | jq -r '.DBClusters[].DBClusterArn')
RDS_CLUSTER_ID=$(aws rds describe-db-clusters --db-cluster-identifier cluster-endpoint-$ENV --region $REGION --profile $PROFILE | jq -r '.DBClusters[].DBClusterIdentifier')

# Get RDS Cluster Secret ARN
printf "Getting RDS cluster secret ARN\n"
RDS_SECRET_ARN=$(aws secretsmanager describe-secret --secret-id RDSSecret --region $REGION --profile $PROFILE | jq -r '.ARN')

printf "---------------------------------------------------\n"
printf "RDS cluster ARN: $RDS_ARN\n"
printf "RDS cluster secret ARN: $RDS_SECRET_ARN\n"
printf "---------------------------------------------------\n"

# Enable Data API
printf "Enabling Data API\n"
aws rds modify-db-cluster \
  --db-cluster-identifier cluster-endpoint-$ENV \
  --enable-http-endpoint \
  --region $REGION --profile $PROFILE > /dev/null
printf "Data API enabled\n"

RDS_DATA_API_ARN=$(aws rds describe-db-clusters --db-cluster-identifier cluster-endpoint-$ENV --region $REGION --profile $PROFILE | jq -r '.DBClusters[].DBClusterArn')

# Set database and table names
DB_NAME=TESTDB
TABLE_NAME=todos

# Create database
printf "Creating database\n"
aws rds-data execute-statement --resource-arn $RDS_DATA_API_ARN \
  --secret-arn $RDS_SECRET_ARN \
  --region $REGION --profile $PROFILE --sql "CREATE DATABASE IF NOT EXISTS $DB_NAME" > /dev/null
printf "Database created\n"

# Create table
printf "Creating table\n"
aws rds-data execute-statement --resource-arn $RDS_DATA_API_ARN \
  --secret-arn $RDS_SECRET_ARN \
  --region $REGION --profile $PROFILE \
  --sql "CREATE TABLE IF NOT EXISTS $TABLE_NAME(id varchar(200), title varchar(200), completed boolean)" --database "$DB_NAME" > /dev/null
printf "Table created\n"
