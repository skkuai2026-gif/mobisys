require 'openssl'
require 'base64'
# require 'zlib'

module MobiSys
  module Encryption
    
    def self.digest(str)
      require 'digest/md5' 
      Digest::MD5.hexdigest(str)[0...16]
      #Digest::SHA256.hexdigest(str)[0...16]
    end
    
    #########################################################################################################
    
    def self.encryptContent(content, key=nil)
      return encryptAndEncodeContent(content,key)
    end
    
    #########################################################################################################
        
    def self.encryptAndEncodeContent(content, key=nil)
      encodedContent = nil
      content = content.to_s
      if content and content.length > 0
        cipher = OpenSSL::Cipher.new('aes-128-cbc')
        aes_key = digest Application.getValue(MobiSys::MOBISYSDEVICEID).value unless key
        aes_key = digest key if key
        aes_iv = cipher.random_iv
         
        # prepare cipher
        cipher.encrypt
        cipher.key = aes_key
        cipher.iv = aes_iv
        
        encryptedContent = ""
        if content != nil
          encryptedContent = cipher.update(content) << cipher.final
        end
        encodedContent = Base64.strict_encode64(encryptedContent) + "|" + Base64.strict_encode64(aes_iv)
      end  
      return encodedContent
    end
    
    #########################################################################################################
          
    def self.decryptAndDecodeContent(content, key=nil)
      return content if (content == nil or content == "")
      decryptedContent = nil
      cipher = OpenSSL::Cipher.new('aes-128-cbc')
      aes_key = digest Application.getValue(MobiSys::MOBISYSDEVICEID).value unless key
      aes_key = digest key if key
      parts = content.rpartition('|')
      encodedData = parts[0]
      encodedIV = parts[2]
      
      aes_iv = Base64.strict_decode64(encodedIV)
      encryptedData = Base64.strict_decode64(encodedData)
      
      # prepare cipher
      cipher.decrypt
      cipher.key = aes_key
      cipher.iv = aes_iv
      
      decryptedContent = cipher.update(encryptedData) << cipher.final
      return decryptedContent
    end
  
    #########################################################################################################
    
    def self.decryptContent(encryptedContent, key=nil)
      return decryptAndDecodeContent(encryptedContent,key)
    end
    
    #########################################################################################################
    
    def self.decryptFile(fileName,aesIVBase64)
      encodedContent = File.open(fileName + "_enc","r").read
      encyptedBytes = Base64.strict_decode64(encodedContent)
      
      
      cipher = OpenSSL::Cipher.new('aes-128-cbc')
      aes_key = digest Application.getValue(MobiSys::MOBISYSDEVICEID).value
      aes_iv = Base64.strict_decode64(aesIVBase64)
      
      # prepare cipher
      cipher.decrypt
      cipher.key = aes_key
      cipher.iv = aes_iv
      bytes = cipher.update(encyptedBytes) << cipher.final
      File.open(fileName, "wb") do |outf|
        outf << bytes
      end  
    end  
    
    #########################################################################################################
    
    def self.encryptFile(fileName,deleteOriginalFile)
      encodedContent = encryptFileContents(fileName)
      fileContent = encodedContent.values[0]
      File.open(fileName + "_enc","w") do |outf|
        outf << fileContent
      end
      aesIVBase64 = encodedContent.keys[0]
      File.delete fileName if deleteOriginalFile
      puts "AES IV         : #{aesIVBase64}"
      return encodedContent
    end
    
    #########################################################################################################
    
    def self.encryptFileContents(fileName)
      cipher = OpenSSL::Cipher.new('aes-128-cbc')
      aes_key = digest Application.getValue(MobiSys::MOBISYSDEVICEID).value
      aes_iv = cipher.random_iv
       
      # prepare cipher
      cipher.encrypt
      cipher.key = aes_key
      cipher.iv = aes_iv
      
      file = File.open(fileName, 'rb')
      bytes = file.read
      content = cipher.update(bytes) << cipher.final
      encodedContent = Base64.strict_encode64(content)
      aesIVBase64 = Base64.strict_encode64(aes_iv)
      returnHash = Hash.new
      returnHash[aesIVBase64] = encodedContent
      file.close()
      return returnHash
    end

    #########################################################################################################
    
    def self.encodeFileContents(fileName)
      file = File.open(fileName, 'rb')
      bytes = file.read
      encodedContent = Base64.strict_encode64(bytes)
      file.close()
      return encodedContent
    end

    def self.zipData(string)
      return Zlib::Deflate.deflate(string)
    end

    def self.unZipData(string)
      return Zlib::Inflate.inflate(string)
    end

    def self.decodeContents(content)
      return Base64.strict_decode64(content)
    end
    
    def self.encodeContents(bytes)
      return Base64.strict_encode64(bytes)
    end

  end

end