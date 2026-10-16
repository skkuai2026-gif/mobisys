require 'CommonClasses/BaseModel'

module MobiSys
    
    class PolicyServiceSignatureListModelForRole < BaseModel

        def initialize(io)
            # puts "~~~in PolicyServiceSignatureListModelForRole initialize: #{io.inspect}"
            super(io)
            # puts "~~~baseIO:#{self.baseIO}"
        end

        def getModel
            # logInfo("~~~baseIO in PolicyServiceSignatureListModelForRole:#{self.baseIO.inspect}")
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")

            partyDO = nil
            policyDO = nil

            if self.parentBaseDO.class.name.to_s == "Party"
                partyDO = self.parentBaseDO
            elsif self.parentBaseDO.class.name.to_s == "Policy"
                policyDO = self.parentBaseDO
            end

            serviceSignatureDOList = []
            policyDO = self.baseIO.baseDO if policyDO == nil

            signatureContainer = SignatureContainer.loadObject(:first,
                                        :conditions => {
                                        :entityGuid => policyDO.guid
                                        }
                                )
            if signatureContainer

                # in same as case, if primary or proposer signature object is there,then no need to create other role of signature.
                if policyDO.quoteProposerSameAsInsured.to_s == "YES"
                    opposite_role = { "PRIMARY" => "PROPOSER", "PROPOSER" => "PRIMARY" }[self.roleCd.to_s]
                    if opposite_role
                        isRoleFound = signatureContainer.ServiceSignatureList.any? { |serviceSignatureDO| serviceSignatureDO.roleCd.to_s == opposite_role }
                    return serviceSignatureDOList if isRoleFound
                    end
                end


                signatureContainer.ServiceSignatureList.each do |serviceSignatureDO|
                    next if self.roleCd.to_s != "" && serviceSignatureDO.roleCd.to_s != "" && self.roleCd.to_s != serviceSignatureDO.roleCd.to_s
                    next if self.signatureTypeCd.to_s != "" && serviceSignatureDO.signatureTypeCd.to_s != "" && self.signatureTypeCd.to_s != serviceSignatureDO.signatureTypeCd.to_s

                    isSignatureAdd = true

                    if partyDO.to_s != "" && partyDO.guid.to_s == serviceSignatureDO.partyGuid.to_s
                        serviceSignatureDOList << serviceSignatureDO
                        isSignatureAdd = true
                    elsif policyDO.to_s != "" && policyDO.guid.to_s == serviceSignatureDO.entityGuid.to_s
                        serviceSignatureDOList << serviceSignatureDO
                        isSignatureAdd = true
                    end

                    if isSignatureAdd
                        if serviceSignatureDO.signature.to_s != "" && serviceSignatureDO.signature.to_s.start_with?('ZLIBCMP')
                            serviceSignatureDO.signature = serviceSignatureDO.signature.sub('ZLIBCMP','')
                            original_signature_decoded = MobiSys::Encryption.decodeContents(serviceSignatureDO.signature)
                            decompressed_signature = MobiSys::Encryption.unZipData(original_signature_decoded)
                            serviceSignatureDO.signature = 'data:image/png;base64,' + MobiSys::Encryption.encodeContents(decompressed_signature)
                        end
                    end
                end

            end 
            partyDO = self.baseIO.baseDO.getPartyByRole(self.roleCd.to_s)
            proposer = self.baseIO.baseDO.getPartyByRole("PROPOSER")
            proposerRelation = proposer.relationCd
            policyadditionalfield = self.baseIO.baseDO.getPolicyAddionalField("000")
        

            if (self.roleCd.to_s == "PROPOSER" || self.roleCd.to_s == "AGENT" || (self.roleCd.to_s == "PRIMARY" && partyDO && partyDO.age.to_i >= 18 && policyDO.quoteProposerSameAsInsured.to_s != "YES" && policyDO.quoteProposerSameAsInsured.to_s != "COPYFROMINSURED" )) || (self.roleCd.to_s == "PRIMARY" && partyDO && partyDO.age.to_i < 18 && policyadditionalfield && policyadditionalfield.field11.to_s == 'Y')
                if serviceSignatureDOList.empty?
                    serviceSignatureDO = ServiceSignature.new
                    serviceSignatureDO.partyGuid = partyDO.guid if partyDO.to_s != ""
                    serviceSignatureDO.entityGuid = policyDO.guid if policyDO.to_s != ""
                    serviceSignatureDO.roleCd = self.roleCd.to_s if self.roleCd.to_s != ""
                    # setting party guid if it is only set role code and not having party as parent
                    if self.roleCd.to_s != "" && partyDO.to_s == ""
                        partyDO = self.baseIO.baseDO.getPartyByRole(self.roleCd.to_s)
                        serviceSignatureDO.partyGuid = partyDO.guid if partyDO.to_s != ""
                    end
                    serviceSignatureDO.signatureTypeCd = self.signatureTypeCd.to_s if self.signatureTypeCd.to_s != ""
                    serviceSignatureDOList << serviceSignatureDO
                end
            end

            return serviceSignatureDOList
        end

        def setModel(entity)
            if entity
                partyDO = nil
                policyDO = nil
                filterColumnName = nil
                isSignatureAmmended = false
                serviceSignatureDOList = nil
                if self.parentBaseDO.class.name.to_s == "Party"
                    partyDO = self.parentBaseDO
                    filterColumnName = "partyGuid"
                elsif self.parentBaseDO.class.name.to_s == "Policy"
                    policyDO = self.parentBaseDO
                    filterColumnName = "entityGuid"
                end

                policyDO = self.baseIO.baseDO if policyDO == nil

                signatureContainer = SignatureContainer.loadObject(:first,
                                            :conditions => {
                                            :entityGuid => policyDO.guid
                                            }
                                    )

                signatureContainer = SignatureContainer.new(:entityGuid => policyDO.guid, :entityTypeCd => policyDO.class.name.to_s) if signatureContainer == nil

                # remove existing service signature list
                if signatureContainer
                    if signatureContainer.ServiceSignatureList.size > 0
                        liHM = CommonUtil.getLinkedHashedList(filterColumnName,signatureContainer.ServiceSignatureList)
                        if partyDO != nil
                            serviceSignatureDOList = liHM[partyDO.guid]
                        elsif policyDO != nil
                            serviceSignatureDOList = liHM[policyDO.guid]
                        end
                        if serviceSignatureDOList&.any?
                            serviceSignatureDOList.each do |serviceSignatureDO|
                                next if self.roleCd.to_s != "" && serviceSignatureDO.roleCd.to_s != "" && self.roleCd.to_s != serviceSignatureDO.roleCd.to_s
                                next if self.signatureTypeCd.to_s != "" && serviceSignatureDO.signatureTypeCd.to_s != "" && self.signatureTypeCd.to_s != serviceSignatureDO.signatureTypeCd.to_s
                                serviceSignatureDO.removed = "YES"
                                signatureContainer.addServiceSignature(serviceSignatureDO)
                            end
                        end
                    end                     
                end

                entity.each do |serviceSignatureDO|
                    serviceSignatureDO.partyGuid = partyDO.guid if serviceSignatureDO.partyGuid.to_s == "" && partyDO.to_s != ""
                    serviceSignatureDO.entityGuid = policyDO.guid if serviceSignatureDO.entityGuid.to_s == ""
                    serviceSignatureDO.roleCd = self.roleCd if serviceSignatureDO.roleCd.to_s == "" && self.roleCd.to_s != ""
                    # setting party guid if it is only set role code and not having party as parent
                    if self.roleCd.to_s != "" && partyDO.to_s == "" && serviceSignatureDO.partyGuid.to_s == ""
                        partyDO = self.baseIO.baseDO.getPartyByRole(self.roleCd.to_s)
                        serviceSignatureDO.partyGuid = partyDO.guid if partyDO.to_s != ""
                    end
                    serviceSignatureDO.signatureTypeCd = self.signatureTypeCd if serviceSignatureDO.signatureTypeCd.to_s == "" && self.signatureTypeCd.to_s != ""
                    if signatureContainer
                        if serviceSignatureDO.signatureTypeCd.to_s != ""
                            if !signatureContainer.ServiceSignatureList.empty?
                                signatureContainer.ServiceSignatureList.each do |eachSignature|
                                    if ((eachSignature.guid.to_s == serviceSignatureDO.guid.to_s) && (eachSignature.signature.to_s != serviceSignatureDO.signature.to_s))
                                        isSignatureAmmended = true
                                    end
                                end
                            end
                            if serviceSignatureDO.signature.to_s != "" && serviceSignatureDO.signatureDt.to_s != "" && !isSignatureAmmended
                                serviceSignatureDO.signatureDt = getDBDate(serviceSignatureDO.signatureDt)
                            else
                                serviceSignatureDO.signatureDt = getDBDate(Time.now.strftime("%d/%m/%Y"))
                            end

                            serviceSignatureDO.entityType = signatureContainer.entityTypeCd
                
                            if serviceSignatureDO.signature.to_s != "" && !serviceSignatureDO.signature.to_s.start_with?('ZLIBCMP')
                                serviceSignatureDO.signature = serviceSignatureDO.signature.gsub!('data:image/png;base64,','')
                                original_signature_decoded = MobiSys::Encryption.decodeContents(serviceSignatureDO.signature)
                                compressed_signature = MobiSys::Encryption.zipData(original_signature_decoded)
                                serviceSignatureDO.signature = 'ZLIBCMP' + MobiSys::Encryption.encodeContents(compressed_signature)
                            end
                            serviceSignatureDO.status = ""
                            signatureContainer.addServiceSignature(serviceSignatureDO)
                            signatureContainer.persistAll
                        end
                    end
                end
            end
            return entity
        end

    end
end

begin 
    require 'Policy/PolicyServiceSignatureListModelForRole_company'
rescue LoadError => e
    puts 'PolicyServiceSignatureListModelForRole_company not included'
end