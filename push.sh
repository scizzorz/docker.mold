#!/bin/sh

# This script will push an image defined by $DOCKER_IMAGE:$DOCKER_TAG.
#
# See build.sh for more information on the defaults for these variables in
# different conditions.

if [ -n "${ECR+x}" ]; then
  echo "Using ECR for default image name."
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  REGION=${AWS_DEFAULT_REGION:-$(aws configure get region)}
  ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
  DOCKER_IMAGE=${DOCKER_IMAGE:-$ECR_REGISTRY/$ECR_IMAGE}
elif [ -n "${CI+x}" ]; then
  echo "Using CI for default image name."
  DOCKER_IMAGE=${DOCKER_IMAGE:-$CI_REGISTRY_IMAGE$CI_IMAGE}
fi

if [ -n "${CI+x}" ]; then
  echo "Using CI for default image tag."
  DOCKER_TAG=${DOCKER_TAG:-$CI_COMMIT_REF_NAME}
fi

echo "DOCKER_IMAGE=$DOCKER_IMAGE"
echo "DOCKER_TAG=$DOCKER_TAG"

if [ -z "$DOCKER_IMAGE" ] || [ -z "$DOCKER_TAG" ]; then
  echo "Missing image name or tag" >&2
  exit 1
fi

FULL_IMAGE=$DOCKER_IMAGE:$DOCKER_TAG
echo "FULL_IMAGE=$FULL_IMAGE"

# Push logic
docker push $FULL_IMAGE
