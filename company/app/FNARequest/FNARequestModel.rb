require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class FNARequestModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			unless self.baseIO.baseDO
				self.baseIO.baseDO = FNARequest.new if self.createNewObject
				if self.baseIO.baseDO
					# self.baseIO.baseDO.userId = Time.now.strftime("%d/%m/%Y") if self.baseIO.baseDO.quotationDt.to_s == ""
					# self.baseIO.baseDO.agent = "LIFE" if self.baseIO.baseDO.insuranceTypeCd.to_s == ""
				end
			end
			return self.baseIO.baseDO
		end

		def setModel(entity)
			return entity		
		end

	end
	
end

begin 
    require 'FNARequest/FNARequestModel_company'
rescue LoadError => e
    puts 'FNARequestModel_company not included'
end