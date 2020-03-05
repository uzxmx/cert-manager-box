# -*- mode: ruby -*-
# vi: set ft=ruby :

$num_instances = 2
$instance_name_prefix = 'k8s'
$vm_gui = false
$vm_memory = 2048
$vm_cpus = 2
$subnet = '172.17.9'
$etcd_instances = $num_instances % 2 == 0 ? $num_instances - 1 : $num_instances
$kube_master_instances = $num_instances == 1 ? $num_instances : $num_instances - 1
$kube_node_instances = $num_instances
$host_vars = {}

def provision_kubespray(node, playbook)
  node.vm.provision "kubespray#{playbook == 'reset.yml' ? '_reset' : ''}", type: 'ansible' do |ansible|
    ansible.playbook = File.expand_path("../kubespray/#{playbook}", __FILE__)

    ansible.extra_vars = YAML.load(File.read(File.expand_path('../kubespray_extra_vars.yml', __FILE__)))
    if playbook == 'reset.yml'
      ansible.extra_vars[:reset_confirmation] = 'yes'
    end

    ansible.limit = 'all,localhost'
    ansible.host_key_checking = false
    ansible.raw_arguments = ["--forks=#{$num_instances}", '--flush-cache', '-e ansible_become_pass=vagrant']
    ansible.verbose = true
    ansible.become = true
    ansible.host_vars = $host_vars

    group_vars = {}
    Dir[File.expand_path('../kubespray/inventory/local/group_vars/*', __FILE__)].each do |path|
      name = File.basename(path, '.*')
      if File.directory?(path)
        config_paths = Dir[File.join(path, '*.{yml,yaml,json}')].to_a
      else
        config_paths = [path]
      end
      vars = {}
      config_paths.sort.each do |config_path|
        extname = File.extname(config_path)
        if extname == 'json'
          config = JSON.parse(File.read(config_path))
        else
          config = YAML.load(File.read(config_path))
        end
        if config.is_a?(Hash) && !config.empty?
          config.each do |key, value|
            if value == true || value == false
              config[key] = config[key] ? 'True' : 'False'
            end
          end
          vars.merge!(config)
        end
      end
      group_vars["#{name}:vars"] = vars
    end
    kube_node_start_id = 1
    ansible.groups = group_vars.merge(
      'etcd' => ["#{$instance_name_prefix}-[1:#{$etcd_instances}]"],
      'kube-master' => ["#{$instance_name_prefix}-[1:#{$kube_master_instances}]"],
      'kube-node' => ["#{$instance_name_prefix}-[#{kube_node_start_id}:#{$kube_node_instances}]"],
      'k8s-cluster:children' => ['kube-master', 'kube-node']
    )
  end
end

def provision_init(node)
  node.vm.provision 'init', type: 'ansible' do |ansible|
    ansible.playbook = 'init.yml'
    ansible.host_key_checking = false
    ansible.raw_arguments = ['--flush-cache', '-e ansible_become_pass=vagrant']
    ansible.verbose = true
    ansible.host_vars = $host_vars

    ansible.limit = 'all,localhost'

    kube_node_start_id = 1
    ansible.groups = {
      'kube-master' => ["#{$instance_name_prefix}-[1:#{$kube_master_instances}]"],
      'kube-node' => ["#{$instance_name_prefix}-[#{kube_node_start_id}:#{$kube_node_instances}]"]
    }
  end
end

Vagrant.configure('2') do |config|
  config.vm.box = 'uzxmx/k8s'

  (1..$num_instances).each do |i|
    config.vm.define vm_name = "%s-%01d" % [$instance_name_prefix, i] do |node|
      node.vm.hostname = vm_name

      node.vm.provider :virtualbox do |vb|
        vb.memory = $vm_memory
        vb.cpus = $vm_cpus
        vb.gui = $vm_gui
      end

      ip = "#{$subnet}.#{i+100}"
      node.vm.network :private_network, ip: ip

      $host_vars[vm_name] = { ip: ip }

      # Only execute the Ansible provisioner once, when all the machines are up and ready.
      if i == $num_instances
        if ENV['RESET_CLUSTER'].nil? || ENV['RESET_CLUSTER'].empty?
          provision_kubespray(node, 'cluster.yml')
          provision_init(node)
        else
          provision_kubespray(node, 'reset.yml')
        end
      end
    end
  end
end
