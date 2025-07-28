#!/bin/bash

# Variables
set -e
source .env

# Login & Pull from Account A ---------------------------------

AWS_PROFILE=$PROFILE_A aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin $ACCOUNT_A_REPO1
docker pull $ACCOUNT_A_REPO1:$IMAGE_TAG

AWS_PROFILE=$PROFILE_A aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin $ACCOUNT_A_REPO2
docker pull $ACCOUNT_A_REPO2:$IMAGE_TAG


# Get full task definition JSON --------------------------------
aws ecs describe-task-definition \
  --task-definition "$TASK_FAMILY1" \
  --region "$REGION" \
  --profile "$PROFILE_A" \
  --query 'taskDefinition' \
  > "$OUT_FILE1"

aws ecs describe-task-definition \
  --task-definition "$TASK_FAMILY2" \
  --region "$REGION" \
  --profile "$PROFILE_A" \
  --query 'taskDefinition' \
  > "$OUT_FILE2"

# Login & Push to Account B -------------------------------------
AWS_PROFILE=$PROFILE_B aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin $ACCOUNT_B_REPO1
docker tag $ACCOUNT_A_REPO1:$IMAGE_TAG $ACCOUNT_B_REPO1:$IMAGE_TAG
docker push $ACCOUNT_B_REPO1:$IMAGE_TAG

AWS_PROFILE=$PROFILE_B aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin $ACCOUNT_B_REPO2
docker tag $ACCOUNT_A_REPO2:$IMAGE_TAG $ACCOUNT_B_REPO2:$IMAGE_TAG
docker push $ACCOUNT_B_REPO2:$IMAGE_TAG


