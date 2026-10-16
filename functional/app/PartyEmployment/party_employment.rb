# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PartyEmployment
  include MobiSys::MobiSysEntitySchema
    
      set :schema_version, '1.0'
          
      # Uncomment the following line to enable sync with Label.
      # enable :sync
    
      #add model specifc code here
      property :partySeq, :int
      property :occupationCd, :string
      property :otherDetails, :string
      property :natureOfDuty, :string
      property :monthsWithJob, :string
      property :yearsWithJob, :string
      property :industryCd, :string
      property :effectiveToDt, :string
      property :effectiveFromDt, :string
      property :currentEmployerFl, :string
      property :annualIncome, :float, :decimal
      property :annualGrossIncome, :string
      property :jobDescription, :string
      property :employmentStatusCd, :string
      property :employerName, :string
      property :employerAddress, :string
      property :occupationClass, :string 
      property :occupationTypeCd, :string  
      property :grade, :string
      property :pepCd, :string
  
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
        self.entityDesc = MobiSys::BrowserHelper.getLabel(self.occupationTypeCd.to_s)
    end
      
      
      def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyEmploymentDO"
      end
      
      def self.entitiesForSync
      end
      
      def afterSync
        puts "After sync called for party occupation      "
     
      end 

      #Method to indicate that this class is extended for context evaluation.
      def isParentExtendingContext
        return true
      end

      def getOccupationCd
          return self.occupationCd 
      end

      def getIndustryCd
        return self.industryCd
      end
end

begin 
    require 'PartyEmployment/party_employment_company'
rescue LoadError => e
    puts 'party_employment_company not included'
end
