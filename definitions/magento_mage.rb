define :magento_mage do

  php_conf =  if platform?('centos', 'redhat')
                ["/etc", "/etc/php.d"]
              else
                ["/etc/php5/fpm", "/etc/php5/conf.d"]
              end
  
  file "#{node[:magento][:dir]}/mage" do
    mode 0744
    owner node[:magento][:system_user]
  end

  execute "Configuring Mage php.ini location" do
    cwd node[:magento][:dir]
    user node[:magento][:system_user]
    command "./mage config-set php_ini #{php_conf}/php.ini" 
  end

  execute "Install Community Varnish Cache" do
    cwd node[:magento][:dir]
    user node[:magento][:system_user]
    command <<-EOH 
    ./mage channel-add http://connect20.magentocommerce.com/community 
    ./mage install community Varnish_Cache
    EOH
  end

  execute "Copying Community Varnish Configuration" do
    user "root"
    command "cp -f #{node[:magento][:dir]}/app/code/community/Phoenix/VarnishCache/etc/default_3.0.vcl /etc/varnish/default.vcl"
    notifies :restart, "service[varnish]"
  end
  
    execute "Allow Varnish PURGE from ServiceNet" do
    user "root"
    command "sed -i 's/^acl purge \{/acl purge \{\\n  \"10.0.0.0\"\\\/8;/g' /etc/varnish/default.vcl"
    notifies :restart, "service[varnish]"
  end

  # Configuration for PageCache module to be enabled
  execute "pagecache-database-inserts" do
    command "/usr/bin/mysql #{node[:magento][:db][:database]} -u root -h localhost -P #{node[:mysql][:port]} -p#{node[:mysql][:server_root_password]} < #{node[:magento][:dir]}/pagecache_inserts.sql"
    action :nothing
  end

  template "#{node[:magento][:dir]}/pagecache_inserts.sql" do
    source "pagecache.sql.erb"
    mode "0644"
    owner "#{node[:magento][:system_user]}"
    variables(
      :varnishservers => "localhost"
    )
    notifies :run, resources(:execute => "pagecache-database-inserts"), :immediately
  end


end
