# -*- mode: ruby -*-
# vi: set ft=ruby :

$SERVER_MEM = 4096
$SERVER_CPU = 4

$AGENT_MEM = 4096
$AGENT_CPU = 4

$INSTALL_PUPPET_AGENT = <<SCRIPT
#!/bin/bash
set -e
set -x
export DEBIAN_FRONTEND=noninteractive
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
export OS=$(lsb_release -sc)

# apt tricks
if [ "$OS" = "buster" ]; then
    sed -iE '/^deb.*backports.*/d' /etc/apt/sources.list
fi;

apt-get update --allow-releaseinfo-change -y -qqq

command -v curl >/dev/null || apt-get install -qqq -y curl -o DPkg::Options::="--force-confold"
command -v gpg >/dev/null || apt-get install -qqq -y gnupg2 -o DPkg::Options::="--force-confold"

if [ ! -d /etc/apt/keyrings ]; then
    mkdir -p /etc/apt/keyrings
fi;

if [ ! -f  /etc/apt/keyrings/puppetlabs.gpg ]; then
    curl -fsSL http://apt.puppetlabs.com/pubkey.gpg -o /tmp/puppetlabs.gpg
    gpg --dearmor --output /etc/apt/keyrings/puppetlabs.gpg /tmp/puppetlabs.gpg
fi;

if [ ! -f /etc/apt/sources.list.d/puppetlabs.list ]; then
    if [ "${OS}" = "noble" ]; then OS="jammy"; fi
    if [ "${OS}" = "bookworm" ]; then OS="bullseye"; fi

    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/puppetlabs.gpg] http://apt.puppetlabs.com ${OS} puppet8" | tee /etc/apt/sources.list.d/puppetlabs.list
    apt-get update --allow-releaseinfo-change -y -qqq
fi;

dpkg-query -W puppet-agent >/dev/null || apt-get install -y -qqq puppet-agent -o DPkg::Options::="--force-confold"

test -f /usr/local/bin/puppet || ln -sf /opt/puppetlabs/bin/puppet /usr/local/bin/
test -f /usr/local/bin/facter || ln -sf /opt/puppetlabs/bin/facter /usr/local/bin/

cat > /etc/puppetlabs/puppet/csr_attributes.yaml << EOF
custom_attributes:
  1.2.840.113549.1.9.7: autosignpassword
EOF
chmod 0600 /etc/puppetlabs/puppet/csr_attributes.yaml

# hostname tricks
sed -i  '/^127.0.0.2/d' /etc/hosts
HOSTNAME=$(cat /etc/hostname | cut -d'.' -f1)
grep -q 127.0.1.1 /etc/hosts || echo "127.0.1.1 $HOSTNAME.local $HOSTNAME" >> /etc/hosts
SCRIPT

Vagrant.configure("2") do |config|
    config.vbguest.auto_update = false
    config.hostmanager.enabled = true
    config.hostmanager.manage_guest = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true

    config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
        cached_addresses = {}
        if cached_addresses[vm.name].nil?
            if hostname = (vm.ssh_info && vm.ssh_info[:host])
                vm.communicate.execute("/usr/sbin/ip -4 -br addr show dev eth1 | awk '{print $3}' | cut -f 1 -d '/' 2>&1") do |type, contents|
                    cached_addresses[vm.name] = contents.split("\n").first[/(\d+\.\d+\.\d+\.\d+)/, 1]
                end
            end
        end
        cached_addresses[vm.name]
    end

    # install puppet-agent no all machines
    config.vm.provision "puppet-agent", type: "shell", run: "once" do |s|
        s.inline = $INSTALL_PUPPET_AGENT
    end

    config.vm.provision "puppet-init", type: "puppet", run: "once" do |puppet|
        puppet.manifests_path = "manifests"
        puppet.module_path = "modules"
        puppet.hiera_config_path = "hiera.yaml"
        puppet.working_directory = "/tmp/vagrant-puppet"
        puppet.synced_folder_type = "rsync"
    end
    config.vm.synced_folder "hiera", "/tmp/vagrant-puppet/hiera",  type: "rsync", rsync__auto: true

    # Setup puppet server
    config.vm.define "server", autostart: true do | server |
        # tested: debian/bookworm64 | debian/bullseye64 | bento/ubuntu-24.04 | ubuntu/jammy64
        server.vm.box = "debian/bookworm64"
        server.vm.hostname = "server.local"
        server.hostmanager.aliases = 'puppet puppet.local'
        server.vm.network :private_network, type: "dhcp"
        server.vm.provider "virtualbox" do |v|
            v.name  = "puppet-server"
            v.memory = $SERVER_MEM
            v.cpus = $SERVER_CPU
            v.destroy_unused_network_interfaces = true
        end

        server.vm.synced_folder ".", "/etc/puppetlabs/code/environments/production",
            disabled: false,
            type: "rsync",
            rsync__args: ["--rsync-path='sudo rsync'", "--archive", "--delete", "-z"],
            rsync__exclude: ".git/,.gitignore/,.idea/,.vagrant/,.librarian/,.tmp/,README.md,Vagrantfile"
    end

    config.vm.define "agent-buster", autostart: false do |agent|
        agent.vm.box = "debian/buster64"
        agent.vm.hostname = "buster.local"
        agent.vm.network :private_network, type: "dhcp"
        agent.vm.provider "virtualbox" do |v|
            v.name = "puppet-agent-buster"
            v.memory = $AGENT_MEM
            v.cpus = $AGENT_CPU
        end
    end

    config.vm.define "agent-bullseye", autostart: false do |agent|
        agent.vm.box = "debian/bullseye64"
        agent.vm.hostname = "bullseye.local"
        agent.vm.network :private_network, type: "dhcp"
        agent.vm.provider "virtualbox" do |v|
            v.name = "puppet-agent-bullseye"
            v.memory = $AGENT_MEM
            v.cpus = $AGENT_CPU
        end
    end

    config.vm.define "agent-bookworm", autostart: false do |agent|
        agent.vm.box = "debian/bookworm64"
        agent.vm.hostname = "bookworm.local"
        agent.vm.network :private_network, type: "dhcp"
        agent.vm.provider "virtualbox" do |v|
            v.name = "puppet-agent-bookworm"
            v.memory = $AGENT_MEM
            v.cpus = $AGENT_CPU
        end
    end

    config.vm.define "agent-noble", autostart: false do |agent|
        agent.vm.box = "bento/ubuntu-24.04"
        agent.vm.hostname = "noble.local"
        agent.vm.network :private_network, type: "dhcp"
        agent.vm.provider "virtualbox" do |v|
            v.name = "puppet-agent-noble"
            v.memory = $AGENT_MEM
            v.cpus = $AGENT_CPU
        end
    end

    config.vm.define "agent-jammy", autostart: false do |agent|
        agent.vm.box = "ubuntu/jammy64"
        agent.vm.hostname = "jammy.local"
        agent.vm.network :private_network, type: "dhcp"
        agent.vm.provider "virtualbox" do |v|
            v.name = "puppet-agent-jammy"
            v.memory = $AGENT_MEM
            v.cpus = $AGENT_CPU
        end
    end

    config.vm.define "agent-focal", autostart: false do |agent|
        agent.vm.box = "ubuntu/focal64"
        agent.vm.hostname = "focal.local"
        agent.vm.network :private_network, type: "dhcp"
        agent.vm.provider "virtualbox" do |v|
            v.name = "puppet-agent-focal"
            v.memory = $AGENT_MEM
            v.cpus = $AGENT_CPU
        end
    end
end
