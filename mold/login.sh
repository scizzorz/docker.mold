# look up credentials from CI environment unless
# they"re already already
if [ -n $CI ]; then
  echo "Running in CI environment."
  REGISTRY=${REGISTRY:-$CI_REGISTRY}
  REGISTRY_USER=${REGISTRY_USER:-$CI_REGISTRY_USER}
  REGISTRY_PASSWORD=${REGISTRY_PASSWORD:-$CI_REGISTRY_PASSWORD}
fi

if [ -z $REGISTRY_USER ] || [ -z $REGISTRY_PASSWORD ] || [ -z $REGISTRY ]; then
  echo "Registry credentials missing or incomplete." >&2
  exit 1
fi

echo "REGISTRY=$REGISTRY"
echo "REGISTRY_USER=$REGISTRY_USER"

echo $REGISTRY_PASSWORD | docker login --username $REGISTRY_USER --password-stdin $REGISTRY
