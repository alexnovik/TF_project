Project deployment demo using teraform

Expected Deliverables:

- Launch an EC2 instance using Terraform
- Connect to the instance
- Install Jenkins, Java and Python in the instance

Deployment plan

 Deploy EC2 instance
 Create VPC 
 Security Group open ports 22, 8080
 Connect to instance and deploy software

 NOTE: Security credentials configured with aws-cli (aws configure)
 and saved in ~/.aws/credentials upon running tf script system asks 
 for profile and it is "default". For unattended run use "terraform apply -var profile=default -auto-approve"
 
 NOTE2: Software post-install running with script.sh 
