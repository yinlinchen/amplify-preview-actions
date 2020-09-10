#!/bin/sh

set -e

if [ -z "$AWS_ACCESS_KEY_ID" ] && [ -z "$AWS_SECRET_ACCESS_KEY" ] ; then
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

if [ -z "$BackendEnvARN" ] ; then
  echo "You must provide BackendEnvARN environment variable in order to deploy"
  exit 1
fi

if [ -z "$1" ] ; then
  echo "You must provide branch name input parameter in order to deploy"
  exit 1
fi

aws configure --profile amplify-preview-actions <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

sh -c "aws amplify create-branch --app-id=${AmplifyAppId} --branch-name=$1  \
              --backend-environment-arn=${BackendEnvARN} --region=${AWS_REGION}"

sleep 10

sh -c "aws amplify start-job --app-id=${AmplifyAppId} --branch-name=$1 --job-type=RELEASE --region=${AWS_REGION}"

aws configure --profile amplify-preview-actions <<-EOF > /dev/null 2>&1
null
null
null
text
EOF