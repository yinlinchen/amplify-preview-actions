#!/bin/sh

set -e

BRANCH_NAME=$1
AMPLIFY_COMMAND=$2
COMMENT_URL=$3
STAGE=$4

if [ -z "$STAGE" ]; then
  if [ "${GITHUB_EVENT_NAME}" = "pull_request" ]; then
    STAGE="PULL_REQUEST"
  elif [ "${GITHUB_REF_NAME}" = "refs/heads/main" ] || [ "${GITHUB_REF_NAME}" = "main" ]; then
    STAGE="PRODUCTION"
  else
    STAGE="DEVELOPMENT"
  fi
fi

STAGE=$(echo "$STAGE" | tr '[:lower:]' '[:upper:]')

case "$STAGE" in
  PRODUCTION|BETA|DEVELOPMENT|EXPERIMENTAL|PULL_REQUEST)
    app_stage="--stage=$STAGE"
    ;;
  *)
    app_stage="--stage=PRODUCTION"
    ;;
esac

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] ; then
  echo "You must provide the action with both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables in order to deploy"
  exit 1
fi

if [ -z "$AWS_REGION" ] ; then
  AWS_REGION="us-east-1"
fi

if [ -z "$AmplifyAppId" ] ; then
  echo "You must provide AmplifyAppId environment variable in order to deploy"
  exit 1
fi

if [[ ! -z "$BackendEnvARN" ]] ; then
  backend_env_arg="--backend-environment-arn=${BackendEnvARN}"
else
  backend_env_arg=""
fi

if [[ ! -z "$EnvironmentVariables" ]] ; then
  environment_variables_arg="--environment-variables=${EnvironmentVariables}"
else
  environment_variables_arg=""
fi

if [ -z "$BRANCH_NAME" ] ; then
  echo "You must provide branch name input parameter in order to deploy"
  exit 1
fi

if [ -z "$AMPLIFY_COMMAND" ] ; then
  echo "You must provide amplify_command input parameter in order to deploy"
  exit 1
fi

aws configure --profile amplify-preview-actions <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

case $AMPLIFY_COMMAND in

  deploy)
    EXISTING_BRANCH=$(sh -c 'aws amplify get-branch --app-id="${AmplifyAppId}" --branch-name="$BRANCH_NAME" --region="${AWS_REGION}" 2>&1 || true')

    if echo "$EXISTING_BRANCH" | grep -q '"branch"'; then
      echo "Branch $BRANCH_NAME already exists — skipping create and deploy"
      SKIP_COMMENT=1
    else
      sh -c "aws amplify create-branch --app-id=${AmplifyAppId} --branch-name=$BRANCH_NAME  \
                ${backend_env_arg} ${environment_variables_arg} --region=${AWS_REGION} ${app_stage}"

      sleep 10

      sh -c "aws amplify start-job --app-id=${AmplifyAppId} --branch-name=$BRANCH_NAME --job-type=RELEASE --region=${AWS_REGION}"
    fi
    ;;

  delete)
    DELETE_OUTPUT=$(sh -c 'aws amplify delete-branch --app-id="'"$AmplifyAppId"'" --branch-name="'"$BRANCH_NAME"'" --region="'"$AWS_REGION"'" 2>&1 || true')

    if echo "$DELETE_OUTPUT" | grep -q "NotFoundException"; then
      echo "Branch $BRANCH_NAME not found — skipping deletion"
      SKIP_COMMENT=1
    elif echo "$DELETE_OUTPUT" | grep -q '"error"'; then
      echo "Error deleting branch: $DELETE_OUTPUT"
      exit 1
    else
      echo "Branch $BRANCH_NAME deleted successfully"
    fi
    ;;

  *)
    echo "amplify command $AMPLIFY_COMMAND is invalid or not supported"
    exit 1
    ;;

esac

aws configure --profile amplify-preview-actions <<-EOF > /dev/null 2>&1
null
null
null
text
EOF

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Skipping comment as GITHUB_TOKEN not provided"
elif [ -z "$SKIP_COMMENT" ]; then
  SUBDOMAIN_NAME=$(echo "$BRANCH_NAME" | sed 's/[^a-zA-Z0-9-]/-/')
  
  if [ "$AMPLIFY_COMMAND" = "deploy" ]; then
    BODY="Preview branch generated at https://$SUBDOMAIN_NAME.${AmplifyAppId}.amplifyapp.com (stage: $STAGE)"
  else
    BODY="Preview branch deleted for https://$SUBDOMAIN_NAME.${AmplifyAppId}.amplifyapp.com (stage: $STAGE)"
  fi

  curl -X POST "$COMMENT_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: token $GITHUB_TOKEN" \
    --data "{ \"body\": \"$BODY\" }"
fi
