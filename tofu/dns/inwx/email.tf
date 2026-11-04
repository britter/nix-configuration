# Mail records for ritter.family (Brevo). The DKIM selector key
# (mail._domainkey) must stay byte-exact or mail signing breaks.

resource "inwx_nameserver_record" "brevo_code" {
  domain  = "ritter.family"
  name    = ""
  type    = "TXT"
  content = "brevo-code:574a88499ea049411afe08defcd9d57d"
  ttl     = 300
}

resource "inwx_nameserver_record" "dkim_record" {
  domain  = "ritter.family"
  name    = "mail._domainkey"
  type    = "TXT"
  content = "k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDeMVIzrCa3T14JsNY0IRv5/2V1/v2itlviLQBwXsa7shBD6TrBkswsFUToPyMRWC9tbR/5ey0nRBH0ZVxp+lsmTxid2Y2z+FApQ6ra2VsXfbJP3HE6wAO0YTVEJt1TmeczhEd2Jiz/fcabIISgXEdSpTYJhb0ct0VJRxcg4c8c7wIDAQAB"
  ttl     = 300
}

resource "inwx_nameserver_record" "dmarc_record" {
  domain  = "ritter.family"
  name    = "_dmarc"
  type    = "TXT"
  content = "v=DMARC1; p=none; rua=mailto:rua@dmarc.brevo.com"
  ttl     = 300
}
