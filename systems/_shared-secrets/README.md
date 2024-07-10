# Shared secrets

This directory contains SOPS secret files that are shared between multiple systems.
The pattern here is to have a directory for the system "owning" the secrets and files inside that directory indicating which other system needs access those secrets.

## Example

The warehouse system hosts a PostgresSQL database and the Nextcloud service installed on cyberoffice needs to have a password to access that database.
In this case warehouse is tha owning system and cyberoffice is the system that needs access to that secret.
For this example there would be a file called `systems/_shared-secrets/warehouse/cyberoffice-secrets.yaml`.

