#!/bin/sh

# Uses $DOCKER_IMAGE and $DOCKER_TAG if defined. Otherwise, in CI environments,
# it appends the user-defined $CI_IMAGE to the environment-defined
# $CI_REGISTRY_IMAGE and selects $CI_COMMIT_REF_SLUG as the tag.

if [ ! -z ${CI+x} ]; then
  echo "Running in CI environment."
  DOCKER_IMAGE=${DOCKER_IMAGE:-$CI_REGISTRY_IMAGE$CI_IMAGE}
  DOCKER_TAG=${DOCKER_TAG:-$CI_COMMIT_REF_SLUG}
fi

DOCKERFILE=${DOCKERFILE:-Dockerfile}
FULL_IMAGE=$DOCKER_IMAGE:$DOCKER_TAG

echo "DOCKERFILE=$DOCKERFILE"
echo "DOCKER_ARGS=$DOCKER_ARGS"
echo "DOCKER_IMAGE=$DOCKER_IMAGE"
echo "DOCKER_TAG=$DOCKER_TAG"
echo "FULL_IMAGE=$FULL_IMAGE"

if [ -z $DOCKER_IMAGE ] || [ -z $DOCKER_TAG ]; then
  echo "Missing image name or tag" >&2
  exit 1
fi

docker build \
  --build-arg http_proxy="$http_proxy" \
  --build-arg https_proxy="$https_proxy" \
  --build-arg no_proxy="$no_proxy" \
  $DOCKER_ARGS \
  -f $DOCKERFILE \
  -t $FULL_IMAGE \
  .
