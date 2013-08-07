#
# Cookbook Name:: magento
# Recipe:: varnish
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

case node["platform_family"]
when "rhel", "fedora"
  # CentOS installs v2.1 by default, installing 3.0
  execute 'reload-external-yum-cache' do
    command 'yum makecache'
    action :nothing
  end
 
  ruby_block "reload-internal-yum-cache" do
    block do
      Chef::Provider::Package::Yum::YumCache.instance.reload
    end
    action :nothing
  end

  execute "Install varnish-release" do
    not_if "rpm -qa | grep -qx 'varnish-release-3.0-1'"
    command "rpm -Uvh --nosignature --replacepkgs http://repo.varnish-cache.org/redhat/varnish-3.0/el5/noarch/varnish-release-3.0-1.noarch.rpm"
    action :run
    notifies :run, resources(:execute => 'reload-external-yum-cache'), :immediately
    notifies :create, resources(:ruby_block => 'reload-internal-yum-cache'), :immediately
  end

  package "varnish" do
    action :install
  end
  
  service "varnish" do
    action [:enable, :start]
  end
  
  template "/etc/sysconfig/varnish" do
    source "varnish.erb"
    owner "root"
    group "root"
    mode "0644"
    notifies :restart, "service[varnish]"
  end


else
  include_recipe "varnish"
  
  service "varnish" do
    action [:enable, :start]
  end

  template "/etc/default/varnish" do
    source "varnish.erb"
    owner "root"
    group "root"
    mode "0644"
    notifies :restart, "service[varnish]"
  end

end

# Setup Mage and install default Varnish template
magento_mage
