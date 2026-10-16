require 'rho/rhocontact'
require 'CommonModules/mobisysbrowserhelper'
 
module MobiSys
  module Contacts
    
    def self.delete(contactId)
      Rho::RhoContact.destroy(contactId)
    end  
    
    def self.create(properties)
      raise ArgumentError.new("company_name property is not supported") if properties.has_key?("company_name")
      contact = Rho::RhoContact.create!(properties)
      contacts = Rho::RhoContact.find(:all, :select=>properties.keys)
      contacts.each do |storedContact|
        match = true
        properties.each do |key,value|
          next if value == ''
          next if key=="company_name"
          match = false unless storedContact[1][key] == value
        end
        contact = storedContact if match
      end 
      if contact
        return contact[1]
      else
        raise MobiSys::ContactsAccessError.new("Cannot Access Contacts")
      end
    end
    
    def self.update(contactId, properties)
      raise ArgumentError.new("contactId cannot be null") unless contactId
      raise ArgumentError.new("Please provide properties to be updated") unless properties and properties.length > 0
      params = Hash.new
      params["id"] = contactId
      properties.each do |key, value|
        params[key] = value 
      end
      Rho::RhoContact.update_attributes(params)
      return findById(contactId)
    end
    
    def self.findById(id, properties=["id","display_name","first_name","last_name","mobile_number","business_number","home_number","email_address"])
      if properties
        raise ArgumentError.new("properties should be of type Array") unless properties.is_a? Array
      end
      raise ArgumentError.new("id parameter is mandatory") unless id
      returnValue = nil
      
      if properties and System::get_property('platform') == 'ANDROID'
        if properties.length > 0
          unless properties.index("id") >= 0
            properties.push "id"
          end  
        end  
        contacts = Rho::RhoContact.find(:all, :select=>properties)
      else
        contacts = Rho::RhoContact.find(:all)
      end
      if contacts
        contacts.each do |contact|
          next unless contact[1]["id"] == id
          returnValue = contact
          break
        end
        return returnValue
      else
        raise MobiSys::ContactsAccessError.new("Cannot Access Contacts")
      end
    end
    
    def self.findByFirstName(firstName, properties=["id","display_name","first_name","last_name","mobile_number","business_number","home_number","email_address"])
      if properties
        raise ArgumentError.new("properties should be of type Array") unless properties.is_a? Array
      end
      raise ArgumentError.new("firstname parameter is mandatory") unless firstName
      returnValue = Array.new
      
      if properties and System::get_property('platform') == 'ANDROID'
        if properties.length > 0
          unless properties.index("first_name") >= 0
            properties.push "first_name"
          end  
        end  
        contacts = Rho::RhoContact.find(:all, :select=>properties)
      else
        contacts = Rho::RhoContact.find(:all)
      end
      if contacts
        contacts.each do |contact|
          next unless contact[1]["first_name"] == firstName
          returnValue.push contact
        end
        return returnValue
      else
        raise MobiSys::ContactsAccessError.new("Cannot Access Contacts")
      end
    end
    
    def self.findByLastName(lastName, properties=["id","display_name","first_name","last_name","mobile_number","business_number","home_number","email_address"])
      if properties
        raise ArgumentError.new("properties should be of type Array") unless properties.is_a? Array
      end
      raise ArgumentError.new("lastName parameter is mandatory") unless lastName
      returnValue = Array.new
      
      if properties and System::get_property('platform') == 'ANDROID'
        if properties.length > 0
          unless properties.index("last_name") >= 0
            properties.push "last_name"
          end  
        end  
        contacts = Rho::RhoContact.find(:all, :select=>properties)
      else
        contacts = Rho::RhoContact.find(:all)
      end
      if contacts
        contacts.each do |contact|
          next unless contact[1]["last_name"] == lastName
          returnValue.push contact
        end
        return returnValue
      else
        raise MobiSys::ContactsAccessError.new("Cannot Access Contacts")
      end
    end
    
    def self.findByMobileNumber(mobileNumber, properties=["id","display_name","first_name","last_name","mobile_number","business_number","home_number","email_address"])
      if properties
        raise ArgumentError.new("properties should be of type Array") unless properties.is_a? Array
      end
      raise ArgumentError.new("mobileNumber parameter is mandatory") unless mobileNumber
      returnValue = Array.new
      
      if properties and System::get_property('platform') == 'ANDROID'
        if properties.length > 0
          unless properties.index("mobile_number") >= 0
            properties.push "first_name"
          end  
        end  
        contacts = Rho::RhoContact.find(:all, :select=>properties)
      else
        contacts = Rho::RhoContact.find(:all)
      end
      if contacts
        contacts.each do |contact|
          next unless contact[1]["mobile_number"] == mobileNumber
          returnValue.push contact
        end
        return returnValue
      else
        raise MobiSys::ContactsAccessError.new("Cannot Access Contacts")
      end
    end
    
    def self.findByEmail(email, properties=["id","display_name","first_name","last_name","mobile_number","business_number","home_number","email_address"])
      if properties
        raise ArgumentError.new("properties should be of type Array") unless properties.is_a? Array
      end
      raise ArgumentError.new("firstname parameter is mandatory") unless email
      returnValue = Array.new
      
      if properties and System::get_property('platform') == 'ANDROID'
        if properties.length > 0
          unless properties.index("email_address") >= 0
            properties.push "email_address"
          end  
        end  
        contacts = Rho::RhoContact.find(:all, :select=>properties)
      else
        contacts = Rho::RhoContact.find(:all)
      end
      if contacts
        contacts.each do |contact|
          next unless contact[1]["email_address"] == email
          returnValue.push contact
        end
        return returnValue
      else
        raise MobiSys::ContactsAccessError.new("Cannot Access Contacts")
      end
    end
    

    
  end
  class ContactsAccessError < StandardError
  
  end
end