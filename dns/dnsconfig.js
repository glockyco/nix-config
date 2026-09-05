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

  // `quarantine` is the endpoint, not a stop on the way to `reject`.
  // Quarantine is where the protection arrives: a spoofed apex message lands
  // in spam. Reject adds little on top for a domain with a single sender and
  // no bulk mail, while turning a forgotten legitimate sender from a
  // recoverable spam-folder message into a bounce nobody reads. Subdomains
  // are stricter than the apex because they carry no mail at all.
  //
  // Published without `t=y` staging. That tag demotes the policy on receivers
  // implementing RFC 9989, but RFC 7489 receivers must ignore unknown tags and
  // would enforce at full strength regardless, so it buys an inconsistent
  // half-measure. What it guards against is a sender nobody remembers, and at
  // this volume no observation window would surface one either. Quarantine
  // failing softly is the mitigation.
  //
  // The sender inventory is closed by construction: Fastmail is the only thing
  // that sends as this domain, per-service addresses are Masked Email on other
  // domains, and aggregate reports show direct mail aligning on both SPF and
  // DKIM.
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
  // Inspect failures on the Mac with `fastmail dmarc --failures-only`.
  // If legitimate mail fails, change p=quarantine to p=none here, then run
  // `dnscontrol preview` and `dnscontrol push` from dns/ with authorized
  // Cloudflare credentials. TTL 300 permits recovery within minutes.
  TXT(
    "_dmarc",
    "v=DMARC1; p=quarantine; sp=reject; np=reject; rua=mailto:dmarc@glockyco.com",
    TTL(300),
  ),

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

  // RFC 6186 autoconfiguration. A target of "." means the service is
  // deliberately not offered, which is the correct answer for cleartext IMAP
  // and POP, so these two stay.
  SRV("_imap._tcp", 0, 0, 0, "."),
  SRV("_pop3._tcp", 0, 0, 0, "."),

  // The apex NS records still name Gandi, but Cloudflare answers the apex with
  // its own nameservers and never serves these, so they are inert rows in the
  // dashboard rather than a live misdirection. Cloudflare also rejects apex NS
  // deletion through the API, so they are ignored rather than managed.
  IGNORE("@", "NS", "ns-159-c.gandi.net."),
  IGNORE("@", "NS", "ns-238-b.gandi.net."),
  IGNORE("@", "NS", "ns-243-a.gandi.net."),
);
