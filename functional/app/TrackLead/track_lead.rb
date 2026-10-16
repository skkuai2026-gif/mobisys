# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'
class TrackLead
    include MobiSys::MobiSysEntitySchema
    set :schema_version, '1.0'

    # Uncomment the following line to enable sync with TrackLead.
    # enable :sync
  
    #add model specifc code here
    property :leadId,           :string
    property :fnaId,            :string
    property :quotationRefNum,  :string
    property :productId,        :string 
    property :totAnnualPremium, :float 
    property :proposalNum,      :string  
    property :policyNum,        :string
    property :statusCd,         :string
    property :leadEntryDt,      :date
    property :fnaEntryDt,       :date 
    property :quotationEntryDt, :date 
    property :proposalEntryDt,  :date 
    property :proposalSubmitDt, :date
    property :proposalClosingDt, :date
    property :totPremiumPaid,   :float
    
    # derived attributes  
    property :userId,       :string
    property :parentKey,    :string
    property :versionID,    :integer
    property :id,           :integer
    property :guid,         :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    attr_accessor :proposerName

    def self.onlineClassName
      return "com.c2lbiz.symbiosys.company.dataobjects.TrackLeadDO"
    end
end