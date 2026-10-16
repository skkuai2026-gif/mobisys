# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class Customer
  include MobiSys::MobiSysEntitySchema

  # Uncomment the following line to enable sync with Customer.
  # enable :sync
  property :firstName,:string
  property :lastName,:string
  has_many 'Address'

  #add model specifc code here
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.mobisys.dataobjects.CustomerDO"
  end
end
