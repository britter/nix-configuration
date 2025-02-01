resource "cloudflare_record" "brevo_code" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  content = "brevo-code:574a88499ea049411afe08defcd9d57d"
  type    = "TXT"
}

resource "cloudflare_record" "dkim_record" {
  zone_id = var.cloudflare_zone_id
  name    = "mail._domainkey"
  content = "k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDeMVIzrCa3T14JsNY0IRv5/2V1/v2itlviLQBwXsa7shBD6TrBkswsFUToPyMRWC9tbR/5ey0nRBH0ZVxp+lsmTxid2Y2z+FApQ6ra2VsXfbJP3HE6wAO0YTVEJt1TmeczhEd2Jiz/fcabIISgXEdSpTYJhb0ct0VJRxcg4c8c7wIDAQAB"
  type    = "TXT"
}

resource "cloudflare_record" "dmarc_record" {
  zone_id = var.cloudflare_zone_id
  name    = "_dmarc"
  content = "v=DMARC1; p=none; rua=mailto:rua@dmarc.brevo.com"
  type    = "TXT"
}
