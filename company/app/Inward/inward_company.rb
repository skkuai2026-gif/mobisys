# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class Inward  
    include MobiSys::MobiSysEntitySchema
    
  	set :schema_version, '1.1'
  
	# Uncomment the following line to enable sync with Lead.
	# enable :sync

	#add model specifc code here
	property :inwardNum, :string
	property :workflowInwardNum, :string
	def afterSync
		returnInward = InwardPolicy.loadObject(
                :first,
                :conditions => {
                    {:name => 'parentKey'} => self.object
                }
            )
		if returnInward && returnInward.acctTypeCd.to_s == ""
			returnInward.acctTypeCd = "APPLICATION_SUSPENSE"
		    returnInward.persistAll
	    end		
    end		
end
