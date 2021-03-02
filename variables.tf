variable "name" {

}

variable "package" {
  type = map(string)
  default = {
    bucket = null
    key    = null
  }
}

variable "version_name" {
  type = string
}

variable "application_name" {
  default = "Custom Application Template Starter"
}

variable "external_api_url" {
  default = ""
}

variable "entrypoint_uri_path" {
  default = "my-custom-app"
}

variable "mc_api_url" {
  default = "https://mc-api.europe-west1.gcp.commercetools.com"
}

variable "local_package" {
  type = string
  default = null
}
