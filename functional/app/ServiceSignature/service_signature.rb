# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'
require 'CommonModules/mobisysbrowserhelper'
require 'time'

class ServiceSignature
  include MobiSys::MobiSysEntitySchema
  extend MobiSys::BrowserHelper
  
  set :schema_version, '1.0'

  # Uncomment the following line to enable sync with ServiceSignature.
  # enable :sync

  #add model specific code here
  property :signatureTypeCd, :string
  property :signature, :string
  property :placeOfSignature, :string
  property :signatureDt, :date
  property :entityGuid, :string
  property :partyGuid, :string
  property :roleCd, :string
  property :removed, :string
  property :entityType, :string
  
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  attr_accessor :entityDesc
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.systemcommon.dataobjects.service.ServiceSignatureDO"
  end
  
  def self.entitiesForSync
    puts "before sync called for ServiceSignature."
    lastSyncDate = Time.at(0)
    lastSyncDateAppObject = Application.getValue('Quotation_' + $userId + '_lastSyncDate')
    if lastSyncDateAppObject
      lastSyncDate = Time._load(lastSyncDateAppObject.value)
    end
    signaturecont = SignatureContainer.loadObject(
      :all,
      conditions: {
        { name: 'entityTypeCd' } => 'Quotation',
      }
    )
    entitiesForSync = []
    signaturecont.each do |service|
      service.ServiceSignatureList.each do |servicesignature|
        entitiesForSync << servicesignature if Time.parse(servicesignature.systemUpdatedDt.to_s) >= lastSyncDate
      end
    end
    return entitiesForSync
  end

  def afterSync
    puts "After sync called for ServiceSignature."
    if self.entityType == 'Quotation'
      signature_container = SignatureContainer.loadObject(
        :first,
        conditions: {
          { name: 'entityTypeCd' } => 'Quotation',
          { name: 'entityGuid' } => self.entityGuid
        }
      )
      unless signature_container
        signature_container = SignatureContainer.new
        signature_container.entityGuid = self.entityGuid
        signature_container.entityTypeCd = 'Quotation'
        signature_container.userId = self.userId 
      end
      signature_container.addServiceSignature(self)
      signature_container.persistAll
    end
  end

  def getEntityDesc
    self.entityDesc = self.signatureTypeCd.to_s
  end

end

begin 
    require 'ServiceSignature/service_signature_company'
rescue LoadError => e
    puts 'service_signature_company not included'
end