# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class InwardPolicy
  	include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.0'

  	# Uncomment the following line to enable sync with InwardPolicy.
  	# enable :sync

    #add model specific code here
    property :policyNum, :string
    property :acctTypeCd, :string
    property :appAmount, :integer
    property :acctSubTypeCd, :string
    property :removed, :string

    # derived attributes  
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
  
    
	#online-offline sync methods
    def self.onlineClassName
      	return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.collection.InwardPolicyDO"
    end


    def self.entitiesForSync
      	entitiesForSync = InwardPolicy.loadObject(:all)
    end


    def afterSync
      	puts "After sync called for inward policy " + self.policyNum.to_s    
    end
end

begin 
    require 'InwardPolicy/inward_policy_company'
rescue LoadError => e
    puts 'inward_policy_company not included'
end