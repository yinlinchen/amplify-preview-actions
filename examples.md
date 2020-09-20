## Configuration Examples

Note: All scenarios are assume that the PR is labeled with `Ready for review` and a reviewer is assigned.

### Scenario 1:
A developer submits a PR for review using the existing backend environment. A new PR review branch is deployed to the Amplify console App page (not the Previews page)

```
name: 'Amplify PR Preview'
on:
  pull_request_target:
    types: [review_requested]

jobs:
  deploy:
    if: contains(github.event.pull_request.labels.*.name, 'Ready for review')
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master

    - name: set branchname env
      id: setenvname
      run: |
        # use GITHUB_HEAD_REF that is set to PR source branch
        echo "##[set-output name=setbranchname;]$(echo ${GITHUB_HEAD_REF})"

    - name: deploy PR preview with current backend env
      if: ${{ !contains(github.event.pull_request.labels.*.name, 'newbackendenv') }}
      uses: yinlinchen/amplify-preview-actions@master
      with:
        branch_name: ${{ steps.setenvname.outputs.setbranchname }}
        amplify_command: deploy
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AmplifyAppId: ${{ secrets.AMPLIFYAPPID }}
        AWS_REGION: 'us-east-1'
        BackendEnvARN: ${{ secrets.BACKENDENVARN }}
```

### Scenario 2:
A developer submits a PR for review using a new backend environment. A new PR review branch using a new backend environment is deployed to the Amplify console App page (not the Previews page)

```
name: 'Amplify PR Preview'
on:
  pull_request_target:
    types: [review_requested]

jobs:
  deploy:
    if: contains(github.event.pull_request.labels.*.name, 'Ready for review')
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master

    - name: set branchname env
      id: setenvname
      run: |
        # use GITHUB_HEAD_REF that is set to PR source branch
        echo "##[set-output name=setbranchname;]$(echo ${GITHUB_HEAD_REF})"
    - name: deploy PR preview with another(new) backend env
      if: contains(github.event.pull_request.labels.*.name, 'newbackendenv')
      uses: yinlinchen/amplify-preview-actions@master
      with:
        branch_name: ${{ steps.setenvname.outputs.setbranchname }}
        amplify_command: deploy
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AmplifyAppId: ${{ secrets.AMPLIFYAPPID }}
        AWS_REGION: 'us-east-1'
        BackendEnvARN: ${{ secrets.NEWBACKENDENVARN }}
```

### Scenario 3:
A reviewer finish reviews a PR, approves it, and merges it into the codebase. The PR preview branch is deleted from the Amplify console App page.

or

A reviewer finish reviews a PR, does not approve it and the developer closes the PR. The PR preview branch is deleted from the Amplify console App page.

```
name: 'Amplify PR Closed'
on:
  pull_request_target:
    branches:
      - dev
    types: [closed]

jobs:
  deploy:
    if: contains(github.event.pull_request.labels.*.name, 'Ready for review')
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master

    - name: set branchname env
      id: setenvname
      run: |
        # use GITHUB_HEAD_REF that is set to PR source branch
        echo "##[set-output name=setbranchname;]$(echo ${GITHUB_HEAD_REF})"
    - name: cleanup PR preview branch
      uses: yinlinchen/amplify-preview-actions@master
      with:
        branch_name: ${{ steps.setenvname.outputs.setbranchname }}
        amplify_command: delete
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AmplifyAppId: ${{ secrets.AMPLIFYAPPID }}
        BackendEnvARN: ${{ secrets.BACKENDENVARN }}
        AWS_REGION: 'us-east-1'
```