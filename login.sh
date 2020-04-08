#!/bin/sh

# FIXME this comment is out of date
# Uses $REGISTRY, $REGISTRY_USER, and $REGISTRY_PASSWORD if defined. Otherwise,
# in CI environments, it selects $CI_REGISTRY, $CI_REGISTRY_USER, and
# $CI_REGISTRY_PASSWORD.

if [ -n "${ECR+x}" ]; then
  echo "Using ECR for default credentials."
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  REGION=${AWS_DEFAULT_REGION:-$(aws configure get region)}

  # grab defaults from the AWS CLI
  ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
  ECR_REGISTRY_USER="AWS"
  ECR_REGISTRY_PASSWORD=$(aws ecr get-login-password)

  # allow user to override these if they want, but otherwise default
  # to the ECR creds
  REGISTRY=${REGISTRY:-$ECR_REGISTRY}
  REGISTRY_USER=${REGISTRY_USER:-$ECR_REGISTRY_USER}
  REGISTRY_PASSWORD=${REGISTRY_PASSWORD:-$ECR_REGISTRY_PASSWORD}

elif [ -n "${CI+x}" ]; then
  echo "Using CI for default credentials."

  # allow user to override these if they want, but otherwise default
  # to the CI creds
  REGISTRY=${REGISTRY:-$CI_REGISTRY}
  REGISTRY_USER=${REGISTRY_USER:-$CI_REGISTRY_USER}
  REGISTRY_PASSWORD=${REGISTRY_PASSWORD:-$CI_REGISTRY_PASSWORD}
fi

if [ -z "$REGISTRY_USER" ] || [ -z "$REGISTRY_PASSWORD" ] || [ -z "$REGISTRY" ]; then
  echo "Registry credentials missing or incomplete." >&2
  exit 1
fi

echo "REGISTRY=$REGISTRY"
echo "REGISTRY_USER=$REGISTRY_USER"

echo $REGISTRY_PASSWORD | docker login --username $REGISTRY_USER --password-stdin $REGISTRY
