# Firewall Policy Import TODO

Remaining policies from `TO-IMPORT.json` to import into OpenTofu.

## Instructions

1. Pick the next policy from the list below
2. Add the resource config to `firewall_policies.tf`, following the existing patterns there
3. Run `tofu import unifi_firewall_policy.<resource_name> <id>`
4. Run `tofu plan` to verify — it must show "No changes"
5. Remove the imported entry from `TO-IMPORT.json`
6. **STOP.** Wait for user to commit before continuing.

**NEVER run `tofu apply`.** Infrastructure changes only via GitHub Actions.

Fetch policy details from the controller with:
```
curl -s -X GET "https://unifi.ritter.family/proxy/network/v2/api/site/default/firewall-policies/<id>" \
  -H "X-API-KEY: $API_KEY" \
  -H 'Accept: application/json' | jq .
```

## Network ID mapping

| Network    | ID                       |
|------------|--------------------------|
| trusted    | 696cb71b8ea6ae4ba05d1c25 |
| homelab    | 69639c458ea6ae4ba05c240a |
| servers    | 696cb69c8ea6ae4ba05d1c15 |
| management | 696cb5fc8ea6ae4ba05d1beb |
| smart_home | 696cb64f8ea6ae4ba05d1c0f |
| kvms       | 696cb6df8ea6ae4ba05d1c1d |
| not        | 69639c2e8ea6ae4ba05c2404 |
| iot        | 695d243c8ea6ae4ba05b8d26 |
| guests     | 695d24088ea6ae4ba05b8d23 |
| blackhole  | 696cb8d18ea6ae4ba05d1ca2 |
| default    | 695804925c7e97282f5a0fc8 |

## Remaining policies

- [ ] Allow Traffic from Trusted to PVE on 8006 (`696be1fd8ea6ae4ba05d0365`)
- [ ] Allow UDP from Trusted to KVMs (`696be5398ea6ae4ba05d03d2`)
- [ ] Allow Traffic from Trusted to Home Assistant (`696ea0ac8ea6ae4ba05d4ed7`)
- [ ] Allow Home Assistant to Control Yeelights in NoT (`69763804e999852897739f04`)
- [ ] Allow Poxying of Home Assistant (`69766e61e99985289773a6af`)
- [ ] Allow PVE Management from Trusted (`697e1d69e999852897748720`)
- [ ] Allow HTTPS from Servers to Homelab (`69863cd4e999852897757f4b`)
- [ ] Allow Servers to access DNS in Homelab (`6987139ee999852897759de1`)
- [ ] Allow Servers to access DNS-TLS in Homelab (`698713d2e999852897759de4`)
- [ ] Allow Trusted to Print (`698b399be999852897762106`)
- [ ] Allow HTTP form Homelab to servers (`69bfe2d5b84e03db685a8bc7`)
- [ ] Allow HTTPS from Homelab to servers (`69bfe30fb84e03db685a8bca`)
- [ ] Allow NFS mount from Servers to Management (`69c82444b84e03db685b7fc9`)
- [ ] Allow PVE proxying via directions (`6a40ff6245682d57c09a27f1`)
