require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys

	class FNARequestServiceSignatureListModel < BaseModel
		
		include MobiSys::BrowserHelper

		def initialize(io)
            super(io)
        end

		def getModel
            serviceSignatureList = []
            fnaRequest = self.parentBaseDO
            signatureContainer = SignatureContainer.loadObject(:first,
                                        :conditions => {
                                        :entityGuid => fnaRequest.guid
                                        }
                                )
            serviceSignatureList = signatureContainer.ServiceSignatureList if signatureContainer

			return serviceSignatureList
		end

        def setModel(entity)
            fnaRequest = self.parentBaseDO
            serviceSignatureList = []
            isSignatureAmmended = false
            signatureContainer = SignatureContainer.loadObject(:first,
                                        :conditions => {
                                        :entityGuid => fnaRequest.guid
                                        }
                                )
            if signatureContainer == nil
                signatureContainer = SignatureContainer.new(:entityGuid => fnaRequest.guid, :entityTypeCd => self.parentBaseDO.class.name.to_s)
                signatureContainer.persist
            else
                serviceSignatureList = signatureContainer.ServiceSignatureList
                serviceSignatureList.each do|serviceSign|
                    serviceSign.removed = "YES"                      
                    signatureContainer.removeServiceSignature(serviceSign)
                end    
            end


            if signatureContainer
                entity.each do |serviceSignature|
                    if serviceSignature.signatureTypeCd.to_s != ""
                        if !serviceSignatureList.empty?
                            serviceSignatureList.each do |eachSignature|
                                if ((eachSignature.guid.to_s == serviceSignature.guid.to_s) && (eachSignature.signature.to_s != serviceSignature.signature.to_s))
                                    isSignatureAmmended = true
                                end
                            end
                        end
                        if serviceSignature.signature.to_s != "" && serviceSignature.signatureDt.to_s != "" && !isSignatureAmmended
                            serviceSignature.signatureDt = getDBDate(serviceSignature.signatureDt)
                        else
                            serviceSignature.signatureDt = getDBDate(Time.now.strftime("%d/%m/%Y"))
                        end
                        serviceSignature.entityType = signatureContainer.entityTypeCd
                        
                        if serviceSignature.signature.to_s != "" && !serviceSignature.signature.to_s.start_with?('ZLIBCMP')
                            serviceSignature.signature = serviceSignature.signature.gsub!('data:image/png;base64,','')
                            original_signature_decoded = MobiSys::Encryption.decodeContents(serviceSignature.signature)
                            compressed_signature = MobiSys::Encryption.zipData(original_signature_decoded)
                            serviceSignature.signature = 'ZLIBCMP' + MobiSys::Encryption.encodeContents(compressed_signature) 
                        end
                        serviceSignature.status = ""
                        signatureContainer.addServiceSignature(serviceSignature)
                        signatureContainer.persistAll
                    end
                end
            end

            return signatureContainer.ServiceSignatureList
        end	
	end	
end

begin 
    require 'FNARequest/FNARequestServiceSignatureListModel_company'
rescue LoadError => e
    puts 'FNARequestServiceSignatureListModel_company not included'
end