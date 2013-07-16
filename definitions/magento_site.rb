define :magento_site do

  include_recipe "nginx"

  ssl_admin = (node[:magento][:ssl].nil? or node[:magento][:ssl][:private_key].nil? or
               node[:magento][:ssl][:private_key].empty? or node[:magento][:ssl][:cert].nil? or
               node[:magento][:ssl][:cert].empty?) ? false : true rescue false

  # Begin SSL configuration
  directory "#{node[:nginx][:dir]}/ssl" do
    owner "root"
    group "root"
    mode "0755"
    action :create
  end

  if node[:magento][:hostname]
    sitedomain = node[:magento][:hostname]
  else
    sitedomain = "magento"
  end

  if ssl_admin # Install certs if provided
    file "#{node[:nginx][:dir]}/ssl/#{sitedomain}.key" do
      content node[:magento][:ssl][:private_key]
      owner "root"
      group "root"
      mode "0600"
      action :create_if_missing
    end
    if defined?(node[:magento][:ssl][:ca]) 
      file "#{node[:nginx][:dir]}/ssl/#{sitedomain}.ca" do
        content node[:magento][:ssl][:ca]
        owner "root"
        group "root"
        mode "0644"
        action :create_if_missing
      end
      certpath = "#{node[:nginx][:dir]}/ssl/#{sitedomain}.certificate"
    else
      certpath = "#{node[:nginx][:dir]}/ssl/#{sitedomain}.crt"
    end
    file "#{certpath}" do
      content node[:magento][:ssl][:cert]
      owner "root"
      group "root"
      mode "0644"
      action :create_if_missing
    end

    if !File.exists?("#{node[:nginx][:dir]}/ssl/#{sitedomain}.crt") || File.zero?("#{node[:nginx][:dir]}/ssl/#{sitedomain}.crt") 
      bash "Combine Certificate and Intermediate Certificates" do
        cwd "#{node[:nginx][:dir]}/ssl"
        code "cat #{sitedomain}.certificate #{sitedomain}.ca > #{sitedomain}.crt"
        only_if { File.zero?("#{node[:nginx][:dir]}/ssl/#{sitedomain}.crt") }
        action :nothing
      end
      cookbook_file "#{node[:nginx][:dir]}/ssl/#{sitedomain}.crt" do
        source "blank"
        mode 0644
        owner "root"
        group "root"
        action :create_if_missing
        notifies :run, resources(:bash => "Combine Certificate and Intermediate Certificates"), :immediately
      end
    end

  else # Create and install a self-signed cert if no certs provided and secure perms on generated key
    bash "Create Self-Signed SSL Certificate" do
      cwd "#{node[:nginx][:dir]}/ssl"
      code <<-EOH
      openssl req -x509 -nodes -days 730 \
        -subj '/CN='#{sitedomain}'/O=Magento/C=US/ST=Texas/L=San Antonio' \
        -newkey rsa:2048 -keyout #{sitedomain}.key -out #{sitedomain}.crt
      chmod 600 #{node[:nginx][:dir]}/ssl/#{sitedomain}.key
      EOH
      only_if { File.zero?("#{node[:nginx][:dir]}/ssl/#{sitedomain}.crt") }
      action :nothing
    end

    cookbook_file "#{node[:nginx][:dir]}/ssl/#{sitedomain}.crt" do
      source "blank"
      mode 0644
      owner "root"
      group "root"
      action :create_if_missing
    end
    
    cookbook_file "#{node[:nginx][:dir]}/ssl/#{sitedomain}.key" do
      source "blank"
      mode 0600
      owner "root"
      group "root"
      action :create_if_missing
      notifies :run, resources(:bash => "Create Self-Signed SSL Certificate"), :immediately
    end
  end

  %w{backend}.each do |file|
    cookbook_file "#{node[:nginx][:dir]}/conf.d/#{file}.conf" do
      source "nginx/#{file}.conf"
      mode 0644
      owner "root"
      group "root"
    end
  end

  bash "Drop default site" do
    cwd "#{node[:nginx][:dir]}"
    code <<-EOH
    rm -rf conf.d/default.conf
    EOH
    notifies :reload, resources(:service => "nginx")
  end

  %w{default ssl}.each do |site|
    template "#{node[:nginx][:dir]}/sites-available/#{site}" do
      source "nginx-site.erb"
      owner "root"
      group "root"
      mode 0644
      variables(
        :http => node[:magento][:firewall][:http],
        :https => node[:magento][:firewall][:https],
        :path => "#{node[:magento][:dir]}",
        :ssl => (site == "ssl")?true:false,
        :sitedomain => sitedomain
      )
    end
    nginx_site "#{site}" do
      notifies :reload, resources(:service => "nginx")
    end
  end

end
