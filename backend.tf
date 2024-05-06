# Define Terraform backend using a S3 bucket for storing the Terraform state
terraform {
  backend "s3" {
    bucket = "my-first-bucket-terraform-state"
    key = "terraform-state/terraform.tfstate"   #use the bucket you created in your main.tf file
    region = "eu-west-3"
    dynamodb_table = "terraform-sm-locks"
    encrypt = true
 }
}
