# This Vagrantfile is a good example of provisioning multiple EC2 instances
# using a single file.
# http://stackoverflow.com/questions/24385079/multiple-ec2-instances-using-vagrant
# read aws specific config from json file
aws_cfg = (JSON.parse(File.read("aws.json")))

# read env vars and store them
keypair_name = ENV['AWS_KEYPAIR_NAME']
access_key_id = ENV['AWS_ACCESS_KEY']
secret_access_key = ENV['AWS_SECRET_KEY']
security_groups = ENV['AWS_SECURITYGROUP']
private_key_path = ENV['AWS_KEYPATH']

# start vagrant configuration
Vagrant.configure(2) do |config|

  config.vm.box = "dummy"
  config.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"


  # loop through each of 'ec2s' key
  aws_cfg['ec2s'].each do |node|
    node_name  = node[0]
    node_value = node[1]
    # Node specific configuration
    config.vm.define node_name do |config2|

      # retrieve node tags
      ec2_tags = node_value['tags']

      # Spin up EC2 instances
      config2.vm.provider :aws do |ec2, override|
        ec2.keypair_name = keypair_name
        ec2.access_key_id = access_key_id
        ec2.secret_access_key = secret_access_key
        ec2.security_groups = security_groups
        override.ssh.private_key_path = private_key_path

        # read region, ami etc from json.
        # default(Mumbai) region, Amazon Linux, T2 Micro
        # (this combination is known to work)
        ec2.region = aws_cfg['region']
        ec2.availability_zone = aws_cfg['region']+aws_cfg['availability_zone']
        ec2.ami = node_value['ami_id']
        ec2.instance_type = node_value['instance_type']
        #ec2.private_ip_address = node_value['private_ip_address']
        override.ssh.username = aws_cfg['ssh_username']
        override.nfs.functional = false
        ec2.tags = {
          'Name'         => ec2_tags['Name'],
          'Role'         => ec2_tags['Role'],
          'ServiceType'  => ec2_tags['ServiceType'],
        }


        # use ansible to run a playbook.
        # if we want to switch to say, chef or puppet we should be able
        # to do that here.
        # the playbook will in turn, setup a docker environment.

      end # config.vm.provider :aws

    end #config.vm.define node_name
  end # aws_cfg['ec2s']

  config.vm.provision "ansible" do |ansible|
    # autodownload dependent roles
    #ansible.galaxy_role_file = "./provisioning/requirements.yml"
    #ansible.galaxy_roles_path = "./provisioning"

    ansible.groups = {
      "docker" => ["seed0", "manager0", "manager1"],
      "swarm_seed" => ["seed0"],
      "swarm_managers" => ["manager0", "manager1"]
    }
    ansible.verbose = "vvvv"
    ansible.playbook = "provisioning/playbook.yml"
    ansible.limit = "all"
    ansible.host_key_checking = false
    ansible.extra_vars = { ansible_python_interpreter: "/usr/bin/python3" }
  end


end
