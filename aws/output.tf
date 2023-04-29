output "cluster_endpoint" {
  description = "The hostname assigned to the mysql instance"
  value       = module.cluster.cluster_endpoint
}