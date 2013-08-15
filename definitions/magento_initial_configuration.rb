define :magento_initial_configuration do
  # Configure all the things
  bash "Configure Magento" do
    cwd node[:magento][:dir]
    user node[:magento][:system_user]
    code  <<-EOH
    php -f install.php -- \
    --license_agreement_accepted "yes" \
    --locale "#{node[:magento][:locale]}" \
    --timezone "#{node[:magento][:timezone]}" \
    --default_currency "#{node[:magento][:default_currency]}" \
    --db_host "#{node['mysql']['bind_address']}:#{node['mysql']['port']}" \
    --db_model "#{node[:magento][:db][:model]}" \
    --db_name "#{node[:magento][:db][:database]}" \
    --db_user "#{node[:magento][:db][:username]}" \
    --db_pass "#{node[:magento][:db][:password]}" \
    --db_prefix "#{node[:magento][:db][:prefix]}" \
    --session_save "#{node[:magento][:session][:save]}" \
    --admin_frontname "#{node[:magento][:admin_frontname]}" \
    --url "#{node[:magento][:url]}" \
    --use_rewrites "#{node[:magento][:use_rewrites]}" \
    --use_secure "#{node[:magento][:use_secure]}" \
    --secure_base_url "#{node[:magento][:secure_base_url]}" \
    --use_secure_admin "#{node[:magento][:use_secure_admin]}" \
    --enable-charts "#{node[:magento][:enable_charts]}" \
    --admin_firstname "#{node[:magento][:admin_user][:firstname]}" \
    --admin_lastname "#{node[:magento][:admin_user][:lastname]}" \
    --admin_email "#{node[:magento][:admin_user][:email]}" \
    --admin_username "#{node[:magento][:admin_user][:username]}" \
    --admin_password "#{node[:magento][:admin_user][:password]}" \
    --encryption_key "#{node[:magento][:encryption_key]}" \
    --skip_url_validation
    EOH
  end

  # Configuration for PageCache module to be enabled
  execute "pagecache-database-inserts" do
    command "/usr/bin/mysql #{node[:magento][:db][:database]} -u #{node[:magento][:db][:username]} -h #{node[:mysql][:bind_address]} -P #{node[:mysql][:port]} -p#{node[:magento][:db][:password]} < /root/pagecache_inserts.sql"
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
