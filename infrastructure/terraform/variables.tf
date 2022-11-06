// Sensitive variables without a default are defined in the `.tfvars` file

variable "token" {
  description = "YC IAM Token"
  sensitive   = true
}

variable "cores" {
  description = "cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "memory"
  type        = number
  default     = 2
}

variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  sensitive   = true
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  sensitive   = true
}

variable "zone" {
  description = "Yandex Cloud zone"
  type        = string
  default     = "ru-central1-a"
}

variable "s3_access_key" {
  description = "Yandex Storage access key"
  type        = string
  sensitive   = true
}

variable "s3_secret_key" {
  description = "Yandex Storage secret key"
  type        = string
  sensitive   = true
}
