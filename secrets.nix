let
  machines = {
    mailserver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIh4HizWNDmonN7QRJr7mAcaE6qjCwe4GcvTaZSV7YnR"; # A normal SSH ed25519 key.
  };
  pth = "./secrets";
  users = {
    sky = "age1yubikey1qd07mh0sznx06zvy3qrzfyajeaveerdg4awzp4t4s5dvc7285n4a23hk6j2"; # the public key
  };
in {

  "${pth}/mailserver".publicKeys = [
    users.sky
    machines.mailserver
  ];
}
