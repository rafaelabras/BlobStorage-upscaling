variable "location_resource" {
  description = "Regiao do azure para deploy de resources"
  type        = string
  default     = "East US"

}

variable "BlobServiceUri" {
  description = "BlobServiceUri"
  type        = string
  default     = "https://upscalingstorageacc921.blob.core.windows.net" 
}

variable "StorageAccountName" {
  description = "StorageAccountName"
  type        = string
  default     = "upscalingstorageacc912" 
}