# Delete orphan AWS resources (account 132721152261, eu-central-1)
# Run: aws sso login --profile main-iam-admin first, then use profile that has access to 132721152261
$ErrorActionPreference = "Continue"
$profile = "main-iam-admin"
$region = "eu-central-1"

# 1. Lambda
Write-Host "Deleting Lambda function..."
aws lambda delete-function --function-name my-demo-lambda-function --profile $profile --region $region 2>$null

# 2. Target group
Write-Host "Deleting Target group..."
aws elbv2 delete-target-group --target-group-arn "arn:aws:elasticloadbalancing:eu-central-1:132721152261:targetgroup/demo-tg-alb/374ec12fe1fe9e99" --profile $profile --region $region 2>$null

# 3. RDS snapshot
Write-Host "Deleting RDS snapshot..."
aws rds delete-db-snapshot --db-snapshot-identifier "wccstack-snapshot-wccdb4715a016-zeb7efeygp5x" --profile $profile --region $region 2>$null

# 4. RDS DB subnet groups (after any DB instance is gone)
Write-Host "Deleting RDS subnet groups..."
aws rds delete-db-subnet-group --db-subnet-group-name "wccstack-wccdbsubnetgroup9d338c79-86ce38vq0tua" --profile $profile --region $region 2>$null
aws rds delete-db-subnet-group --db-subnet-group-name "default-vpc-0e16b65ae29df2a53" --profile $profile --region $region 2>$null

# 5. Secrets Manager (force no recovery)
Write-Host "Deleting Secret..."
aws secretsmanager delete-secret --secret-id "WccStackWccDbSecret9FA6FE9F-0ojyLBTlUSsg-R4azTa" --force-delete-without-recovery --profile $profile --region $region 2>$null

# 6. Detach IGW from VPCs and delete IGW
Write-Host "Detaching and deleting Internet Gateway..."
aws ec2 detach-internet-gateway --internet-gateway-id igw-019cb2ea1d5782c64 --vpc-id vpc-0425e3f97351d1e26 --profile $profile --region $region 2>$null
aws ec2 detach-internet-gateway --internet-gateway-id igw-019cb2ea1d5782c64 --vpc-id vpc-0e16b65ae29df2a53 --profile $profile --region $region 2>$null
aws ec2 delete-internet-gateway --internet-gateway-id igw-019cb2ea1d5782c64 --profile $profile --region $region 2>$null

# 7. Subnets
Write-Host "Deleting Subnets..."
@("subnet-0f2a1058efe74fdbd","subnet-0c095e5a0d4098de3","subnet-0c742fb83e0a2d837","subnet-033d78fbcfcd06c14","subnet-0393750e2ddbf41f7") | ForEach-Object {
  aws ec2 delete-subnet --subnet-id $_ --profile $profile --region $region 2>$null
}

# 8. Route tables (skip main/default if needed)
Write-Host "Deleting Route tables..."
aws ec2 delete-route-table --route-table-id rtb-05069922bc31d03cd --profile $profile --region $region 2>$null
aws ec2 delete-route-table --route-table-id rtb-060dc6b77114511ed --profile $profile --region $region 2>$null

# 9. Network ACLs (skip default)
Write-Host "Deleting Network ACLs..."
aws ec2 delete-network-acl --network-acl-id acl-0be7d5518151beeab --profile $profile --region $region 2>$null
aws ec2 delete-network-acl --network-acl-id acl-042ea2d60ec651b21 --profile $profile --region $region 2>$null

# 10. Security groups
Write-Host "Deleting Security groups..."
@("sg-0bbfb6ade2a470005","sg-047e13fd8fe3bb9dc","sg-00e4619c04a7a2920","sg-0353b2f6a8c077328") | ForEach-Object {
  aws ec2 delete-security-group --group-id $_ --profile $profile --region $region 2>$null
}

# 11. VPCs
Write-Host "Deleting VPCs..."
aws ec2 delete-vpc --vpc-id vpc-0425e3f97351d1e26 --profile $profile --region $region 2>$null
aws ec2 delete-vpc --vpc-id vpc-0e16b65ae29df2a53 --profile $profile --region $region 2>$null

# 12. DHCP options (if not default)
Write-Host "Deleting DHCP options..."
aws ec2 delete-dhcp-options --dhcp-options-id dopt-03e5c8b7b1722a919 --profile $profile --region $region 2>$null

# 13. KMS keys - schedule for deletion (7 days)
Write-Host "Scheduling KMS keys for deletion..."
@("2a398a2f-c579-4c0e-b7da-471ef4cbd829","2fccdceb-d04b-4cfb-af22-4ed6f8ed2513","486f0055-fcea-4690-84e2-bfcf2e5221b0","53801fd5-932a-424a-b07b-a92bbc35ae70","5f6ec954-d82b-476d-8e55-0adc0910a815","b9c65e2f-d96b-4624-89f5-d6e8d3498ad9") | ForEach-Object {
  aws kms schedule-key-deletion --key-id $_ --pending-window-in-days 7 --profile $profile --region $region 2>$null
}

Write-Host "Done. Check errors above. RDS parameter group default.postgres16 and option group default:postgres-16 are often default and cannot be deleted."
