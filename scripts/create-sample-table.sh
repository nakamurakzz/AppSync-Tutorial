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

RDS_SECRET_ARN=$(aws secretsmanager describe-secret --secret-id RDSSecret-$ENV --region $REGION --profile $PROFILE | jq -r '.ARN')
RDS_DATA_API_ARN=$(aws rds describe-db-clusters --db-cluster-identifier $DB_CLUSTER_ID --region $REGION --profile $PROFILE | jq -r '.DBClusters[].DBClusterArn')

echo $RDS_SECRET_ARN
echo $RDS_DATA_API_ARN

# Create table
echo "Creating table"
aws rds-data execute-statement --resource-arn $RDS_DATA_API_ARN --secret-arn $RDS_SECRET_ARN --region $REGION --profile $PROFILE \
  --sql "CREATE TABLE IF NOT EXISTS todos(id varchar(200) PRIMARY KEY, title varchar(200), completed boolean) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci" --database "TESTDB" > /dev/null

if [ $? -ne 0 ]; then
  echo "Failed to create table"
  exit 1
fi

echo "Table created"