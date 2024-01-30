{lib, ...}: {
  mailserver = {
    enable = true;
    fqdn = "mail.example.com";
    domains = ["example.com"];

    # A list of all login accounts. To create the password hashes, use
    # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
      "user1@example.com" = {
        hashedPasswordFile = "/a/file/containing/a/hashed/password";
        aliases = ["postmaster@example.com"];
      };
      # "user2@example.com" = { ... };
    };

    # Use Let's Encrypt certificates. Note that this needs to set up a stripped
    # down nginx and opens port 80.
    certificateScheme = "acme-nginx";
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "security@example.com";
}
