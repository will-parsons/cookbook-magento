#
# Cookbook Name:: magento
# Recipe:: memcached-client
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node[:platform]
when "ubuntu", "debian"
  package "php5-memcache" do
    action :install
    notifies :restart, "service[php-fpm]"
  end
when "centos", "fedora"
  package "php-pecl-memcache" do
    action :install
    notifies :restart, "service[php-fpm]"
  end
end

####### Magento local.xml Configuration to use Memcached Instances #####

node.set_unless[:magento][:session][:save_path] = "tcp://#{node[:magento][:memcached][:servers][:sessions][:servers]}:#{node[:magento][:memcached][:servers][:sessions][:server_port]}?persistent=0&amp;weight=2&amp;timeout=10&amp;retry_interval=10"

template "#{node[:magento][:dir]}/app/etc/local.xml" do
  source "local.xml.erb"
  mode "0600"
  owner "#{node[:magento][:system_user]}"
  variables(
    :db_host => node[:mysql][:bind_address],
    :db_port => node[:mysql][:port],
    :db_name => node[:magento][:db][:database],
    :db_prefix => node[:magento][:db][:prefix],
    :db_user => node[:magento][:db][:username],
    :db_pass => node[:magento][:db][:password],
    :db_init => node[:magento][:db][:initStatements],
    :db_model => node[:magento][:db][:model],
    :db_type => node[:magento][:db][:type],
    :db_pdo => node[:magento][:db][:pdoType],
    :db_active => node[:magento][:db][:active],
    :enc_key => node[:magento][:encryption_key],
    :session => node[:magento][:session],
    :admin_path => node[:magento][:admin_frontname],
    :cache_info => node[:magento][:memcached][:servers][:slow_backend],
    :inst_date => Time.new.rfc2822()
  )
end
