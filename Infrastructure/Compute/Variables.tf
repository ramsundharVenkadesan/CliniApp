variable "health_check" {
  type = string
  default = "autohealing-check"

  validation {
    condition = length(var.health_check) > 5
    error_message = "A valid name is required for the health check"
  }
}

variable "google_api_key" {
  type = string

  validation {
    condition = length(var.google_api_key) > 10
    error_message = "Missing Gemini API key"
  }
}
variable "pinecone_api_key" {
  type = string

  validation {
    condition = length(var.pinecone_api_key) > 10
    error_message = "Missing Pinecone API key"
  }
}

variable "huggingface_token" {
  type = string

  validation {
    condition = length(var.huggingface_token) > 10
    error_message = "Missing Hugging-Face API key"
  }
}

variable "index" {
  type = string
  validation {
    condition = length(var.index) > 5
    error_message = "Missing database index"
  }
}
variable "langchain_api_key" {
  type = string

  validation {
    condition = length(var.langchain_api_key) > 10
    error_message = "Missing LangChain API key"
  }
}
variable "cache_bucket_name" {
  type = string

  validation {
    condition = length(var.cache_bucket_name) > 5
    error_message = "Missing cache bucket"
  }
}

variable "regional_instance_group" {
  type = string
  default = "cliniclarity-app-server"
  validation {
    condition = length(var.regional_instance_group) > 5
    error_message = "A valid name is required for the regional instance group"
  }
}

variable "region" {
  type = string
  default = "us-central1"
  validation {
    condition = strcontains(var.region, "-")
    error_message = "A valid region is required to deploy infrastructure"
  }
}

variable "instance_template" {
  type = string
  default = "server-template"
  validation {
    condition = length(var.instance_template) > 5
    error_message = "A valid name is required for the instance template"
  }
}

variable "autoscaler" {
  type = string
  default = "cliniclarity-autoscaler"
  validation {
    condition = length(var.autoscaler) > 5
    error_message = "A valid name is required for the autoscaler"
  }
}

variable "backend" {
  type = string
  default = "cliniclarity-backend"
  validation {
    condition = length(var.backend) > 5
    error_message = "A valid name is required for backend"
  }
}

variable "port_name" {
  type = string
  default = "cliniclarity-port"
  validation {
    condition = length(var.port_name) > 5
    error_message = "A valid port name is required"
  }
}

