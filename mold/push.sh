# Behaves fundamentally different in local and CI environments. In a CI
# environment, it will push a single image. In a local environment, for each
# git ref pointing at HEAD, it adds an additional image tag that points at a
# registry, then pushes it.

# Uses $DOCKER_IMAGE and $DOCKER_TAG if defined. Otherwise, in local
# environments, it selects $LOCAL_DOCKER_IMAGE AND $LOCAL_DOCKER_TAG, as well
# as $DOCKER_REGISTRY. In CI environments, it appends the user-defined
# $CI_IMAGE to the environment-defined $CI_REGISTRY_IMAGE and selects
# $CI_COMMIT_REF_SLUG as the tag.

# Parameter logic

if [ ! -z ${CI+x} ]; then
  echo "Running in CI environment."
  DOCKER_TAG=${DOCKER_TAG:-$CI_COMMIT_REF_SLUG}
  DOCKER_IMAGE=${DOCKER_IMAGE:-$CI_REGISTRY_IMAGE$CI_IMAGE}
  FULL_IMAGE=$DOCKER_IMAGE:$DOCKER_TAG

else
  DOCKER_TAG=${DOCKER_TAG:-$LOCAL_DOCKER_TAG}
  DOCKER_IMAGE=${DOCKER_IMAGE:-$LOCAL_DOCKER_IMAGE}
  FULL_IMAGE=$DOCKER_IMAGE:$DOCKER_TAG
fi

echo "DOCKER_REGISTRY=$DOCKER_REGISTRY"
echo "DOCKER_IMAGE=$DOCKER_IMAGE"
echo "DOCKER_TAG=$DOCKER_TAG"
echo "FULL_IMAGE=$FULL_IMAGE"

if [ -z $DOCKER_IMAGE ] || [ -z $DOCKER_TAG ]; then
  echo "Missing image name or tag" >&2
  exit 1
fi

# only check if we're running locally
if [ -z $CI ] && [ -z $DOCKER_REGISTRY ]; then
  echo "Missing Docker registry" >&2
  exit 1
fi

# Push logic

if [ ! -z ${CI+x} ]; then
  docker push $FULL_IMAGE

else
  # this finds all local git references that are pointing at HEAD
  head=$(git rev-parse HEAD)
  refs=$(git show-ref --tags --heads -d | grep $head | awk "{print $2}" | xargs -L1 basename | sed "s/\^{}//")
  echo "Git refs: $refs"

  for ref in $refs; do
    remote_image="$DOCKER_REGISTRY/$DOCKER_IMAGE:$ref"
    echo "remote_image=$remote_image"
    docker tag $FULL_IMAGE $remote_image
    docker push $remote_image
  done
fi
