require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class LeadPartyModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			lead = self.parentBaseDO
			leadParty = lead.getLeadParty
			if leadParty == nil
				leadParty = Party.new(:roleCd => "LEAD", :partyTypeCd => "INDIVIDUAL")
				lead.partyRefGuid = leadParty.uniqueKey
				lead.addParty(leadParty)
			end

			addtnlLookup = {}
            @baseIO.additionalData = {} if (@baseIO != nil && (@baseIO.additionalData == nil || (@baseIO.additionalData != nil and !@baseIO.additionalData.is_a?(Hash))))
            addtnlLookup["FILEDATATYPE"] = []
           
            if ((@baseIO.additionalData.has_key?("ADDTNL_LOOKUPS") and @baseIO.additionalData["ADDTNL_LOOKUPS"] == nil) || @baseIO.additionalData.empty? || (!@baseIO.additionalData.empty? and !@baseIO.additionalData.has_key?("ADDTNL_LOOKUPS")))
                @baseIO.additionalData["ADDTNL_LOOKUPS"] = []
            end
            @baseIO.additionalData["ADDTNL_LOOKUPS"].push(addtnlLookup) if @baseIO.additionalData["ADDTNL_LOOKUPS"].select{|lookups| lookups if lookups.has_key?("FILEDATATYPE")}.size == 0

			return leadParty
		end

		def setModel(entity)
			if entity
				entity.status = ""
				self.parentBaseDO.partyRefGuid = entity.guid
			end

			return entity
		end
	end
	
end

begin 
    require 'Lead/LeadPartyModel_company'
rescue LoadError => e
    puts 'LeadPartyModel_company not included'
end