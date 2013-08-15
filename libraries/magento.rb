class Chef::Recipe::Magento


  # Take a plain text password and hash it Magento style
  def self.hash_password(password, salt)
    require 'rubygems'
    require 'digest/md5'
    require 'securerandom'
    salt = SecureRandom.uuid.gsub('-', '').byteslice(0..1) if !salt || salt.length < 2
    return Digest::MD5.hexdigest(Digest::MD5.digest(salt + password)) + ":#{salt}"
  end


  # Take a value and return a string for use in SQL insert statements
  def self.null_or_value(value)
    return "NULL" if value.empty?
    # Escape any single quotes to encure values returned do not not cause
    # issues with the SQL insert statement
    return "'#{value.gsub("'", "\\\\'")}'"
  end


  # Create magento encryption key mimicing how Magento does it
  def self.magento_encryption_key 
    require 'rubygems'
    require 'securerandom'
    return SecureRandom.uuid.gsub('-', '')
  end

  # Determine if this node is the MySQL server based on IP
  def self.db_is_local?(node)
    return true if node['mysql']['bind_address'] == 'localhost' || node['mysql']['bind_address'] == '127.0.0.1'
    node['network']['interfaces'].each do |iface|
      node['network']['interfaces'][iface[0]]['addresses'].each do |addr|
        return true if addr[0] == node['mysql']['bind_address']
      end
    end
    return false
  end

  # Determine if tables exist for specific database
  def self.tables_exist?(host, username, password, database)
    begin
      require 'rubygems'
      require 'mysql'
      m = Mysql.new(host, username, password, database)
      t = m.list_tables
      return false if t.empty?
      return true
    rescue Exception => e
      return false
    end
  end