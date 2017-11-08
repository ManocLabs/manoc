# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "centos/7"

  config.vm.network "forwarded_port", guest: 80, host: 8080


  config.vm.provider "virtualbox" do |vb|
    config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  end

  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "maint/ansible/site.yml"
  end

end
