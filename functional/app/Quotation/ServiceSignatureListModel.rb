require 'CommonClasses/BaseModel'

module MobiSys
	
	class ServiceSignatureListModel < BaseModel
        def initialize(io)
            # logInfo "~~~in ServiceSignatureListModel initialize: #{io.inspect}"
            super(io)
            # logInfo "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			# logInfo("~~~baseIO in ServiceSignatureListModel:#{self.baseIO.inspect}")
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            serviceSignatureList = []
            quotation = self.parentBaseDO
            signatureContainer = SignatureContainer.loadObject(:first,
                                        :conditions => {
                                        :entityGuid => quotation.guid
                                        }
                                )
            serviceSignatureList = signatureContainer.ServiceSignatureList if signatureContainer

			return serviceSignatureList
		end

        def setModel(entity)
            quotation = self.parentBaseDO
            serviceSignatureList = []
            isSignatureAmmended = false
            signatureContainer = SignatureContainer.loadObject(:first,
                                        :conditions => {
                                        :entityGuid => quotation.guid
                                        }
                                )
            if signatureContainer == nil
                signatureContainer = SignatureContainer.new(:entityGuid => quotation.guid, :entityTypeCd => self.parentBaseDO.class.name.to_s)
                signatureContainer.persist
            else
                serviceSignatureList = signatureContainer.ServiceSignatureList
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
                        party = nil
                        if serviceSignature.roleCd.to_s != ""
                            party = QuotationParty.loadObject(:first,
                                :conditions => {
                                    :roleCd => serviceSignature.roleCd,
                                    :parentKey => quotation.object
                                }
                                )
                        end
                        serviceSignature.partyGuid = party.guid if party
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
    require 'Quotation/ServiceSignatureListModel_company'
rescue LoadError => e
    puts 'ServiceSignatureListModel_company not included'
end