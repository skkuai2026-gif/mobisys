require 'CommonClasses/BaseModel'
require 'Policy/PolicyServiceSignatureListModel'

module MobiSys
    
    class PolicyServiceSignatureListModel_SUNPH < PolicyServiceSignatureListModel

        def initialize(io)
            #puts "~~~in PolicyServiceSignatureListModel_SUNPH initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

        def getModel
            #logInfo("~~~baseIO in PolicyServiceSignatureListModel_SUNPH:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")

            serviceSignatureList = []
            policy = self.baseIO.baseDO
            signatureContainer = SignatureContainer.loadObject(:first,
                                        :conditions => {
                                        :entityGuid => policy.guid
                                        }
                                )
            if signatureContainer
                 signatureContainer.ServiceSignatureList.each do |signature|
                    if signature.signatureTypeCd.to_s == "SIGNATURECAPTURE"
                        serviceSignatureList << signature
                    elsif signature.signatureTypeCd.to_s == "AGENTSIGNATURECAPTURE" && self.parentBaseDO.class.name.to_s == "Policy"
                        serviceSignatureList << signature
                    end
                 end
            end

            #if the model is initialized for merging purpose then no need to fetch and transform all data.. in accept counter offer decision,add quotation signature also
            if(self.initForMerge &&  policy.counterOfferDecisionCd.to_s == "ACCEPT")
                quotSignatureContainer = SignatureContainer.loadObject(:first,
                                        :conditions => {
                                        :entityGuid => policy.quotationRefGuid
                                        }
                                )
                if quotSignatureContainer
                    quotSignatureContainer.ServiceSignatureList.each do |quotSignature|
                        serviceSignatureList << quotSignature
                    end
                end
            end

            return serviceSignatureList
        end

        def setModel(entity)
            if entity
                policy = self.baseIO.baseDO
                serviceSignatureList = []
                isSignatureAmmended = false
                signatureContainer = SignatureContainer.loadObject(:first,
                                            :conditions => {
                                            :entityGuid => policy.guid
                                            }
                                    )

                if signatureContainer == nil
                    signatureContainer = SignatureContainer.new(:entityGuid => policy.guid, :entityTypeCd => policy.class.name.to_s)
                else
                    serviceSignatureList = signatureContainer.ServiceSignatureList
                end

                if signatureContainer
                    entity.each do |serviceSignature|
                        if serviceSignature
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
            
                end
            end

            return entity
        end

    end
end

begin 
    require 'Policy/PolicyServiceSignatureListModel_SUNPH_company'
rescue LoadError => e
    puts 'PolicyServiceSignatureListModel_SUNPH_company not included'
end