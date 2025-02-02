terraform {
    backend "s3" {
        bucket = "your-bucket-name"
        key = "global/s3/terrafrom.tfstate"
        region = "your-region"
        dynamodb_table = "s3-tf-state-table"
        
    }
}
