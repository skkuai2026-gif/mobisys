#encoding: UTF-8
require "CommonModules/schema_module"

class LabelValue
    include MobiSys::MobiSysFixedSchema
  
    set :schema_version, '1.0'
    set :partition, :master
  
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specifc code here
    
    property :key, :string
    property :value, :string
    property :lang, :string
    property :toolTipValue, :string
    property :labelValueExtra, :string
    
    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.OfflineLabelDO"
    end
  
    def afterSync
      defaultLanguage = Application.getValue('DEFAULTLOCALE')
      if defaultLanguage != nil && self.lang.to_s == defaultLanguage.value.to_s
        Localization::LabelCache.instance.updateLabel(self.key.to_sym, self.value)
      end      
    end

    def self.getLabel(labelCd, lang)
      labelValue = ""
      if lang.is_a?(Application)
        lang = lang.value.to_s
      end
      label = LabelValue.find( :first, :conditions => {{ :name => 'key'} => labelCd, {:name => 'lang'} => lang}, :op => 'AND')
      labelValue = label && label.value ? label.value : labelCd
      if labelCd.to_s.include?("MINMAX") || labelCd.to_s.include?("ERR_MAX") ||labelCd.to_s.include?("ERR_MIN")
        if labelValue.to_s == labelCd.to_s
          labelValue = ""
        end
      end
      return labelValue.to_s.force_encoding("UTF-8")
    end
end