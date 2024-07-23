# Configure the AWS Provider
provider "aws" {
    region = "eu-west-2"
} 

    # Create an S3 bucket
    resource "aws_s3_bucket" "website_bucket" {
        bucket = "patchez-s3-static-web-bucket"
        
        tags = {
            Name = "s3-static-website"
        }
    }

    # Bucket ownership
    resource "aws_s3_bucket_ownership_controls" "website_bucket_acl_ownership" {
        bucket = aws_s3_bucket.website_bucket.id

        rule {
            object_ownership = "BucketOwnerPreferred"
        }
    }

    # Enable public static website hosting
    resource "aws_s3_bucket_public_access_block" "website_public_access" {
        bucket = aws_s3_bucket.website_bucket.id

        block_public_acls = false
        block_public_policy = false
        ignore_public_acls = false
        restrict_public_buckets = false
    }

    # S3 bucket ACL
    resource "aws_s3_bucket_acl" "website_bucket_acl" {
        depends_on = [
            aws_s3_bucket_ownership_controls.website_bucket_acl_ownership,
            aws_s3_bucket_public_access_block.website_public_access,
        ]

        bucket = aws_s3_bucket.website_bucket.id
        acl = "private"
    } 

    # Bucket policy
    resource "aws_s3_bucket_policy" "website_bucket_policy" {
        bucket = aws_s3_bucket.website_bucket.id

        policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
                {
                    Sid = "PublicReadGetObject"
                    Effect = "Allow"
                    Principal = "*"
                    Action = "s3:GetObject"
                    Resource = "${aws_s3_bucket.website_bucket.arn}/*"
                }
            ]

        })

    }

    # Create an Origin Access Identity for CloudFront
    resource "aws_cloudfront_origin_access_identity" "oai" {
        comment = "OAI for Cloudfront to access S3"
    }

    # Configure the bucket for website hosting
    resource "aws_s3_bucket_website_configuration" "website_config" {
        bucket = aws_s3_bucket.website_bucket.id

        index_document {
            suffix = "index.html"
        }

        error_document {
            key = "error.html"
        }
    }

    # Create Cloudfront Distribution
    resource "aws_cloudfront_distribution" "cdn" {
        origin {
            domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
            origin_id = "S3-${aws_s3_bucket.website_bucket.bucket}"

            s3_origin_config {
                origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
            }
        }

        enabled = true
        is_ipv6_enabled = true
        default_root_object = "index.html"
        comment = "Next.js static site"

        default_cache_behavior {
            allowed_methods = ["GET", "HEAD", "OPTIONS"]
            cached_methods = ["GET", "HEAD"]
            target_origin_id  = "S3-${aws_s3_bucket.website_bucket.bucket}"

            forwarded_values {
                query_string = false
                
                cookies {
                forward = "none"
                }
            }

            viewer_protocol_policy = "redirect-to-https"
            min_ttl = 0
            default_ttl = 3600
            max_ttl = 86400
        }

        viewer_certificate{
            cloudfront_default_certificate = true
        }

        restrictions {
            geo_restriction {
                restriction_type = "none"
            }
        }

        tags = {
            Name = "cloudfront"
        }
    }