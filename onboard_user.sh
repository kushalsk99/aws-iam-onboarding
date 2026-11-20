#!/bin/bash

# Exit immediately if a command fails, an unset variable is used, or a pipe fails
set -euo pipefail

# 1. Validate that exactly 2 arguments were provided
if [ "$#" -ne 2 ]; then
    echo "Error: Invalid number of arguments."
    echo "Usage: $0 <username> <ReadOnly|Developer|Admin>"
    exit 1
fi

USERNAME="$1"
ACCESS_LEVEL="$2"

# 2. Fetch your AWS Account ID dynamically (needed for custom policy ARNs)
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# 3. Map the requested access level to the matching Policy ARN
case "$ACCESS_LEVEL" in
    ReadOnly)
        POLICY_ARN="arn:aws:iam::aws:policy/ReadOnlyAccess"
        ;;
    Developer)
        POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/policy1"
        ;;
    Admin)
        POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/policy2"
        ;;
    *)
        echo "Error: Invalid access level '$ACCESS_LEVEL'."
        echo "Allowed values: ReadOnly, Developer, Admin"
        exit 1
        ;;
esac

# 4. Check if the IAM user already exists to prevent overwriting or errors
if aws iam get-user --user-name "$USERNAME" >/dev/null 2>&1; then
    echo "Error: IAM user '$USERNAME' already exists."
    exit 1
fi

# 5. Create the IAM user
echo "Creating IAM user: $USERNAME..."
aws iam create-user --user-name "$USERNAME" >/dev/null

# 6. Attach the matching policy directly to the user
echo "Attaching $ACCESS_LEVEL policy..."
aws iam attach-user-policy --user-name "$USERNAME" --policy-arn "$POLICY_ARN"

# 7. Print a clean onboarding summary
echo "----------------------------------------"
echo "Onboarding Complete"
echo "Username     : $USERNAME"
echo "Access Level : $ACCESS_LEVEL"
echo "Policy ARN   : $POLICY_ARN"
echo "----------------------------------------"
