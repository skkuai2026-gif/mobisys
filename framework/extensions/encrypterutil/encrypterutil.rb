module EncrypterUtil

class EncrypterUtilStringHelper

  def self.encrypt(str)      
    return EncrypterUtil::native_encrypt(str) 
  end 

  def self.decrypt(str)
    return EncrypterUtil::native_decrypt(str)
  end 
    
end


end

