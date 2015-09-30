# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "puppetlabs/centos-7.0-64-puppet"

  config.vm.network "forwarded_port", guest: 3000, host: 8080

  config.vm.provision "shell", path: "vagrant/setup.sh"
end
