# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class Device
  include Rhom::FixedSchema
  include MobiSys::MobiSysFixedSchema

  # Uncomment the following line to enable sync with Device.
  # enable :sync

  #add model specifc code here
  property :deviceId, :string
  property :deviceName, :string
  property :osVersion, :string
  property :appVersion, :string
  property :masterDBVersion, :string
  property :devicePlatform, :string
  property :mobiSysDeviceId, :string
end
