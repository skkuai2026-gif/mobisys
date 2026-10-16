require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class LeadRPQModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			leadRPQDO = self.baseIO.leadRPQDO
			if leadRPQDO == nil 
				leadRPQDO = LeadRPQ.new
				leadRPQDO.rpqId = SequenceNoGenerator.getNextNumber('RPQID')
				leadRPQDO.rpqScore = ""
				self.baseIO.leadRPQDO = leadRPQDO
			end
			return leadRPQDO
		end

		def setModel(entity)
			self.baseIO.leadRPQDO = entity
			if entity.otherTitle.to_s == ""
				self.baseIO.leadRPQDO.otherTitle = nil
		    end	
		    if entity.closureNotes.to_s == ""
			   self.baseIO.leadRPQDO.closureNotes = nil
		    end
	        return self.baseIO.leadRPQDO
		end

	end
	
end

begin 
    require 'FNARequest/FNAPartyModel_company'
rescue LoadError => e
    puts 'FNAPartyModel_company not included'
end