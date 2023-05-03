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
--region ap-northeast-1 --profile $PROFILE

echo "Creating RDS cluster completed"