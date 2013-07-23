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

end
