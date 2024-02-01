{
  lib,
  config,
  ...
}: {
  age.secrets.admin = {
    file = ../../../secrets/mailserverusers/admin;
    mode = "770";
    owner = "dovecot2";
    group = "dovecot2";
  };
  age.secrets.zoid = {
    file = ../../../secrets/mailserverusers/zoid;
    mode = "770";
    owner = "dovecot2";
    group = "dovecot2";
  };
  services.roundcube = {
     enable = true;
     # this is the url of the vhost, not necessarily the same as the fqdn of
     # the mailserver
     hostName = "arouzing.win";
     extraConfig = ''
       # starttls needed for authentication, so the fqdn required to match
       # the certificate
       $config['smtp_server'] = "tls://${config.mailserver.fqdn}";
       $config['smtp_user'] = "%u";
       $config['smtp_pass'] = "%p";
     '';
  };
  services.nginx = {
    enable = true;
    virtualHosts."arouzing.win" = {
      serverName = "arouzing.win";
      forceSSL = true;
      enableACME = true;
      acmeRoot = "/var/lib/acme/acme-challenge";
    };
  };
  mailserver = {
    enable = true;
    fqdn = "mail.arouzing.win";
    domains = ["arouzing.win"];

    # A list of all login accounts. To create the password hashes, use
    # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
      "admin@arouzing.win".hashedPasswordFile = config.age.secrets.admin.path;
      "hodbogi@arouzing.win".hashedPasswordFile = config.age.secrets.zoid.path;
    };

    # Use Let's Encrypt certificates. Note that this needs to set up a stripped
    # down nginx and opens port 80.
    certificateScheme = "acme-nginx";
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "owner@arouzing.xyz";
    # certs."arouzing.win" = {
    #   email = "cert+${config.security.acme.defaults.email}";
    #   extraDomainNames = [ "mail.arouzing.win" ];
    #   listenHTTP = ":80";
    # };
  };
}
