# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class OutputPreferences
  include MobiSys::MobiSysEntitySchema
  
  set :schema_version, '1.0'
  # Uncomment the following line to enable sync with OutputPreferences.
  # enable :sync

    #add model specific code here
    property :languageCd, :string
    property :field1, :string
    property :field2, :string
    property :field3, :string
    property :field4, :string
    property :field5, :string
    property :field6, :string
    property :field7, :string
  
    # derived attributes  
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    property :removed, :string
    
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.OutputPreferencesDO"
    end
end

begin 
    require 'OutputPreferences/output_preferences_company'
rescue LoadError => e
    puts 'output_preferences_company not included'
end