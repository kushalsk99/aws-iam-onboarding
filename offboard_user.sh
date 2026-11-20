#!/bin/bash

# Exit immediately if a command fails, an unset variable is used, or a pipe fails
set -euo pipefail

# 1. Validate that exactly 1 argument (username) was provided
if [ "$#" -ne 1 ]; then
    echo "Error: Invalid number of arguments."
    echo "Usage: $0 <username>"
    exit 1
fi

USERNAME="$1"

# 2. Verify the IAM user exists before trying to offboard them
if ! aws iam get-user --user-name "$USERNAME" >/dev/null 2>&1; then
    echo "Error: IAM user '$USERNAME' does not exist."
    exit 1
fi

echo "Starting offboarding for user: $USERNAME..."

# 3. Detach all directly attached managed policies
POLICIES=$(aws iam list-attached-user-policies --user-name "$USERNAME" --query "AttachedPolicies[].PolicyArn" --output text)
for POLICY_ARN in $POLICIES; do
    echo "Detaching policy: $POLICY_ARN"
    aws iam detach-user-policy --user-name "$USERNAME" --policy-arn "$POLICY_ARN"
done

# 4. Delete all programmatic access keys
ACCESS_KEYS=$(aws iam list-access-keys --user-name "$USERNAME" --query "AccessKeyMetadata[].AccessKeyId" --output text)
for KEY_ID in $ACCESS_KEYS; do
    echo "Deleting access key: $KEY_ID"
    aws iam delete-access-key --user-name "$USERNAME" --access-key-id "$KEY_ID"
done

# 5. Delete the console login profile (password), if one exists
if aws iam get-login-profile --user-name "$USERNAME" >/dev/null 2>&1; then
    echo "Deleting console login profile..."
    aws iam delete-login-profile --user-name "$USERNAME"
else
    echo "No console login profile found. Skipping."
fi

# 6. Delete the IAM user
echo "Deleting IAM user: $USERNAME..."
aws iam delete-user --user-name "$USERNAME"

# 7. Print a clean summary
echo "----------------------------------------"
echo "Offboarding Complete"
echo "Removed User : $USERNAME"
echo "----------------------------------------"
