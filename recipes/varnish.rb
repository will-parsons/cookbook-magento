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
  # CentOS installs v2.1 by default, installing 3.0 from EPEL
  execute "Install varnish-release" do
    not_if "rpm -qa | grep -qx 'varnish-release-3.0-1'"
    command <<-EOH
    rpm -Uvh --nosignature --replacepkgs http://repo.varnish-cache.org/redhat/varnish-3.0/el5/noarch/varnish-release-3.0-1.noarch.rpm
    EOH
    action :run
  end

  package "varnish" do
    version "3.0.4-1.el5.centos"
    action :install
  end
  service "varnish" do
    action [:enable, :start]
  end
else
  include_recipe "varnish"
end
