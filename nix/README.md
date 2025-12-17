First copy the disko config over

```bash
scp disko-config.nix nixos@nixos:/tmp/disko-config.nix
```

Then create a file containing your password at /tmp/secret.key

```bash
echo 'my-password' > /tmp/secret.key
```

Next, create the partition table using disko.

```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /tmp/disko-config.nix
```

Once complete, generate the config on the machine, telling nix to not generate filesystems.

```bash
sudo nixos-generate-config --no-filesystems --root /mnt
```

Switch to root and create password

```bash
sudo su -
```

```bash
passwd
```

Copy over other nix config

```bash
scp -r ~/.dotfiles/nix/* root@nixos:/mnt/etc/nixos/
```

Move hardware config to host you are using

```bash
sudo mv /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hosts/joejadnix/hardware-configuration.nix
```

Finally, you can install nixos and then reboot

```bash
sudo nixos-install --root /mnt --flake '/mnt/etc/nixos#joejadnix'
sudo reboot
```
