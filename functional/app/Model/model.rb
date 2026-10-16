# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'

class Model
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master

    property :modelCd, :string
    property :modelDesc, :string
    property :modelTypeCd, :string

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    has_many 'ModelFund'
    has_many 'ModelSubModel'
    
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.ModelDO"
    end

    def getModelFunds
        modelList = []
        self.ModelFundList.each do| modelFund|
            modelList.push(modelFund)
        end
        modelList
    end

    def getFundByCd(fundCd)
      @fund ||= {}
      @fund[fundCd] ||= ModelFund.find(:first, :conditions=> {
        {:name => 'parentKey'} => object,
        {:name => 'fundCd'} => fundCd 
      }, :opt=>'AND')
    end


  # Uncomment the following line to enable sync with Model.
  # enable :sync

  #add model specifc code here
end
