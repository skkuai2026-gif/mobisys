require "CommonModules/schema_module"

class FNASIProductLink
    include MobiSys::MobiSysFixedSchema
  
    set :schema_version, '1.0'
    set :partition, :master
        
    # Uncomment the following line to enable sync with FNASIProductLink.
    # enable :sync
  
    #add model specifc code here
    property :fnaSiProductLinkSeq, :integer
    property :fnaProductId, :string
    property :siProductId, :string
    property :optionCd, :string
    property :configuredAs, :string
    property :versionID,:integer

    # derived attributes
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    property :removed, :String
    
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNASIProductLinkDO"
    end
    
    def self.entitiesForSync
    end
    
    def afterSync
      # puts "After sync called for FNASIProductLink"   
    end 

end

begin
    require 'FNASIProductLink/f_n_a_s_i_product_link_company'
rescue LoadError => e
    puts 'f_n_a_s_i_product_link_company not included'
end