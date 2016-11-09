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

        qi_vars = JSON.dump(YAML::load(config.to_yaml))

        basecmd = "sudo PYTHONUNBUFFERED=1 VM_HOSTNAME=#{vm_id} "\
                  "ansible-playbook --extra-vars='#$base_vars' /provisioning/base-playbook.yml"
        instance.vm.provision "shell", inline: basecmd

        cmds = \
        "sudo mkdir -p /var/tmp/#{config['app_name']}/node_modules #{config['folder']['dest']}/node_modules \n"\
        "sudo chown vagrant:vagrant -R /var/tmp/#{config['app_name']}/node_modules #{config['folder']['dest']}/node_modules \n"\
        "sudo mount -o bind /var/tmp/#{config['app_name']}/node_modules #{config['folder']['dest']}/node_modules \n"\
        "sudo ansible-galaxy install -fr /provisioning/#{stack}-requirements.yml \n"\
        "sudo VARS_FILE=#{stack}-vagrant-vars.yml PYTHONUNBUFFERED=1 \\\n"
        if config["deploy"] then
          cmds << "ansible-playbook --tags='install,configure,deploy' --extra-vars='#{qi_vars}' /provisioning/#{stack}-playbook.yml"
        else
          cmds << "ansible-playbook --tags='install,configure' --extra-vars='#{qi_vars}' /provisioning/#{stack}-playbook.yml"
        end
        instance.vm.provision "shell", inline: cmds

      elsif ARGV[0] == "provision" and config["test_cmds"] and config["folder"] and config["folder"]["dest"] then
        test_cmds = "cd #{config['folder']['dest']} \n"
        config["test_cmds"].each do |cmd|
          test_cmds << "DISPLAY=:0 " + cmd + "\n"
        end unless config["test_cmds"].nil?
        instance.vm.provision "shell", privileged: false, inline: test_cmds
      end
    end
  end if apps
end
