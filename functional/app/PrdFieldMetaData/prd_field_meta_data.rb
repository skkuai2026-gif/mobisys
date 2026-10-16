require "CommonModules/schema_module"

class PrdFieldMetaData
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master

    #add model specifc code here

    property :prdFieldMetadataSeq, :string
    property :fieldCd, :string
    property :productseq, :integer
    property :propertyCd, :string
    property :propertyValue, :string
    property :errLabelKey, :string
    property :modelCd, :string
    property :outputActionElement, :string
    property :objectName, :string

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

  	def self.onlineClassName
      return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.PrdFieldMetaDataDO"
  	end

  	def afterSync
    	# puts "After sync called UIMetaDataProperty"
  	end

end
