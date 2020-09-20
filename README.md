# amplify-preview-actions

[![RELEASE](https://img.shields.io/github/v/release/yinlinchen/amplify-preview-actions?include_prereleases)](https://github.com/ambientlight/amplify-cli-action/releases)
[![LICENSE](https://img.shields.io/github/license/yinlinchen/amplify-preview-actions)](https://github.com/yinlinchen/amplify-preview-actions/blob/master/LICENSE)
[![ISSUES](https://img.shields.io/github/issues/yinlinchen/amplify-preview-actions)](https://github.com/yinlinchen/amplify-preview-actions/issues)

AWS Amplify Pull-Request Previews currently only supports private GitHub repository. This `amplify-preview-actions` GitHub action enables the ability to deploy AWS Amplify Pull-Request Previews for your open source and public GitHub repository.

With this `amplify-preview-actions` GitHub action, you can define your own rule to deploy the Pull-Request branch to the AWS Amplify console app page for a preview. For example, you can setup a rule only a pull request is labeled with `Ready for review` and is assigned to a reviewer; and clean up the previews after the pull request is merged or closed.

## Getting Started
You can include the action in your workflow as `actions/amplify-preview-actions@master`.

### Basic ```workflow.yml``` Example
Deploy a PR preview branch to the Amplify console App page (not the Previews page) after a reviewer is assigned.

Place in a `.yml` file such as this one in your `.github/workflows` folder. [Refer to the documentation on workflow YAML syntax here.](https://help.github.com/en/articles/workflow-syntax-for-github-actions)

```yaml
name: 'Amplify PR Preview'
on:
  pull_request_target:
    types: [review_requested]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master

    - name: set branchname env
      id: setenvname
      run: |
        # use GITHUB_HEAD_REF that is set to PR source branch
        echo "##[set-output name=setbranchname;]$(echo ${GITHUB_HEAD_REF})"

    - name: deploy PR preview
      uses: yinlinchen/amplify-preview-actions@master
      with:
        branch_name: ${{ steps.setenvname.outputs.setbranchname }}
        amplify_command: deploy
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        AmplifyAppId: ${{ secrets.AMPLIFYAPPID }}
        BackendEnvARN: ${{ secrets.BACKENDENVARN }}
        AWS_REGION: 'us-east-1'
```

### Configuration

The following settings must be passed as environment variables as shown in the example. Sensitive information, especially `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, should be [set as encrypted secrets](https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets) — otherwise, they'll be public to anyone browsing your repository's source code and CI logs.

| Key | Value | Suggested Type | Required | Default |
| ------------- | ------------- | ------------- | ------------- | ------------- |
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key. [More info here.](https://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html) | `secret env` | **Yes** | N/A |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Access Key. [More info here.](https://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html) | `secret env` | **Yes** | N/A |
| `AWS_REGION` | The region where you created your bucket. Set to `us-east-1` by default. [Full list of regions here.](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions) | `env` | **Yes** | `us-east-1` |
| `AmplifyAppId` | The unique ID for an Amplify app. For example, `d6a88fjhifqlks` | `secret env` | **Yes** | N/A |
| `BackendEnvARN` | The Amazon Resource Name (ARN) for a backend environment that is part of the Amplify app. If the Amplify App has no backend environment, don't set it. | `secret env` | **No** | N/A |
| `GITHUB_TOKEN` | The `GITHUB_TOKEN`, should be supplied if a comment with the preview URL is to be posted on the PR.  GitHub automatically creates a `GITHUB_TOKEN` secret to use in your workflow. You can use it directly, see [About the GITHUB_TOKEN secret](https://docs.github.com/en/actions/configuring-and-managing-workflows/authenticating-with-the-github_token#about-the-github_token-secret) | `github env` | No | N/A |
| `NewBackendEnvARN` | The Amazon Resource Name (ARN) for a backend environment that is part of an Amplify app. | `secret env` | No | N/A |

#### AWS_SECRET_ACCESS_KEY & AWS_ACCESS_KEY_ID
<details>
  <summary>Click to expand...</summary>

To create these, you'll need to go to [IAM Console](https://console.aws.amazon.com/iam/home)

1. Click on `Users` > `Add User`
2. Click `Enable Programmatic Access`
![image](https://user-images.githubusercontent.com/5545980/93388180-28c69900-f81f-11ea-9ab8-69b04c56f81d.png)
3. On the next screen click `Attach Existing Policies directly` > `Create Policy`
![image](https://user-images.githubusercontent.com/5545980/93388246-45fb6780-f81f-11ea-9415-7b484a168ae3.png)
4. Create a policy called `AmplifyPreviewURL` based on the policy shown here: [AWS access keys & IAM Policy](https://github.com/yinlinchen/amplify-preview-actions#aws-access-keys--iam-policy)
5. Create the user. Copy the `AWS_SECRET_ACCESS_KEY` and `AWS_ACCESS_KEY_ID` to 
</details>

#### AmplifyAppId
<details>
  <summary>Click to expand...</summary>
  
  To get the Amplify App ID, go to the [Amplify Console](https://console.aws.amazon.com/amplify/home).
  
  1. Navigate to the application and click **General**
  2. Copy the id from the `App Arn`, it'll look something like `de63t2jjt7llc`
</details>

#### BackendEnvARN

<details>
  <summary>Click to expand...</summary>
  
  Run:
  ```bash
  aws amplify list-backend-environments --app-id=[app_id]
  ```
</details>



## Inputs

### amplify_command

**type**: `string`  
**values**: `deploy | delete`

#### deploy
Creates a new branch for an Amplify app using `BackendEnvARN` or `NewBackendEnvARN` and deploy your PR to the Amplify console app page (not the Previews page).

#### delete
Deletes a branch for an Amplify app.

## Advanced Examples
Note: All scenarios are assume that the PR is labeled with ```Ready for review``` and a reviewer is assigned.

### Scenario 1:
* A developer submits a PR for review using the existing backend environment. A new PR review branch is deployed to the Amplify console app page (not the Previews page) [Scenario 1](examples.md#scenario-1)

### Scenario 2:
* A developer submits a PR for review using a new backend environment. A new PR review branch using a new backend environment is deployed to the Amplify console app page (not the Previews page) [Scenario 2](examples.md#scenario-2)

### Scenario 3:
* A reviewer finish reviews a PR, approves it, and merges it into the codebase. The PR preview branch is deleted from the Amplify console app page.

or

* A reviewer finish reviews a PR, does not approve it and the developer closes the PR. The PR preview branch is deleted from the Amplify console app page. [Scenario 3](examples.md#scenario-3)

### Live Demo
* You can see a complete setup with above scenarios in [Amplify workshop bookapp demo](https://github.com/yinlinchen/bookapp) and [.github/workflows](https://github.com/yinlinchen/bookapp/tree/master/.github/workflows)

<img src="demo.gif" width="80%"/>

## AWS access keys & IAM Policy
* Minimal necessary permissions IAM policy
  ```
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "VisualEditor1",
              "Effect": "Allow",
              "Action": "amplify:StartJob",
              "Resource": "arn:aws:amplify:${Region}:${Account}:apps/{AppId}/branches/*/jobs/*"
          },
          {
              "Sid": "VisualEditor2",
              "Effect": "Allow",
              "Action": [
                  "amplify:DeleteBranch",
                  "amplify:CreateBranch"
              ],
              "Resource": "arn:aws:amplify:${Region}:${Account}:apps/{AppId}/branches/*"
          }
      ]
  }
  ```

* [How do I create an AWS access key?](https://aws.amazon.com/premiumsupport/knowledge-center/create-access-key/)
* Amplify [IAM Policy](https://docs.amplify.aws/cli/usage/iam#n3-set-up-the-local-development-environment-dev-corp)
* Amplify [IAM Roles & MFA](https://docs.amplify.aws/cli/usage/iam-roles-mfa)

## License

This project is distributed under the [MIT license](LICENSE.md).
