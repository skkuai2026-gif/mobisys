# The model has already been created by the framework, and extends Rhom::RhomObject
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'
#require 'Lead/lead'
# You can add more methods here
class FNARequestAdditional
  include Rhom::PropertyBag

  include MobiSys::MobiSysEntitySchema

  set :schema_version, '1.0'

  # Uncomment the following line to enable sync with FNARequest.
  # enable :sync

  # add model specific code here
  
  #FNARequestAdditional specific columns
  property :field1, :string
  property :field2, :string
  property :field3, :string
  property :field4, :string
  property :field5, :string
  property :field6, :string
  property :field7, :string
  property :field8, :string
  property :field9, :string
  property :field10, :string
  property :field11, :string
  property :field12, :string
  property :field13, :string
  property :field14, :string
  property :field15, :string
  property :field16, :string
  property :field17, :string
  property :field18, :string
  property :field19, :string
  property :field20, :string
  property :removed, :string
  
  # derived attributes  
  property :userId,       :string
  property :parentKey,    :string
  property :versionID,    :integer
  property :id,           :integer
  property :guid,         :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
	 
  	# model specific methods
	def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNARequestAdditionalDO"
	end

end
