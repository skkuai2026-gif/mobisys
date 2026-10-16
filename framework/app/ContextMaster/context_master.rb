# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'

class ContextMaster
  include MobiSys::MobiSysFixedSchema

  # Uncomment the following line to enable sync with Contet.
  # enable :sync
  set :schema_version, '1.0'
  set :partition, :master

  property :className, :string
  property :fieldName, :string
  property :contextNameExpression, :string
  property :expressionTypeCd, :string

  # derived attributes
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  #add model specific code here

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.ContextMasterDO"
  end

  def afterSync
    puts "+++After sync called for modelcd #{self.className}.#{self.fieldName}"
    objectClass = self.className.gsub("DO","")
    attribute = self.fieldName
   
    #Check if Do exists in offline else delete record
    if Rho::RhoConfig.sources.has_key?(objectClass)
      if Rho::RhoConfig.sources[objectClass]["schema"]["property"].has_key?(attribute)
        dataType = Rho::RhoConfig.sources[objectClass]["schema"]["property"][attribute][0].to_s
        if dataType == "float"
          self.contextNameExpression.to_s.gsub!("#{attribute} ","#{attribute}.to_f ")
        elsif dataType == "integer" 
          self.contextNameExpression.to_s.gsub!("#{attribute} ","#{attribute}.to_i ")
        else
          self.contextNameExpression.to_s.gsub!("#{attribute} ","#{attribute}.to_s ")
        end

        #Context Master expressions for nil do not work with data type conversion so need to remove them for nil check
        #to_f
        self.contextNameExpression.to_s.gsub!("#{attribute}.to_f ==null","#{attribute} == nil")
        self.contextNameExpression.to_s.gsub!("#{attribute}.to_f == null","#{attribute} == nil")
        self.contextNameExpression.to_s.gsub!("#{attribute}.to_f !=null","#{attribute} != nil")
        self.contextNameExpression.to_s.gsub!("#{attribute}.to_f != null","#{attribute} != nil")

        #to_i
        self.contextNameExpression.to_s.gsub!("#{attribute}.to_i ==null","#{attribute} == nil")
        self.contextNameExpression.to_s.gsub!("#{attribute}.to_i == null","#{attribute} == nil")
        self.contextNameExpression.to_s.gsub!("#{attribute}.to_i !=null","#{attribute} != nil")
        self.contextNameExpression.to_s.gsub!("#{attribute}.to_i != null","#{attribute} != nil")

        #to_s
        self.contextNameExpression.to_s.gsub!("#{attribute}.to_s ==null","#{attribute} == nil")
        self.contextNameExpression.to_s.gsub!("#{attribute}.to_s == null","#{attribute} == nil")
        self.contextNameExpression.to_s.gsub!("#{attribute}.to_s !=null","#{attribute} != nil")
        self.contextNameExpression.to_s.gsub!("#{attribute}.to_s != null","#{attribute} != nil")
      end
      #check if null keyword is present then replace it with nil
      self.contextNameExpression.to_s.gsub!("null","nil")


      self.persist('fromSync')
    else
      self.destroy
    end
  end
end
