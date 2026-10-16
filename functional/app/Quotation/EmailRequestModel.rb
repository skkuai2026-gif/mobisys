require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class EmailRequestModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			# logInfo "~~~baseIO in EmailRequestModel:#{self.baseIO.inspect}"
			quotation = @baseIO.baseDO
			emailRequestDO = self.baseIO.emailRequestDO

			if emailRequestDO == nil 
				emailRequestDO = EmailRequest.new
				self.baseIO.emailRequestDO = emailRequestDO
			end
			proposer = quotation.getPartyByRole("PROPOSER")
			emailRequestDO.toEmail = proposer.emailAddress if proposer

			return emailRequestDO
		end

		def setModel(entity)
			if entity != nil
				entity.entityGuid = @baseIO.baseDO.guid
	            entity.entityNumber = @baseIO.baseDO.quotationRefNum
	            entity.entityName = 'Quotation'
	        	self.baseIO.emailRequestDO = entity
	        end

	        return entity
		end

	end
	
end

begin 
    require 'Quotation/EmailRequestModel_company'
rescue LoadError => e
    puts 'EmailRequestModel_company not included'
end