require 'yaml'

VAGRANTFILE_API_VERSION = "2"

configuration = YAML::load(File.read("#{File.dirname(__FILE__)}/Hosts.yaml"))
runPath = "#{File.dirname(__FILE__)}/" + configuration["path"]

require File.expand_path("#{runPath}/Hosts.rb")

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    Hosts.configure(config, configuration)
end
