require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class PolicyOutputPreferencesModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			# logInfo "~~~baseIO in PolicyOutputPreferencesModel:#{self.baseIO.inspect}"
			self.baseIO.outputPreferencesDO = MobiSys::PolicyService.defaultOutputPreferences(OutputPreferences.new) if self.baseIO.outputPreferencesDO == nil
			return self.baseIO.outputPreferencesDO
		end

		def setModel(entity)
			self.baseIO.outputPreferencesDO = entity
			return entity
		end

	end
	
end

begin 
    require 'Policy/PolicyOutputPreferencesModel_company'
rescue LoadError => e
    puts 'PolicyOutputPreferencesModel_company not included'
end