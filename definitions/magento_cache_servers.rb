define :magento_cache_servers do

  # Set page cache servers
  unless node[:magento][:pagecache][:servers].empty?
    cache_servers = String.new

    node[:magento][:pagecache][:servers].each do |ip|
      if cache_servers.empty?
        cache_servers = ip
      else
        cache_servers = cache_servers + ";#{ip}"
      end
    end

    # Configuration for PageCache module to be enabled
    execute "pagecache-database-update" do
      command "/usr/bin/mysql #{node[:magento][:db][:database]} -u root -h localhost -P #{node[:mysql][:port]} -p#{node[:mysql][:server_root_password]} < /root/pagecache_updates.sql"
      action :nothing
    end

    # Initializes the page cache configuration
    template "/root/pagecache_updates.sql" do
      source "pagecache_updates.sql.erb"
      mode "0644"
      owner "root"
      variables(
        :varnishservers => cache_servers
      )
      notifies :run, resources(:execute => "pagecache-database-update"), :immediately
    end
  end

end
