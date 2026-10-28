terraform {
  required_version = ">= 0.13.0"
  backend "s3" {
    bucket                      = "tofu-states-keycloak"
    key                         = "terraform.tfstate"
    region                      = "garage"
    endpoint                    = "https://garage.srv-prod-3.ritter.family"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.10.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }
}

provider "sops" {}

data "sops_file" "secrets" {
  source_file = "secrets.json"
}

# Official provider, hosted under the keycloak org since 2024-12.
# Client-credentials grant against the `tofu` service-account client in the
# master realm — the provider docs' recommended setup.
provider "keycloak" {
  client_id     = data.sops_file.secrets.data["keycloak_admin_client_id"]
  client_secret = data.sops_file.secrets.data["keycloak_admin_client_secret"]
  url           = data.sops_file.secrets.data["keycloak_url"]
  # Required for servers >= 26.4 (provider fails version parsing otherwise).
  # Keep in sync with the nixpkgs keycloak version; renovate bumps both.
  keycloak_version = "26.8.1"
}
