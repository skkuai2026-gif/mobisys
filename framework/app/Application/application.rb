# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class Application
  include Rhom::FixedSchema
  # Uncomment the following line to enable sync with Application.
  # enable :sync

  #add model specifc code here
  set :schema_version, '69.6'
  # set :schema_version, '1.2'

  property :key, :string
  property :value, :string
  
  def self.create(key,value)
    applicationObject = Application.getValue(key)
    if applicationObject
      raise MobiSys::ApplicationKeyDuplicateError.new("An application object already exists with key #{key}")
    else
      app = Application.new
      app.key = key
      app.value = value
      app.save
      return app  
    end
  end
  
  def self.getValue(key)
    applicationObject = Application.find(:first, :conditions=>{'key'=>key})
    return applicationObject
    if applicationObject
      return applicationObject
    else
      #raise MobiSys::ApplicationKeyDoesNotExistError.new("No application object found with key #{key}")
      return nil  
    end  
  end
  
  def self.remove(key)
    applicationObject = Application.find(:first, :conditions=>{'key'=>key})
    value = applicationObject.value
    applicationObject.destroy
    return value
  end

  def self.updateValue(key,value)
    applicationObject = Application.find(:first, :conditions=>{'key'=>key})
    if applicationObject
      applicationObject.value = value
      applicationObject.save
    else
      raise MobiSys::ApplicationKeyDoesNotExistError.new("No application object found with key #{key}")  
    end  
  end
end

begin 
  require 'Application/application_company'
rescue LoadError => e
  puts 'application_company not included'
end