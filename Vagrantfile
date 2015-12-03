# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "centos/7"

  config.vm.network "forwarded_port", guest: 3000, host: 8080

  config.vm.provision "shell", path: "maint/vagrant-setup.sh"
end
