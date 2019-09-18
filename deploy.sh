#!/bin/bash

LAMBDA_FUNCTION_NAME='aws-nmap'
ROLE_NAME='aws-nmap-logs'

function create_bucket() {
    GUID=$(python -c 'import uuid; print(uuid.uuid1())')
    BUCKET_NAME=$GUID-$LAMBDA_FUNCTION_NAME
    aws s3api create-bucket --bucket $BUCKET_NAME | jq '.Location'
}

function create_role() {
    ROLE_ARN=$(aws iam create-role --path '/service-role/' \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file://role-trust-policy.json \
        --tags 'Key=name,Value=aws-nmap' | jq '.Role | .Arn' | sed 's/"//g'
    )

    aws iam put-role-policy --role-name $ROLE_NAME \
        --policy-name LambdaLogCreation \
        --policy-document file://lambda-execution-policy.json
}

function package_code() {
    rm function.zip
    zip -q function.zip nmap* -r nse* -r scripts
}

function upload_initial_code() {
    aws s3 cp function.zip "s3://$BUCKET_NAME/$LAMBDA_FUNCTION_NAME"
}

function update_code() {
    aws lambda update-function-code --function-name $LAMBDA_FUNCTION_NAME --zip-file fileb://function.zip
}

function init_lambda_function() {
    aws lambda create-function --function-name $LAMBDA_FUNCTION_NAME \
        --description "Remotely run nmap" \
        --timeout 600 \
        --runtime 'python3.7' \
        --tags "team=red,category=reconnaissance" \
        --role $ROLE_ARN \
        --handler 'nmap_aws.lambda_handler' \
        --code "S3Bucket=$BUCKET_NAME,S3Key=$LAMBDA_FUNCTION_NAME"
}

function main() {
    create_bucket
    create_role
    package_code
    upload_initial_code
    init_lambda_function
}

main
