# Take a plain text password and hash it Magento style
def hash_password(password, salt) 
  require 'digest/md5'
  require 'securerandom'

  salt = SecureRandom.uuid.gsub('-', '').byteslice(0..1) if !salt || salt.length < 2
  return Digest::MD5.hexdigest(Digest::MD5.digest(salt + node[:magento][:admin_user][:password])) + ":#{salt}"
end

# Take a value and return a string for use in SQL insert statements
def null_or_value(value)
  return "NULL" if value.empty?
  # Escape any single quotes to encure values returned do not not cause
  # issues with the SQL insert statement
  return "'#{value.gsub("'", "\\\\'")}'"
end

# Create magento encryption key mimicing how Magento does it
def magento_encryption_key 
  require 'securerandom'
  return SecureRandom.uuid.gsub('-', '')
end
