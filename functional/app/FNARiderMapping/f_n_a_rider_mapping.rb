require "CommonModules/schema_module"

class FNARiderMapping
    include MobiSys::MobiSysFixedSchema
  
    set :schema_version, '1.0'
    set :partition, :master
        
    # Uncomment the following line to enable sync with FNARiderMapping.
    # enable :sync
  
    #add model specifc code here
    property :fnaProductSeq, :integer
    property :fnaBaseProductSeq, :integer
    property :effectiveFromDt, :date
    property :effectiveToDt, :date
    property :fnaParentProductSeq, :integer
    
    # derived attributes  
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    property :removed, :String
    
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNARiderMappingDO"
    end
    
    def self.entitiesForSync
    end
    
    def afterSync
      # puts "After sync called for FNARiderMapping"   
    end 
end

begin
    require 'FNARiderMapping/f_n_a_rider_mapping_m_company'
rescue LoadError => e
    puts 'f_n_a_rider_mapping_m_company not included'
end