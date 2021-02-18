# -*- mode: ruby -*-
# vi: set ft=ruby :

load "settings.sh"

Vagrant.configure("2") do |config|

  config.vm.box = VB_IMAGE
  config.vm.network "public_network", auto_config: true, bridge: LAN_IF

  config.vm.provider "virtualbox" do |virtualbox|
    # Ativando modo promíscuo
    virtualbox.customize ["modifyvm", :id, "--nicpomisc2", "allow-all"]
    virtualbox.memory = VB_RAM

  config.vm.provision "shell", path: "install.sh"

end