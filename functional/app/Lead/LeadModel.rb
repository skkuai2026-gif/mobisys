require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class LeadModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			lead = self.baseIO.baseDO
			lead = Lead.new unless lead
			
			return lead
		end
	end
	
end

begin 
    require 'Lead/LeadModel_company'
rescue LoadError => e
    puts 'LeadModel_company not included'
end