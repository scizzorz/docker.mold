# in a CI environment, we want to only push a single image, whereas
# in a normal environment, we want to push the image for every git
# ref pointing at HEAD.

if [ -n $CI ]; then
  echo "Running in CI environment."
  DOCKER_TAG=${DOCKER_TAG:-$CI_COMMIT_REF_SLUG}
  DOCKER_IMAGE=${DOCKER_IMAGE:-$CI_REGISTRY_IMAGE$IMAGE}
  FULL_IMAGE=$DOCKER_IMAGE:$DOCKER_TAG

  echo "DOCKER_IMAGE=$DOCKER_IMAGE"
  echo "DOCKER_TAG=$DOCKER_TAG"
  echo "FULL_IMAGE=$FULL_IMAGE"

  if [ -z $DOCKER_IMAGE ] || [ -z $DOCKER_TAG ]; then
    echo "Missing image name or tag" >&2
    exit 1
  fi

  docker push $FULL_IMAGE

else
  LOCAL_IMAGE=$DOCKER_IMAGE:$DOCKER_TAG

  echo "DOCKER_IMAGE=$DOCKER_IMAGE"
  echo "DOCKER_TAG=$DOCKER_TAG"
  echo "LOCAL_IMAGE=$LOCAL_IMAGE"

  if [ -z $DOCKER_IMAGE ] || [ -z $DOCKER_TAG ]; then
    echo "Missing image name or tag" >&2
    exit 1
  fi

  if [ -z $DOCKER_REGISTRY ]; then
    echo "Missing Docker registry" >&2
    exit 1
  fi

  # this finds all local git references that are pointing at HEAD
  head=$(git rev-parse HEAD)
  refs=$(git show-ref --tags --heads -d | grep $head | awk "{print $2}" | xargs -L1 basename | sed "s/\^{}//")
  echo "Git refs: $refs"

  for ref in $refs; do
    remote_image="$DOCKER_REGISTRY/$DOCKER_IMAGE:$ref"
    echo "remote_image=$remote_image"
    docker tag $LOCAL_IMAGE $remote_image
    docker push $remote_image
  done
fi
