
#!/bin/bash
rm -f /usr/local/bin/mkinst
rm -f /usr/local/bin/vncc
chmod +x mkinst vncc
cp ./mkinst /usr/local/bin
cp ./vncc /usr/local/bin
cp ./recover_inst.sh /etc/init.d/recover_inst.sh
chmod 755 /etc/init.d/recover_inst.sh
update-rc.d recover_inst.sh defaults 90
