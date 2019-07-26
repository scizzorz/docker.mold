local_ref="$DOCKER_IMAGE:$DOCKER_TAG"

# this finds all local git references that are pointing at the current commit
head=$(git rev-parse HEAD)
refs=$(git show-ref --tags --heads -d | grep $head | awk '{print $2}' | xargs -L1 basename | sed 's/\^{}//')

for ref in $refs; do
  remote_ref="$DOCKER_REGISTRY/$DOCKER_IMAGE:$ref"
  docker tag $local_ref $remote_ref
  docker push $remote_ref
done
