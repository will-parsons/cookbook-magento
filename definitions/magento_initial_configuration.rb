define :magento_initial_configuration do

  if platform?("debian") 
    execute "Fixing extension bug that can cause Debian installs to fail" do
      command "sed -i 's/\<pdo_mysql\/\>/\<pdo_mysql\>1\<\/pdo_mysql\>/' #{node[:magento][:dir]}/app/code/core/Mage/Install/etc/config.xml"
      action :run
    end
  end

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
end
