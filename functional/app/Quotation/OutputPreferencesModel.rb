require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class OutputPreferencesModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			# logInfo "~~~baseIO in OutputPreferencesModel:#{self.baseIO.inspect}"
			self.baseIO.outputPreferencesDO = MobiSys::QuotationService.defaultOutputPreferences(OutputPreferences.new) if self.baseIO.outputPreferencesDO == nil

			return self.baseIO.outputPreferencesDO
		end

		def setModel(entity)
			self.baseIO.outputPreferencesDO = entity
			
			return entity
		end

	end
	
end

begin 
    require 'Quotation/OutputPreferencesModel_company'
rescue LoadError => e
    puts 'OutputPreferencesModel_company not included'
end