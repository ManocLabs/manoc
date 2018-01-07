# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "centos/7"

  config.vm.network "forwarded_port", guest: 80, host: 8080


  config.vm.provider "virtualbox" do |vb|
    config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  end

  config.vm.provision "shell",
    inline: "yum install -y git"

  config.vm.provision "ansible_local" do |ansible|
    ansible.galaxy_role_file = "maint/ansible/requirements.yml"
    ansible.playbook = "maint/ansible/playbook.yml"
    ansible.galaxy_roles_path = "/home/vagrant/ansible/roles"
    ansible.install = true
  end

end
