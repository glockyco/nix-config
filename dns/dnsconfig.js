var DSP_CLOUDFLARE = NewDnsProvider("cloudflare");
var REG_NONE = NewRegistrar("none");

D("glockyco.com", REG_NONE,
  DnsProvider(DSP_CLOUDFLARE),
  DefaultTTL(1),

  // Fastmail's inbound MX pair keeps delivery independent of the web workers.
  MX("@", 10, "in1-smtp.messagingengine.com."),
  MX("@", 20, "in2-smtp.messagingengine.com."),

  // Fastmail publishes DKIM through these targets, which must remain DNS-only
  // so verifiers receive the key rather than a Cloudflare edge address.
  CNAME("fm1._domainkey", "fm1.glockyco.com.dkim.fmhosted.com."),
  CNAME("fm2._domainkey", "fm2.glockyco.com.dkim.fmhosted.com."),
  CNAME("fm3._domainkey", "fm3.glockyco.com.dkim.fmhosted.com."),

  // Fastmail is the only authorized sender for the domain's mail.
  TXT("@", "v=spf1 include:spf.messagingengine.com ~all"),

  // Subdomains carry no mail, so they enforce immediately while the apex stays
  // at `none` pending the staged rollout in docs/plans.
  //
  // `rua` is in-domain so that RFC 9990 section 4 never applies. Pointing it
  // out of the organizational domain would oblige the receiving domain to
  // publish an authorization record at `<domain>._report._dmarc.<rua-domain>`,
  // and fastmail.com publishes none, so a conforming receiver would have to
  // discard every report.
  //
  // `dmarc@` is a role address on purpose. Mail to it currently resolves via
  // the catch-all, but a catch-all is the first thing to be switched off when
  // the spam gets tiring, and this record is public and load-bearing. The
  // alias has to exist in its own right.
  //
  // TTL 300 keeps every step of the ladder revertible in minutes.
  TXT("_dmarc", "v=DMARC1; p=none; sp=reject; np=reject; rua=mailto:dmarc@glockyco.com", TTL(300)),

  // Cloudflare creates these discard-address records for Worker routes and
  // marks them read-only, so DNSControl must leave them in place rather than
  // trying to recreate them. The comments retain the live proxy state.
  // AAAA("@", "100::", CF_PROXY_ON),
  // AAAA("dashboard", "100::", CF_PROXY_ON),
  // AAAA("hotrepl", "100::", CF_PROXY_ON),
  // AAAA("lnf26", "100::", CF_PROXY_ON),
  // AAAA("www", "100::", CF_PROXY_ON),
  IGNORE("@", "AAAA", "100::"),
  IGNORE("dashboard", "AAAA", "100::"),
  IGNORE("hotrepl", "AAAA", "100::"),
  IGNORE("lnf26", "AAAA", "100::"),
  IGNORE("www", "AAAA", "100::"),

  // Google uses this token to verify ownership of the public site.
  TXT("@", "google-site-verification=jFHLKO_n1tlV12VSycCUJHi7K-iaH2QH6OPRr03In00", TTL(3600)),

  // These are leftovers from Gandi's former mail hosting and are pending
  // deletion in a follow-up commit after the user approves the cleanup.
  CNAME("webmail", "webmail.gandi.net.", CF_PROXY_ON),
  // The old delegation is retained in Cloudflare but is not managed here.
  IGNORE("@", "NS", "ns-159-c.gandi.net."),
  IGNORE("@", "NS", "ns-238-b.gandi.net."),
  IGNORE("@", "NS", "ns-243-a.gandi.net."),
  SRV("_imaps._tcp", 0, 1, 993, "mail.gandi.net."),
  SRV("_imap._tcp", 0, 0, 0, "."),
  SRV("_pop3s._tcp", 10, 1, 995, "mail.gandi.net."),
  SRV("_pop3._tcp", 0, 0, 0, "."),
  SRV("_submission._tcp", 0, 1, 465, "mail.gandi.net."),
);
