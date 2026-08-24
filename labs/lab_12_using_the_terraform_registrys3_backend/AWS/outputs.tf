output "logs_bucket_name" {
  description = "The name of the logs bucket"
  value       = module.s3_buckets["logs"].s3_bucket_id
}
