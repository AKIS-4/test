#!/bin/bash

# Variables
set -e
source .env

# Login & Pull from Account A ---------------------------------

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin $ACCOUNT_A_REPO1
docker pull $ACCOUNT_A_REPO1:$IMAGE_TAG

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin $ACCOUNT_A_REPO2
docker pull $ACCOUNT_A_REPO2:$IMAGE_TAG


# Get full task definition JSON --------------------------------
aws ecs describe-task-definition \
  --task-definition "$TASK_FAMILY1" \
  --region "$REGION" \
  --query 'taskDefinition' \
  > "$OUT_FILE1"

aws ecs describe-task-definition \
  --task-definition "$TASK_FAMILY2" \
  --region "$REGION" \
  --query 'taskDefinition' \
  > "$OUT_FILE2"



