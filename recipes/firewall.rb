#
# Cookbook Name:: magento
# Recipe:: firewall
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
  include_recipe "iptables"

  iptables_rule "http"
  iptables_rule "https"

else
  include_recipe "firewall"

  firewall_rule "http" do
    port node['magento']['firewall']['http']
    protocol :tcp
    interface node['magento']['firewall']['interface']
    action :allow
  end

  firewall_rule "https" do
    port node['magento']['firewall']['https']
    protocol :tcp
    interface node['magento']['firewall']['interface']
    action :allow
  end
end
