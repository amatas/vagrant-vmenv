# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

def config_provision(instance, vm_config, vm_id, apps)


  apps.each do |config|
    if config["run_in"] == vm_id then
      if ARGV[0] == "up" then
        app = config["app_name"] #app_name
        stack = config["software_stack"]

        #check if every file is in place
        raise "File vagrant/provisioning/#{stack}-requirements.yml doesn't exist"\
          unless File.file?(VAGRANT_VMENV_PATH + "/provisioning/#{stack}-requirements.yml")
        raise "File vagrant/provisioning/#{stack}-vars.yml doesn't exist"\
          unless File.file?(VAGRANT_VMENV_PATH + "/provisioning/#{stack}-vagrant-vars.yml")
        raise "File vagrant/provisioning/#{stack}-playbook.yml doesn't exist"\
          unless File.file?(VAGRANT_VMENV_PATH + "/provisioning/#{stack}-playbook.yml")
        raise "File vagrant/provisioning/base-playbook.yml doesn't exist"\
          unless File.file?(VAGRANT_VMENV_PATH + "/provisioning/base-playbook.yml")

        File.open(VAGRANT_VMENV_PATH + "/provisioning/#{vm_id}-#{app}-vagrant-vars.yml",'w') do |h|
             h.write config.to_yaml
        end

        basecmd = "sudo PYTHONUNBUFFERED=1 VM_HOSTNAME=#{vm_id} "\
                  "ansible-playbook /vagrant/#{VAGRANT_VMENV_PATH}/provisioning/base-playbook.yml"
        instance.vm.provision "shell", inline: basecmd

        cmds = \
        "sudo ansible-galaxy install -fr /vagrant/#{VAGRANT_VMENV_PATH}/provisioning/#{stack}-requirements.yml \n"\
        "sudo VARS_FILE=#{stack}-vagrant-vars.yml QI_VARS_FILE=#{vm_id}-#{app}-vagrant-vars.yml PYTHONUNBUFFERED=1 \\\n"
        if config["deploy"] then #app_start_service
          cmds << "ansible-playbook --tags='install,configure,deploy' /vagrant/#{VAGRANT_VMENV_PATH}/provisioning/#{stack}-playbook.yml"
        else
          cmds << "ansible-playbook --tags='install,configure' /vagrant/#{VAGRANT_VMENV_PATH}/provisioning/#{stack}-playbook.yml"
        end
        instance.vm.provision "shell", inline: cmds

      elsif ARGV[0] == "provision" then
        test_cmds = "cd /vagrant \n"
        config["test_cmds"].each do |cmd|
          test_cmds << "DISPLAY=:0 " + cmd + "\n"
        end unless config["commands"].nil?
        instance.vm.provision "shell", privileged: false, inline: test_cmds
      end
    end
  end if apps
end
