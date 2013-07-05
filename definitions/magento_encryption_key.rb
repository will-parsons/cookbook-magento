define :magento_encryption_key do

  require 'securerandom'

  # Mimic random encryption key generation that Magento does
  node.set[:magento][:encryption_key] = SecureRandom.uuid.gsub('-', '')

  # save node data to prevent loss of encryption key and customer saved data
  unless Chef::Config[:solo]
    ruby_block "save node data" do
      block do
        node.save
      end
      action :create
    end
  end

end
