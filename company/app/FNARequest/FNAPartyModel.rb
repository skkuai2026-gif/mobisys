require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys

	class FNAPartyModel < BaseModel
		attr_accessor :roleCd
		include MobiSys::BrowserHelper

		def getRoleCd
			return self.roleCd
		end

		def setRoleCd(partyRoleCd)
			if partyRoleCd.to_s == ""
				self.roleCd == partyRoleCd
			end
		end

		def getModel
			fnaRequest = self.parentBaseDO
			fnaParty = fnaRequest.getParty(self.roleCd)
			if fnaParty == nil
				fnaParty = FNAParty.new(:partyRoleCd => self.roleCd)
            	self.parentBaseDO.addFNARequest(fnaParty)
            	# setModel(fnaParty)
			end
			p "fnaParty.FNAQuestionResponseList---getModel---#{fnaParty.FNAQuestionResponseList}"
			return fnaParty
		end

		def setModel(entity)
			p "entity------start--------#{entity}"
			fnaRequest = self.parentBaseDO
			fnaRequest.addFNARequest(entity)
			return entity		
		end
	end	
end

begin 
    require 'FNARequest/FNAPartyModel_company'
rescue LoadError => e
    puts 'FNAPartyModel_company not included'
end