#!/bin/sh

# This script will build an image from $DOCKERFILE and tag it
# $DOCKER_IMAGE:$DOCKER_TAG.
#
# If $ECR is defined, the ECR registry is looked up using the AWS CLI. You can
# define the ECR repo using $ECR_IMAGE: $DOCKER_IMAGE will default to
# $ECR_REGISTRY/$ECR_IMAGE.
#
# If $CI is defined, the CI registry is looked up using predefined CI
# variables. You can define the CI image using $CI_IMAGE: $DOCKER_IMAGE will
# default to $CI_REGISTRY_IMAGE$CI_IMAGE.
#
# In both cases, if $CI is defined, then $DOCKER_TAG will default to the commit
# ref name.
#
# Additional arguments can be passed to docker using $DOCKER_ARGS.

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

DOCKERFILE=${DOCKERFILE:-Dockerfile}
echo "DOCKERFILE=$DOCKERFILE"
echo "DOCKER_ARGS=$DOCKER_ARGS"
echo "DOCKER_IMAGE=$DOCKER_IMAGE"
echo "DOCKER_TAG=$DOCKER_TAG"

if [ -z "$DOCKER_IMAGE" ] || [ -z "$DOCKER_TAG" ]; then
  echo "Missing image name or tag" >&2
  exit 1
fi

FULL_IMAGE=$DOCKER_IMAGE:$DOCKER_TAG
echo "FULL_IMAGE=$FULL_IMAGE"

docker build \
  --build-arg http_proxy="$http_proxy" \
  --build-arg https_proxy="$https_proxy" \
  --build-arg no_proxy="$no_proxy" \
  $DOCKER_ARGS \
  -f $DOCKERFILE \
  -t $FULL_IMAGE \
  .
