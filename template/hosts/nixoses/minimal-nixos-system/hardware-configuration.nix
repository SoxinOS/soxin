{
  # Dummy options so the configuration builds
  fileSystems."/".label = "nixos-root";
  boot.loader.grub.device = "/dev/sda";
}
