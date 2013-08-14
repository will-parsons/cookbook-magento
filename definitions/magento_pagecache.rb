define :magento_pagecache do

  # This must be done AFTER Magento has been configured
  if Chef::Recipe::Magento.tables_exist?(node[:mysql][:bind_address], node[:magento][:db][:username], node[:magento][:db][:password], node[:mysql][:port]) && Chef::Recipe::Magento.ready_for_pagecache?(node[:mysql][:bind_address], node[:magento][:db][:username], node[:magento][:db][:password], node[:mysql][:port], "install")

    # Configuration for PageCache module to be enabled
    execute "pagecache-database-inserts" do
      command "/usr/bin/mysql #{node[:magento][:db][:database]} -u root -h localhost -P #{node[:mysql][:port]} -p#{node[:mysql][:server_root_password]} < /root/pagecache_inserts.sql"
      action :nothing
    end

    # Initializes the page cache configuration
    template "/root/pagecache_inserts.sql" do
      source "pagecache.sql.erb"
      mode "0644"
      owner "root"
      variables(
        :varnishservers => "localhost"
      )
      notifies :run, resources(:execute => "pagecache-database-inserts"), :immediately
    end
  end

end