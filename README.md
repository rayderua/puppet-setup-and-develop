# project possibilities
- ### Install puppetserver on your server 
- ### Develop puppet modules by running server/agent via vagrant

## Structure
```bash
├── hiera             # hiera data directory
├── hiera.yaml        # hiera config
├── manifests         # puppet manifests 
├── modules           # puppet modules
├── Puppetfile        # librarian-puppet config (or r10k) 
├── Puppetfile.lock   # librarian-puppet lock file
├── README.md         # Readme
└── Vagrantfile       # vagrant config
```
These files will be synced to /etc/puppetlabs/code/environments/production/ on puppetserver

## Install puppetserver on your server

1. Install puppet-agent
```bash
# Get os codename
OS=$(lsb_release -sc)

# There are no puppetserver packages for debian/bookworm or ubuntu/noble
# use repos for  previous releases 
[ "${OS}" = "noble" ]; then OS="jammy"; fi
[ "${OS}" = "bookworm" ]; then OS="bullseye"; fi

# Install keyrings for puppetlabs repo
sudo curl -fsSL http://apt.puppetlabs.com/pubkey.gpg -o /tmp/puppetlabs.gpg
sudo gpg --dearmor --output /etc/apt/keyrings/puppetlabs.gpg /tmp/puppetlabs.gpg

# Add puppetlabs apt repository
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/puppetlabs.gpg] http://apt.puppetlabs.com ${OS} puppet8" | sudo tee /etc/apt/sources.list.d/puppetlabs.list

# synchronize the package index files 
sudo apt-get update --allow-releaseinfo-change -y -qqq

# install puppet-agent
sudo apt-get install -y -qqq puppet-agent -o DPkg::Options::="--force-confold"
```

2. Create hiera config for your server from example ()
```bash
cp hiera/nodes/puppet.example.com.yaml hiera/nodes/<YOUR_PUPPET_SERVER_FQDN>.yaml
```

3. Change the settings as you wish, for example the postgresql settings
```bash
nano hiera/nodes/<YOUR_PUPPET_SERVER_FQDN>.yaml
```

4. Install. By default will be installed: puppetserver, puppetdb, postgresql-16 
```bash
puppet apply --certname <YOUR_PUPPET_SERVER_FQDN> --modulepath modules --hiera_config hiera.yaml manifests/default.pp
```

5. Sync your envoronments config (e.g. from git) to /etc/puppetlabs/code/environments

Done! 

### Provision local development environment 

1. Install virtualbox - https://www.virtualbox.org/wiki/Linux_Downloads
2. Install vagrant - https://developer.hashicorp.com/vagrant/install
3. Install vagrant plugins
```bash
vagrant plugin install vagrant-hostmanager vagrant-vbguest
```
4. Start puppetserver. By default only puppetserver will be started  
```bash
vagrant up
```

5. Start required agents. Use `vagrant status` for list availables agents (vm with prefix agent- )  
```bash
vagrant up agent-bullseye
```
 
6. Add you production envoronment files to development directory (e.g. manifests, hiera, modules etc) and sync them to puppetserver
```bash
vagrant rsync server
```

7. Run puppet-agent on agent node
```bash
vagrant ssh agent-buster -c 'sudo puppet agent -t'
```
