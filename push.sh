#!/bin/sh

# FIXME this comment is out of date
# Behaves fundamentally different in local and CI environments. In a CI
# environment, it will push a single image. In a local environment, for each
# git ref pointing at HEAD, it adds an additional image tag that points at a
# registry, then pushes it.

# Uses $DOCKER_IMAGE and $DOCKER_TAG if defined. In local environments, it also
# uses $DOCKER_REGISTRY. In CI environments, it appends the user-defined
# $CI_IMAGE to the environment-defined $CI_REGISTRY_IMAGE and selects
# $CI_COMMIT_REF_NAME as the tag.

# Parameter logic


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


# echo "DOCKER_REGISTRY=$DOCKER_REGISTRY"
echo "DOCKER_IMAGE=$DOCKER_IMAGE"
echo "DOCKER_TAG=$DOCKER_TAG"

if [ -z "$DOCKER_IMAGE" ] || [ -z "$DOCKER_TAG" ]; then
  echo "Missing image name or tag" >&2
  exit 1
fi

FULL_IMAGE=$DOCKER_IMAGE:$DOCKER_TAG
echo "FULL_IMAGE=$FULL_IMAGE"

# FIXME local is disabled
# only check if we're running locally
# if [ -z "${CI+x}" ] && [ -z "$DOCKER_REGISTRY" ]; then
#   echo "Missing Docker registry" >&2
#   exit 1
# fi

# Push logic
docker push $FULL_IMAGE

# else
#   # this finds all local git references that are pointing at HEAD
#   head=$(git rev-parse HEAD)
#   refs=$(git show-ref --tags --heads -d | grep $head | awk '{print $2}' | xargs -L1 basename | sed "s/\^{}//")
#   echo "Git refs: $refs"
#
#   for ref in $refs; do
#     remote_image="$DOCKER_REGISTRY/$DOCKER_IMAGE:$ref"
#     echo "remote_image=$remote_image"
#     docker tag $FULL_IMAGE $remote_image
#     docker push $remote_image
#   done
# fi
