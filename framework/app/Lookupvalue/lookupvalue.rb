require "CommonModules/schema_module"

class Lookupvalue
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master
      
    # Uncomment the following line to enable sync with Lookupvalue.
    # enable :sync
  
    #add model specifc code here
    
    property :key, :string
    property :cd, :string
    property :desc, :string
    property :companyCd, :string
    property :typeCd, :string
    property :valueFrom, :float
    property :valueTo, :float
    property :sortOrder, :integer
	property :additionalField1, :string
    property :additionalField2, :string
    property :defaultFl, :string
    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
    def self.getValue(key)
        lookup_value =  []
        lookup_value = Lookupvalue.find(
            :all, 
            :select => ['key','cd','desc','companyCd', 'typeCd', 'valueFrom', 'valueTo', 'sortOrder', 'additionalField1', 'additionalField2', 'defaultFl'], 
            :conditions=>{'key'=>key})
        return lookup_value
    end

    def self.getDefaultLookupValue(key,lookup_value)
        defaultFl = ''
        lookup_value = getValue(key) if lookup_value == nil
        lookup_value.each do |lookupValue|
            if lookupValue.defaultFl.to_s == 'YES'
                defaultFl = lookupValue.cd
                break
            end
        end
        return defaultFl
    end
    
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.OfflineLookupDO"
    end

    def self.getLookupValue(lookupKey,lookupDataCd)
        lookup_desc = ""
        lookup_val = Lookupvalue.find( :first, :conditions => {{ :name => 'key'} => lookupKey, {:name => 'cd'} => lookupDataCd}, :op => 'AND', :select =>['desc'])
        lookup_desc = lookup_val.desc if lookup_val
        return lookup_desc
    end

    def self.getLookupValueIn(lookupArr)
        lookupList = Lookupvalue.find(
            :all,
            :select => ['key','cd','desc', 'sortOrder', 'additionalField1', 'additionalField2', 'defaultFl'],
            :conditions =>{
                {
                    :name => 'key',
                    :op => 'IN'
                } => lookupArr
            }
        )

        return lookupList
    end

    def self.createLookupCache(lookupArr)
        reqLookupCache = Hash.new
        lookupList = Lookupvalue.getLookupValueIn(lookupArr)
        lookupList.each do |lookup|
            key = lookup.key + lookup.cd
            key = key.to_sym
            reqLookupCache[key] = Hash.new if !reqLookupCache[key].is_a?(Hash)
            reqLookupCache[key] = lookup
        end
        return reqLookupCache
    end

    def getAdditionalField1
        return self.additionalField1
    end

    def getAdditionalField2
        return self.additionalField2
    end
    
end
