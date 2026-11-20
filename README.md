# Cloud Access Management & User Onboarding Automation (AWS IAM)

## Overview
A hands-on AWS IAM project built on the AWS Free plan to implement least-privilege access control and automate user lifecycle management (onboarding and offboarding) using Bash and the AWS CLI.

### Free Plan Constraints & Workarounds
- **Locked IAM User Groups:** Attached managed and custom IAM policies directly to individual users instead of groups.
- **IAM User MFA Restriction:** Enabled Multi-Factor Authentication (MFA) on the AWS Root account to secure top-level access.
- **Account-Level SCP on EC2:** Verified least-privilege enforcement via AWS CLI (`iam:CreateUser` denied with `AccessDenied` for the ReadOnly user).

---

## Access Levels (Least Privilege)
- **ReadOnly:** AWS managed `ReadOnlyAccess` policy (view-only access, no write/delete permissions).
- **Developer (`policy1`):** Custom policy granting `ec2:*` and `s3:*` with no IAM permissions.
- **Admin (`policy2`):** Custom policy scoped to EC2, S3, and IAM user/policy management for this lab (no billing or account-wide admin access).

---

## Setup Steps
1. Created custom IAM policies (`policy1` for Developer, `policy2` for limited Admin) in the AWS Console.
2. Created the `lab-admin` IAM user, attached `policy2` directly, and generated CLI access keys.
3. Configured a dedicated AWS CLI profile (`iam-lab`) locally.
4. Enabled virtual MFA on the AWS Root account using an authenticator app.
5. Wrote and executed `onboard_user.sh` and `offboard_user.sh` to automate user provisioning and deprovisioning.
6. Tested `test-readonly` via CLI credentials to verify write actions are blocked.

---

## Commands Executed

```bash
# Configure and activate the dedicated CLI profile
aws configure --profile iam-lab
export AWS_PROFILE=iam-lab
aws sts get-caller-identity

# Make scripts executable
chmod +x onboard_user.sh offboard_user.sh

# Onboard a ReadOnly user and a Developer user
./onboard_user.sh test-readonly ReadOnly
./onboard_user.sh test-dev Developer

# Offboard the Developer user (detaches policies, deletes keys/login profile, deletes user)
./offboard_user.sh test-dev

# Verify ReadOnly restrictions via CLI
aws iam create-access-key --user-name test-readonly
export AWS_ACCESS_KEY_ID="<TEST_READONLY_KEY>"
export AWS_SECRET_ACCESS_KEY="<TEST_READONLY_SECRET>"
aws iam create-user --user-name should-fail   # Expected: AccessDenied
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
