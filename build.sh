#!/bin/sh

# FIXME this comment is out of date
# Uses $DOCKER_IMAGE and $DOCKER_TAG if defined. Otherwise, in CI environments,
# it appends the user-defined $CI_IMAGE to the environment-defined
# $CI_REGISTRY_IMAGE and selects $CI_COMMIT_REF_NAME as the tag.

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
