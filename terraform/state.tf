terraform {
    backend "s3" {
        bucket = "patchez-terraform-state"
        key = "global/s3/terrafrom.tfstate"
        region = "eu-west-2"
        dynamodb_table = "s3-tf-state-table"
        
    }
}