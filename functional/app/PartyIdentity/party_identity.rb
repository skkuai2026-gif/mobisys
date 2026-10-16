# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

# You can add more methods here
class PartyIdentity
  include MobiSys::MobiSysEntitySchema
     
       set :schema_version, '1.0'
           
       # Uncomment the following line to enable sync with Label.
       # enable :sync
     
       #add model specifc code here
       property :identityNum, :string
       property :expiryDt, :date
       property :identityTypeCd, :string
       property :idStatus, :string
       property :issueDt, :date
       property :issuingAuthority, :string
       property :primaryFl, :string
       property :creditCardNum, :string

       property :identityField1, :string
       property :identityField2, :string
       property :identityField3, :string
       property :identityField4, :string
       property :identityField5, :string
  
       # derived attributes  
       property :userId, :string
       property :parentKey, :string
       property :versionID, :integer
       property :id, :integer
       property :guid, :string
       property :systemCreatedDt, :time
       property :systemUpdatedDt, :time
       property :removed, :string


	attr_accessor :entityDesc

	def getEntityDesc
    party = Party.loadObject(:first, :conditions => {:object => (self.parentKey).to_s}, :loadChild => false)
    if party and self.entityDesc.to_s == ""
      ofLabel = LabelValue.getLabel("of",Application.getValue('DEFAULTLOCALE').value)
      spaceLabel = LabelValue.getLabel("SPACE",Application.getValue('DEFAULTLOCALE').value)
      #self.entityDesc = ""
      #Adding Identity type in entityDesc for better understanding.
      self.entityDesc = Lookupvalue.getLookupValue("IDENTITYTYPE",self.identityTypeCd.to_s) + spaceLabel + ofLabel + spaceLabel if self.identityTypeCd.to_s != ""
      self.entityDesc  = self.entityDesc.to_s + party.getEntityDesc
    end
    
    return self.entityDesc
	end
      
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyIdentityDO"
  end
   
  def self.entitiesForSync
     
  end
   
  def afterSync
    puts "After sync called for party identity " + self.identityNum.to_s   
  end 
end

begin 
    require 'PartyIdentity/party_identity_company'
rescue LoadError => e
    puts 'party_identity_company not included'
end