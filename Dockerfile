FROM python:3.8-alpine

LABEL "com.github.actions.name"="AWS Amplify PR Previews for Public Repository"
LABEL "com.github.actions.description"="This action deploys your AWS Amplify pull request for your public repository"
LABEL "com.github.actions.icon"="git-commit"
LABEL "com.github.actions.color"="blue"

LABEL version="0.2"
LABEL "repository"="https://github.com/yinlinchen/amplify-preview-actions.git"
LABEL "homepage"="https://github.com/yinlinchen/amplify-preview-actions"
LABEL maintainer="Yinlin Chen <ylchen@vt.edu>"

ENV AWSCLI_VERSION='1.18.14'

RUN pip install --quiet --no-cache-dir awscli==${AWSCLI_VERSION}

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]