#!/bin/bash

. ../.env

cd ../web
npm run build

cd ../tf
terraform init
terraform apply -auto-approve -var "bucket_name=$BUCKET_NAME"

cd ../web
aws s3 sync build/ s3://$BUCKET_NAME
cd ..
