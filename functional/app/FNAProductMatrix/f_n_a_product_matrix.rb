require "CommonModules/schema_module"

class FNAProductMatrix
    include MobiSys::MobiSysFixedSchema
  
    set :schema_version, '1.0'
    set :partition, :master
        
    # Uncomment the following line to enable sync with FNAProductMatrix.
    # enable :sync
  
    #add model specifc code here
    property :fnaProductSeq, :string
    property :fnaQuestionCd, :string
    property :fnaQuestionLookupDataCd, :string
    property :productTypeCd, :string
    property :ppt, :string

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
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNAProductMatrixDO"
    end
    
    def self.entitiesForSync
    end
    
    def afterSync
      # puts "After sync called for FNAProductMatrix"   
    end 
end

begin
    require 'FNAProductMatrix/f_n_a_product_matrix_company'
rescue LoadError => e
    puts 'f_n_a_product_matrix_company not included'
end