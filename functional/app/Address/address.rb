# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
class Address
  include MobiSys::MobiSysEntitySchema

  # Uncomment the following line to enable sync with Address.
  # enable :sync
  
  property :line1, :string
  property :line2, :string

  #add model specifc code here
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.mobisys.dataobjects.AddressDO"
  end
end
