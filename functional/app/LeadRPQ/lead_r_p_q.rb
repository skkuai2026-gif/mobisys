# The model has already been created by the framework, and extends Rhom::RhomObject
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

# You can add more methods here
class LeadRPQ
  include MobiSys::MobiSysEntitySchema
  
  set :schema_version, '1.0'

  # Uncomment the following line to enable sync with LeadRPQ.
  # enable :sync

  # add model specific code here
  property :fnaId,        :string
  property :rpqId,        :string
  property :rpqScore,     :integer
  property :expiryDt, :time
  
  property :agentId, :string
  property :agentSignatureCd, :string
  property :agentSignatureDt, :time
  property :signatureCd, :string
  property :signatureDt, :time
  
  #Columns derived from Lead model
  property :leadId,       :string
  property :statusCd,     :string
  property :title,        :string
  property :otherTitle,   :string
  property :firstname,    :string 
  property :middlename,   :string 
  property :lastname,     :string  
  property :alias,        :string
  property :nationality,  :string
  property :language,     :string
  property :dob,          :date
  property :age,          :integer
  property :genderCd,     :string
  property :occupationCd, :string
  property :mobileNumber,    :string
  property :residenceNumber,    :string
  property :officeNumber,    :string
  property :officeExtension,    :string
  property :fromTime,     :time
  property :toTime,       :time
  property :emailAddress, :string
  property :address1,     :string
  property :address2,     :string
  property :address3,     :string
  property :address4,     :string
  property :city,         :string
  property :state,        :string
  property :pincode,      :string
  property :country,      :string
  property :leadUpdatedDt, :string
  property :education,    :string
  property :incomeGroup,  :string
  property :maritalStatus,    :string
  property :leadSource,   :string
  property :leadSourceOther,    :string
  property :leadStatus,   :string
  property :closureNotes, :string
  property :addActivityFlag, :string
  property :activityToBeUpdated, :string
  property :contactId, :string

  #Swati Ahire 29-04-2014: Following to be added as part of Philippines capture lead impl
  property :leadType,        :string
  property :extensionName, :string
  property :natureOfDuty,    :string
  property :occupationClass, :string
  property :companyName, :string
  
  #30-04-2014: Added for contact information
  property :residenceAreaCode,    :string
  property :residenceCountryCode,    :string
  property :mobileAreaCode, :string
  property :mobileCountryCode, :string
  property :officeAreaCode, :string
  property :officeCountryCode, :string
  property :businessTIN, :string
  #End--Lead model
  
  property :visitedTabs, :string

  # derived attributes  
   property :userId,       :string
   property :parentKey,    :string
   property :versionID,    :integer
   property :id,           :integer
   property :guid,         :string
   property :systemCreatedDt, :time
   property :systemUpdatedDt, :time

   has_many 'RPQResponse'

     
  # model specific methods
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.lead.LeadRPQDO"
    end
    
    def afterSync
      puts "After sync called for Lead RPQ " + self.leadId.to_s    
    end
    
    # def self.entitiesForSync
      
    # end
end

begin 
    require 'LeadRPQ/lead_r_p_q_company'
rescue LoadError => e
    puts 'lead_r_p_q_company not included'
end