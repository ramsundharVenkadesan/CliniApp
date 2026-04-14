locals {
  services = [
    "compute.googleapis.com",
    "storage.googleapis.com",
    "cloudkms.googleapis.com",
    "run.googleapis.com", 
    "iam.googleapis.com"
  ]
} // 

resource "google_project_service" "enable_apis" {
  for_each = toset(local.services)
  project  = "cliniclarity"
  service  = each.value
}

module "storage" {
  source     = "./Storage"
  depends_on = [google_project_service.enable_apis]
}


module "compute" {
  source     = "./Compute"
  depends_on = [google_project_service.enable_apis]

  google_api_key    = var.google_api_key
  pinecone_api_key  = var.pinecone_api_key
  huggingface_token = var.hugging_face_token
  index             = pinecone_index.serverless.name
  langchain_api_key = var.langchain_api_key
  cache_bucket_name = module.storage.storage_bucket
}
