# TODO

- [ ] raspberry pi bindings entfernen
- [ ] ohne plymouth-set-default-theme installierbar machen 
      (
        update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/rpi-spinner/rpi-spinner.plymouth 200
        update-alternatives --config default.plymouth
        update-initramfs -u
      )
- [ ] Test new version 1.2