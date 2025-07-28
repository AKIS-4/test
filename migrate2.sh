#!/bin/bash

# Variables
set -e
source .env

# Login & Push to Account B -------------------------------------
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin $ACCOUNT_B_REPO1
docker tag $ACCOUNT_A_REPO1:$IMAGE_TAG $ACCOUNT_B_REPO1:$IMAGE_TAG
docker push $ACCOUNT_B_REPO1:$IMAGE_TAG

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin $ACCOUNT_B_REPO2
docker tag $ACCOUNT_A_REPO2:$IMAGE_TAG $ACCOUNT_B_REPO2:$IMAGE_TAG
docker push $ACCOUNT_B_REPO2:$IMAGE_TAG
