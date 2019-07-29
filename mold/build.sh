# pull some variables from CI environment unless
# they"re already defined
if [ -n $CI ]; then
  echo "Running in CI environment."
  DOCKER_TAG=${DOCKER_TAG:-$CI_COMMIT_REF_SLUG}
  DOCKER_IMAGE=${DOCKER_IMAGE:-$CI_REGISTRY_IMAGE$IMAGE}
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
