unless File.exist?("#{node[:magento][:dir]}/.installed")

  require 'time'
  inst_date = Time.new.rfc2822()

  # BOF: Initialization block
  case node["platform_family"]
  when "rhel", "fedora"
    include_recipe "yum"
  else
    include_recipe "apt"
  end

  if node.has_key?("ec2")
    server_fqdn = node.ec2.public_hostname
  else
    server_fqdn = node.fqdn
  end

  unless node[:magento][:encryption_key]
    node.set[:magento][:encryption_key] = magento_encryption_key()
    unless Chef::Config[:solo] # Saving the key incase of failed Chef run
      ruby_block "save node data" do
        block do
          node.save
        end
        action :create
      end
    end
  end

  enc_key = node[:magento][:encryption_key] 

  machine = node['kernel']['machine'] =~ /x86_64/ ? 'x86_64' : 'i686'
  webserver = node[:magento][:webserver]
  user = node[:magento][:system_user]
  group = node[webserver]['group']
  php_conf =  if platform?('centos', 'redhat')
                ["/etc", "/etc/php.d"]
              else
                ["/etc/php5/fpm", "/etc/php5/conf.d"]
              end

  user "#{user}" do
    comment "magento guy"
    home "#{node[:magento][:dir]}"
    system true
  end
  # EOF: Initialization block

  # Install php-fpm package
  include_recipe "php-fpm"

  # Centos Polyfills
  if platform?('centos', 'redhat')
    execute "Install libmcrypt" do
      not_if "rpm -qa | grep -qx  'libmcrypt-2.5.7-1.2.el6.rf'"
      command "rpm -Uvh --nosignature --replacepkgs http://pkgs.repoforge.org/libmcrypt/libmcrypt-2.5.7-1.2.el6.rf.#{machine}.rpm"
      action :run
    end
    execute "Install php-mcrypt" do
      not_if "rpm -qa | grep -qx 'php-mcrypt'"
      command "rpm -Uvh --nosignature --replacepkgs http://dl.fedoraproject.org/pub/epel/6/x86_64/php-mcrypt-5.3.3-1.el6.x86_64.rpm"
      action :run
      notifies :restart, "service[php-fpm]"
    end
  end

  # Install required packages
  node[:magento][:packages].each do |package|
    package "#{package}" do
      action :upgrade
    end
  end

  # Ubuntu Polyfills
  if platform?('ubuntu', 'debian')
    bash "Tweak CLI php.ini file" do
      cwd "/etc/php5/cli"
      code <<-EOH
      sed -i 's/memory_limit = .*/memory_limit = 128M/' php.ini
      sed -i 's/;realpath_cache_size = .*/realpath_cache_size = 256K/' php.ini
      sed -i 's/;realpath_cache_ttl = .*/realpath_cache_ttl = 7200/' php.ini
      EOH
    end
  end

  bash "Tweak apc.ini file" do
    cwd "#{php_conf[1]}" # module ini files
    code <<-EOH
    grep -q -e 'apc.stat=0' apc.ini || echo "apc.stat=0" >> apc.ini
    EOH
  end

  bash "Tweak FPM php.ini file" do
    cwd "#{php_conf[0]}" # php.ini location
    code <<-EOH
    sed -i 's/memory_limit = .*/memory_limit = 128M/' php.ini
    sed -i 's/;realpath_cache_size = .*/realpath_cache_size = 256K/' php.ini
    sed -i 's/;realpath_cache_ttl = .*/realpath_cache_ttl = 7200/' php.ini
    EOH
    notifies :restart, resources(:service => "php-fpm")
  end

  directory "#{node[:magento][:dir]}" do
    owner user
    group group
    mode "0755"
    action :create
    recursive true
  end

  magento_site

  # Fetch magento release
  unless node[:magento][:download_url].empty?
    remote_file "#{Chef::Config[:file_cache_path]}/magento.tar.gz" do
      source node[:magento][:download_url]
      mode "0644"
    end
    execute "untar-magento" do
      cwd node[:magento][:dir]
      command "tar --strip-components 1 -xzf #{Chef::Config[:file_cache_path]}/magento.tar.gz"
    end
  end

  # Setup Database
  # if Chef::Config[:solo]
    db_config = {
      :host => node['mysql']['bind_address'],
      :port => node['mysql']['port']
    }
    db_user = node[:magento][:db]
  # else
    # FIXME: data bags search throwing 404 error: Net::HTTPServerException
    # db_config = search(:db_config, "id:master").first || { :host => 'localhost' }
    # db_user = search(:db_users, "id:magento").first || node[:magento][:db]
    # enc_key = search(:magento, "id:enckey").first
  # end

  admin_user = node[:magento][:admin_user]
  if 'localhost' == db_config[:host] || '127.0.0.1' == db_config[:host]
    # Install and configure MySQL
    magento_database
    
  end

  # Import Sample Data
  if node[:magento][:use_sample_data]
    include_recipe "mysql::client"

    remote_file "#{Chef::Config[:file_cache_path]}/magento-sample-data.tar.gz" do
      source node[:magento][:sample_data_url]
      mode "0644"
    end

    bash "magento-sample-data" do
      cwd "#{Chef::Config[:file_cache_path]}"
      code <<-EOH
        mkdir #{name}
        cd #{name}
        tar --strip-components 1 -xzf #{Chef::Config[:file_cache_path]}/magento-sample-data.tar.gz
        mv media/* #{node[:magento][:dir]}/media/

        mv magento_sample_data*.sql data.sql 2>/dev/null
        /usr/bin/mysql -h #{db_config[:host]} -P #{db_config[:port]} -u #{db_user[:username]} -p#{db_user[:password]} #{db_user[:database]} < data.sql
        cd ..
        rm -rf #{name}
        EOH
    end
  end

  bash "Ensure correct permissions & ownership" do
    cwd node[:magento][:dir]
    code <<-EOH
    chown -R #{user}:#{group} #{node[:magento][:dir]}
    chmod -R o+w media
    chmod -R o+w var
    EOH
  end

  magento_initial_configuration

  bash "Touch .installed flag" do
    cwd node[:magento][:dir]
    code <<-EOH
    echo '#{inst_date}' > #{node[:magento][:dir]}/.installed
    EOH
  end

end
