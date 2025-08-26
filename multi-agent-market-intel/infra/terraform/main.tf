terraform {
  required_version = ">= 1.6.0"
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.27.0" }
    helm       = { source = "hashicorp/helm",       version = ">= 2.13.1" }
    aws        = { source = "hashicorp/aws",        version = ">= 5.0.0" }
  }
}

provider "kubernetes" {}
provider "helm" {}
provider "aws" {}

variable "namespace" { default = "mai" }
variable "supabase_jwt_secret" { sensitive = true }
variable "database_url" { description = "Postgres URL" }
variable "audit_bucket" {}
variable "audit_retention_days" { default = 365 }

resource "kubernetes_namespace" "mai" { metadata { name = var.namespace } }

resource "kubernetes_config_map" "api" {
  metadata { name = "api-config" namespace = var.namespace }
  data = { BIND_ADDR = "0.0.0.0:8080", RUST_LOG = "api=info", DATABASE_URL = var.database_url }
}

resource "kubernetes_secret" "api" {
  metadata { name = "api-secrets" namespace = var.namespace }
  data = {
    SUPABASE_JWT_SECRET = base64encode(var.supabase_jwt_secret)
    JWT_AUDIENCE        = base64encode("authenticated")
    JWT_ISSUER          = base64encode("https://YOUR.supabase.co/auth/v1")
  }
}

# S3 WORM bucket
resource "aws_s3_bucket" "audit" {
  bucket = var.audit_bucket
  force_destroy = false
  object_lock_enabled = true
}

resource "aws_s3_bucket_versioning" "audit" {
  bucket = aws_s3_bucket.audit.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_object_lock_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id
  rule { default_retention { mode = "COMPLIANCE" days = var.audit_retention_days } }
}
