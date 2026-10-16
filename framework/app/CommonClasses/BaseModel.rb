# require 'CommonClasses/BaseIO'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	class BaseModel
		include MobiSys::BrowserHelper
		attr_accessor :baseIO
		attr_accessor :parentBaseDO
		attr_accessor :initForMerge, :addDefaultRecord
		#Neha Comments Done
		def initialize(io)
			# logInfo "~~~in BaseModel initialize: #{io.inspect}"
			self.baseIO = io
			# logInfo "~~~baseIO:#{self.baseIO}"
		end

		def getModel
			#return baseDO
		end

		def setModel(baseDO)
			#self.baseIO
			return baseDO
		end
	end
end