#!/bin/bash
echo "Create RDS cluster"
echo "Region: ap-northeast-1"

# .envからUSERNAME, COMPLEX_PASSWORDを読み込む
USERNAME=$(grep USERNAME .env | cut -d '=' -f 2)
COMPLEX_PASSWORD=$(grep COMPLEX_PASSWORD .env | cut -d '=' -f 2)

echo $USERNAME
echo $COMPLEX_PASSWORD

echo "input aws profile"
read PROFILE

echo "Creating RDS cluster"

aws rds create-db-cluster --db-cluster-identifier http-endpoint-test  --master-username $USERNAME \
--master-user-password $COMPLEX_PASSWORD --engine aurora --engine-mode serverless \
--region ap-northeast-1 \
--profile $PROFILE > /dev/null

echo "RDS cluster created"

echo "Creating RDS cluster secret"
aws secretsmanager create-secret \
    --name HttpRDSSecret \
    --secret-string "{\"username\":\"$USERNAME\",\"password\":\"$COMPLEX_PASSWORD\"}" \
    --region ap-northeast-1 \
    --profile $PROFILE > /dev/null
echo "RDS cluster secret created"

# Get RDS Cluster ARN
echo "Getting RDS cluster ARN"
RDS_ARN=$(aws rds describe-db-clusters --db-cluster-identifier http-endpoint-test --region ap-northeast-1 --profile $PROFILE | jq -r '.DBClusters[].DBClusterArn')

# Get RDS Cluster Secret ARN
echo "Getting RDS cluster secret ARN"
RDS_SECRET_ARN=$(aws secretsmanager describe-secret --secret-id HttpRDSSecret --region ap-northeast-1 --profile $PROFILE | jq -r '.ARN')

echo "---------------------------------------------------"
echo "RDS cluster ARN: $RDS_ARN"
echo "RDS cluster secret ARN: $RDS_SECRET_ARN"
echo "---------------------------------------------------"