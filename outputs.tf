output "wordpress_url" {
  value = "http://${module.alb.alb_dns_name}"
}

# Commented out due to CloudFront Error: "Your account must be verified before you can add new CloudFront resources"
# output "cloudfront_url" {
#   value = "https://${module.cloudfront.cloudfront_domain_name}"
# }
