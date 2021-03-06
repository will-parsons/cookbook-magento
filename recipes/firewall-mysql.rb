#
# Cookbook Name:: magento
# Recipe:: firewall-mysql
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
  fwfile = "/etc/sysconfig/iptables"
  %w{ node[:mysql][:port] }.each do |port|
    rule = "-I INPUT -p tcp -m tcp --dport #{port} -j ACCEPT"
    execute "Adding iptables rule for #{port}" do
      command "iptables #{rule}"
      not_if "grep \"\\#{rule}\" #{fwfile}"
    end
  end
  # Save iptables rules
  execute "Saving iptables rule set" do
    command "/sbin/service iptables save"
  end
else
  include_recipe "firewall"

  firewall_rule "mysql" do
    port node[:mysql][:port]
    protocol :tcp
    interface node[:mysql][:interface]
    action :allow
  end
end
