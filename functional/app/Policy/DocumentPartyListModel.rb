require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysuihelper_jazz'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
    
    class DocumentPartyListModel < BaseModel

        def initialize(io)
            #puts "~~~in DocumentPartyListModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

        def getModel
            documentPartyList = []
            $currentProduct ||= ProductUtil.getProduct(@baseIO.baseDO.baseProductSeq)
            partyList = self.parentBaseDO.getPartyNames('tab_requirement')
            partyList.each do |party|
                partyInfo = party[1].split("-")
                partyContainer = PolicyPartyContainer.new
                partyContainer.partyGuid = party[0]
                partyContainer.partyRole = partyInfo[0]
                partyContainer.partyName = partyInfo[1]
                partyContainer.status = ""
                documentPartyList << partyContainer
            end
            addtnlLookup = {}
            @baseIO.additionalData = {} if (@baseIO != nil && (@baseIO.additionalData == nil || (@baseIO.additionalData != nil and !@baseIO.additionalData.is_a?(Hash))))
            addtnlLookup["FILEDATATYPE"] = []
           
            if ((@baseIO.additionalData.has_key?("ADDTNL_LOOKUPS") and @baseIO.additionalData["ADDTNL_LOOKUPS"] == nil) || @baseIO.additionalData.empty? || (!@baseIO.additionalData.empty? and !@baseIO.additionalData.has_key?("ADDTNL_LOOKUPS")))
                @baseIO.additionalData["ADDTNL_LOOKUPS"] = []
            end
            @baseIO.additionalData["ADDTNL_LOOKUPS"].push(addtnlLookup) if @baseIO.additionalData["ADDTNL_LOOKUPS"].select{|lookups| lookups if lookups.has_key?("FILEDATATYPE")}.size == 0
            
            return documentPartyList
        end

    end
end

begin 
    require 'Policy/DocumentPartyListModel_company'
rescue LoadError => e
    puts 'DocumentPartyListModel_company not included'
end