# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PartyOtherIncome
      include MobiSys::MobiSysEntitySchema
    
      set :schema_version, '1.0'
          
      # Uncomment the following line to enable sync with Label.
      # enable :sync
    
      #add model specifc code here
      property :incomeTypeCd, :string
      property :sourceOfIncome, :string
      property :incomeAmount, :double, :decimal
      property :otherSourceIncome, :string
      property :currencyCd, :string
      property :incomeYear, :string
  
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
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyOtherIncomeDO"
      end
      
      def self.entitiesForSync
      end
      
      def afterSync
        puts "After sync called for party Other Income      "     
      end 
end

begin 
    require 'PartyOtherIncome/party_other_income_company'
rescue LoadError => e
    puts 'party_other_income_company not included'
end
