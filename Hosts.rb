class Hosts
  def Hosts.configure(config, settings)
    # Configure scripts path variable
    scriptsPath = File.dirname(__FILE__) + '/scripts'

    # Prevent TTY errors
    config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
    config.ssh.forward_agent = true

    # Limit port range
    config.vm.usable_port_range = (10200..10500)

    # Set VirtualBox as provider
    config.vm.provider 'virtualbox'

    settings['hosts'].each_with_index do |host, index|
      autostart = host.has_key?('autostart') && host['autostart']

      config.vm.define "#{host['name']}", autostart: autostart do |server|
        server.vm.box = host['box'] || 'laravel/homestead'

        if settings.has_key?('boxes')
          boxes = settings['boxes']

          if boxes.has_key?(server.vm.box)
            server.vm.box_url = settings['boxes'][server.vm.box]
          end
        end

        server.vm.hostname = host['identifier']

        if host['ip'].kind_of?(Array)
            host['ip'].each do |ip|
                server.vm.network 'private_network', ip: ip
            end
        else
            server.vm.network 'private_network', ip: host['ip'] ||= '192.168.10.10#{index}'
        end


        # VirtulBox machine configuration
        server.vm.provider :virtualbox do |vb|
          vb.name = host['identifier']
          vb.customize ['modifyvm', :id, '--memory', '2048']
          vb.customize ['modifyvm', :id, '--cpus', '1']
          vb.customize ['modifyvm', :id, '--cpuexecutioncap', '30']
          vb.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
          vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
          vb.customize ['modifyvm', :id, '--ostype', 'Ubuntu_64']

          if host.has_key?('provider')
            host['provider'].each do |param|
              vb.customize ['modifyvm', :id, "--#{param['directive']}", param['value']]
            end
          end
        end

        # Standardize Ports Naming Schema
        if (host.has_key?('ports'))
          host['ports'].each do |port|
            port['guest'] ||= port['to']
            port['host'] ||= port['map']
            port['protocol'] ||= 'tcp'
          end
        else
          host['ports'] = []
        end

        # Default port forwarding
        default_ports = {
          80   => 8000,  # HTTP
          443  => 44300, # UDP
          3306 => 33060, # MySQL
          5432 => 54320 # Postgres
        }
        # port 22 => 2222 SSH already configured by Vagrant

        # Default port forwarding unless overridden
        default_ports.each do |guest_port, host_port|
          unless host['ports'].any? { |mapping| mapping['guest'] == guest_port }
            server.vm.network 'forwarded_port', guest: guest_port, host: host_port
          end
        end

        # Custom ports forwarding
        if host.has_key?('ports')
          host['ports'].each do |port|
            server.vm.network 'forwarded_port', guest: port['guest'], host: port['host'], protocol: port['protocol'], auto_correct: true
          end
        end

        # Public Key For SSH Access
        if host.has_key?('authorize')
          server.vm.provision 'shell' do |s|
            s.inline = 'echo $1 | grep -xq "$1" /home/vagrant/.ssh/authorized_keys || echo $1 | tee -a /home/vagrant/.ssh/authorized_keys'
            s.args = [File.read(File.expand_path(host['authorize']))]
          end
        end

        # Register SSH private keys
        if host.has_key?('keys')
          host['keys'].each do |key|
            server.vm.provision 'shell' do |s|
              s.privileged = false
              s.inline = 'echo "$1" > /home/vagrant/.ssh/$2 && chmod 600 /home/vagrant/.ssh/$2'
              s.args = [File.read(File.expand_path(key)), key.split('/').last]
            end
          end
        end

        # Register shared folders
        if host.has_key?('folders')
          host['folders'].each do |folder|
            mount_opts = folder['type'] == 'nfs' ? ['actimeo=1'] : []

            server.vm.synced_folder folder['map'], folder ['to'],
              type: folder['type'],
              owner: folder['owner'] ||= 'www-data',
              group: folder['group'] ||= 'www-data',
              mount_options: mount_opts
            end
        end

        # Configure Nginx sites
        if host.has_key?('sites')
          host['sites'].each do |site|
            server.vm.provision 'shell' do |s|
                if (site.has_key?('hhvm') && site['hhvm'])
                  s.path = scriptsPath + '/serve-hhvm.sh'
                else
                  s.path = scriptsPath + '/serve.sh'
                end
                s.args = [site['map'], site['to'], site['port'] ||= '80', site['ssl'] ||= '443']
            end
          end
        end

        # Configure databases
        if host.has_key?('databases')
          host['databases'].each do |db|
            server.vm.provision 'shell' do |s|
              s.path = scriptsPath + '/create-mysql.sh'
              s.args = [db]
            end

            server.vm.provision 'shell' do |s|
              s.path = scriptsPath + '/create-postgres.sh'
              s.args = [db]
            end
          end
        end

        # Configure environment variables
        if host.has_key?('variables')
          host['variables'].each do |var|
            server.vm.provision 'shell' do |s|
              s.inline = 'echo "\nenv[$1] = \'$2\'" >> /etc/php5/fpm/php-fpm.conf'
              s.args = [var['key'], var['value']]
            end

            server.vm.provision 'shell' do |s|
                s.inline = 'echo "\n#Set Homestead environment variable\nexport $1=$2" >> /home/vagrant/.profile'
                s.args = [var['key'], var['value']]
            end
          end

          server.vm.provision 'shell' do |s|
            s.inline = 'service php5-fpm restart'
          end
        end

        # Run custom provisioners
        if host.has_key?('provision')
            host['provision'].each do |file|
                server.vm.provision 'shell', path: file
            end
        end

        # Configure Blackfire
        if host.has_key?('blackfire')
          server.vm.provision 'shell' do |s|
            s.path = scriptsPath + '/blackfire.sh'
            s.args = [
              host['blackfire'][0]['id'],
              host['blackfire'][0]['token'],
              host['blackfire'][0]['client-id'],
              host['blackfire'][0]['client-token']
            ]
          end
        end
      end
    end
  end
end
