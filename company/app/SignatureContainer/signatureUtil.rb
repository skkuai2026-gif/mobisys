require 'json'
require 'CommonModules/schema_module.rb'
require 'CommonModules/entityschema'
require 'CommonModules/mobisysbrowserhelper'
module MobiSys
  class SignatureUtil
    extend BrowserHelper
    extend MobiSys::BrowserHelper
    
    #Deepali Singh 18-08-2015: Method to get service signature for agent, proposer, insured, supplementary for entity
    def self.getSignatures(entity,signatureContainer)
      supplementarySigns = Array.new
      agentSign = proposerSign = insuredSign = supplementarySign = beneficiarySign = parentSign = fatcaSign = agentTabSign = nil
        
      serviceSignArr = []
      signatureTypesArr = ["SIGNATURECAPTUREEAPPPROPOSER", "SIGNATURECAPTUREEAPPPRIMARY", "FATCASIGNATURECAPTURE", "PARENTSIGNATURECAPTURE", "AGENTSIGNATURECAPTURE", "AGENTTYPE"]
      serviceSignArr = signatureContainer.ServiceSignatureList.select{|serviceSign| signatureTypesArr.include?(serviceSign.signatureTypeCd.to_s) } if signatureContainer
      serviceSignArr.each do |serviceSign|
        case serviceSign.roleCd
        when "PROPOSER"
          proposerSign = serviceSign
        when "PRIMARY"
          insuredSign = serviceSign
        when "SUPPLEMENTARY"
          supplementarySigns.push(serviceSign)
        when "PARENT"
          parentSign = serviceSign
        when "FATCA"
          fatcaSign = serviceSign
        when "AGENT"
          if serviceSign.signatureTypeCd.to_s == 'AGENTSIGNATURECAPTURE'
            agentSign = serviceSign
          elsif serviceSign.signatureTypeCd.to_s == 'AGENTTYPE'
            agentTabSign = serviceSign
          end
        end
      end
      
      insuredPartyRole = entity.getPolicyPartyRole("PRIMARY")
      # policyadditionalfield = entity.getAdditionalFields
      policyadditionalfield = entity.getPolicyAddionalField("000")
      insured = entity.getParty("PRIMARY")
      proposer = entity.getParty("PROPOSER")
        proposerRelation = proposer.relationCd
        if insured  && insuredPartyRole.partySameAsCd.to_s == ""
          if insured && insured.age.to_i < 18 && policyadditionalfield && policyadditionalfield.field11.to_s == 'Y'
            # parentSign = ServiceSignature.new(:signatureTypeCd => "PARENTSIGNATURECAPTURE", :entityGuid => entity.guid,:roleCd => "PARENT", :entityType => entity.class.name.to_s)
            # signatureContainer.addServiceSignature(parentSign)
            if parentSign.to_s == ""
              if insuredSign.to_s != "" && insuredSign.signature.to_s != ""
                parentSign = insuredSign
              elsif proposerSign
                parentSign = proposerSign
              end 
            elsif parentSign.to_s != "" && parentSign.signature.to_s == ""
              if insuredSign.to_s != "" && insuredSign.signature.to_s != ""
                parentSign = insuredSign
              elsif proposerSign && proposerSign.signature.to_s != ""
                parentSign = proposerSign
              end 
            end  
          end
        end
      # if agentSign.to_s == ""
      #   # agentSign = ServiceSignature.new(:signatureTypeCd => "AGENTSIGNATURECAPTURE", :entityGuid => entity.guid, :entityType => entity.class.name.to_s, :roleCd => "AGENT")
      #   # signatureContainer.addServiceSignature(agentSign)
      # end

      # if parentSign.to_s == ""
      #   insured = entity.getParty("PRIMARY")
      #   proposer = entity.getParty("PROPOSER")
      #   proposerRelation = proposer.relationCd
      #   if insured  && insuredPartyRole.partySameAsCd.to_s == ""
      #     if (policyadditionalfield && policyadditionalfield.field11.to_s == 'Y' || (proposerRelation.to_s != "" && (proposerRelation.to_s == "MOTH" || proposerRelation.to_s == "FATH") && insured.age.to_i < 18))
      #       parentSign = ServiceSignature.new(:signatureTypeCd => "PARENTSIGNATURECAPTURE", :entityGuid => entity.guid,:roleCd => "PARENT", :entityType => entity.class.name.to_s)
      #       signatureContainer.addServiceSignature(parentSign)
      #     end
      #   end
      # end

      if fatcaSign.to_s == "" && proposerSign
        # fatcaSign = ServiceSignature.new(:signatureTypeCd => "FATCASIGNATURECAPTURE", :entityGuid => entity.guid,:roleCd => "FATCA", :entityType => entity.class.name.to_s)
        # signatureContainer.addServiceSignature(fatcaSign)
        fatcaSign = proposerSign
      elsif fatcaSign.to_s != "" && fatcaSign.signature.to_s == "" && proposerSign
           fatcaSign = proposerSign   
      end

      if entity.class.name.to_s == "Policy"
        # if proposerSign.to_s == ""
        #   proposer = entity.getParty("PROPOSER")
        #   if proposer
        #     proposerSign = ServiceSignature.new(:signatureTypeCd => "SIGNATURECAPTUREEAPPPROPOSER", :entityGuid => entity.guid ,:partyGuid => proposer.guid, :roleCd => "PROPOSER", :entityType => entity.class.name.to_s)
        #     signatureContainer.addServiceSignature(proposerSign)
        #   end
        # end

          insured = entity.getParty("PRIMARY")
          if insured && insuredPartyRole && insuredPartyRole.partySameAsCd.to_s == ""
            if !(insured.age >= 18)
              insuredSign = nil
            end
          end
        
        if supplementarySigns.empty? 
          supplementaryInsuredList = entity.getPartyList("SUPPLEMENTARY")
          if supplementaryInsuredList  
            supplementaryInsuredList.each do |supplementaryInsured| 
              supplementarySign = ServiceSignature.new(:signatureTypeCd => "SIGNATURECAPTURE", :entityGuid => entity.guid ,:partyGuid =>  supplementaryInsured.guid, :roleCd => "SUPPLEMENTARY", :entityType => entity.class.name.to_s)
              signatureContainer.addServiceSignature(supplementarySign)
              supplementarySigns.push(supplementarySign)
            end
          end
        end
      elsif entity.class.name.to_s == "Quotation"
        if proposerSign.to_s == ""
          proposer = entity.getPartyByRole("PROPOSER")
          if proposer
            proposerSign = ServiceSignature.new(:signatureTypeCd => "SIGNATURECAPTURE", :entityGuid => entity.guid ,:partyGuid => proposer.guid, :roleCd => "PROPOSER", :entityType => entity.class.name.to_s)
            signatureContainer.addServiceSignature(proposerSign)
          end
        end

        if insuredSign.to_s == ""
          insured = entity.getPartyByRole("PRIMARY")
          if insured
            roleCd = (insured.age.to_s!="" && insured.age < 18) ? "PARENT" : "PRIMARY"
            insuredSign = ServiceSignature.new(:signatureTypeCd => "SIGNATURECAPTURE", :entityGuid => entity.guid ,:partyGuid =>  insured.guid, :roleCd => roleCd, :entityType => entity.class.name.to_s)
            signatureContainer.addServiceSignature(insuredSign)
          end
        end

        if supplementarySigns.empty?
          supplementaryInsuredList = entity.getPartyListByRoleCd("SUPPLEMENTARY")
          if supplementaryInsuredList
            supplementaryInsuredList.each do |supplementaryInsured|
              supplementarySign = ServiceSignature.new(:signatureTypeCd => "SIGNATURECAPTURE", :entityGuid => entity.guid ,:partyGuid =>  supplementaryInsured.guid, :roleCd => "SUPPLEMENTARY", :entityType => entity.class.name.to_s)
              signatureContainer.addServiceSignature(supplementarySign)
              supplementarySigns.push(supplementarySign)
            end
          end
        end 
      end
      return agentSign, proposerSign, insuredSign, supplementarySigns, parentSign, fatcaSign,agentTabSign
    end

    def self.getFNASignatures(entity,signatureContainer)
      p "in getFNASignatures===>#{entity}===>#{signatureContainer}"
      agentSign = proposerSign = nil
      policySign = nil
      policyAgentSign = nil
      serviceSignArr = []
      serviceSignArr = signatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.signatureTypeCd == "SIGNATURECAPTUREFNAPROPOSER" || serviceSign.signatureTypeCd == "AGENTSIGNATURECAPTUREFNA"} if signatureContainer
      
      serviceSignArr.each do |serviceSign|
        case serviceSign.roleCd
        when "PROPOSER"
          proposerSign = serviceSign
        else
          agentSign = serviceSign
        end
      end
     
      policy = Policy.find(:first, :conditions => {:proposalNum => entity.marketingInfoFl.to_s})
      if policy 
         signatureContainerPolicy = SignatureContainer.loadObject(:first, :conditions => {:entityGuid =>policy.guid})
      end
      if signatureContainerPolicy
        signatureContainerPolicy.ServiceSignatureList.each do |servSign|
          if servSign && servSign.signatureTypeCd.to_s == "SIGNATURECAPTUREEAPPPROPOSER"
            policySign = servSign
            if $rhoconfig[:SunPHComp].to_s == 'SLGFI'
               policyAgentSign = servSign
              break
            end  
          elsif servSign && servSign.signatureTypeCd.to_s == "AGENTSIGNATURECAPTURE"
             policyAgentSign = servSign
          end
        end
      end  
      

      if agentSign.to_s == "" && policyAgentSign
         agentSign = policyAgentSign
        # agentSign = ServiceSignature.new(:signatureTypeCd => "AGENTSIGNATURECAPTUREFNA", :entityGuid => entity.guid, :entityType => entity.class.name.to_s, :roleCd => "AGENT")
      elsif agentSign && agentSign.signature.to_s == "" && policyAgentSign
        agentSign = policyAgentSign
      end

      if proposerSign.to_s == "" && policySign
        proposer = entity.getParty("PROPOSER")
        if proposer
          # proposerSign = ServiceSignature.new(:signatureTypeCd => "SIGNATURECAPTUREFNAPROPOSER", :entityGuid => entity.guid ,:partyGuid => proposer.guid, :roleCd => "PROPOSER", :entityType => entity.class.name.to_s)
          # signatureContainer.addServiceSignature(proposerSign)
          proposerSign = policySign 
        end
      elsif proposerSign && proposerSign.signature.to_s == "" && policySign 
           proposerSign = policySign 
      end

      return agentSign, proposerSign
    end
    
    #Deepali Singh 18-08-2015: Clear signatures captured for entity on tab change
    def self.clearSignatures(entity)
      signatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => entity.guid})
      if signatureContainer
        signatureContainer.ServiceSignatureList.each do|servSign|
          if servSign.to_s != "" && servSign.signatureTypeCd != "AGENTDECLARATION" #&& servSign.removed=="YES"
              servSign.destroy  
          end
        end
        signatureContainer.ServiceSignatureList.each do|servSignRemove|
          if servSignRemove.to_s != "" && servSignRemove.signatureTypeCd != "AGENTDECLARATION" #&& servSignRemove.removed=="YES"
            signatureContainer.removeServiceSignature(servSignRemove) 
          end
        end
        signatureContainer.destroy if signatureContainer.ServiceSignatureList.size <= 0
        entity.signatureStatus = ""
      end
    end

    def self.clearPartySignature(entity,partyGuid)
      signatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => entity.guid})
      if signatureContainer
        signatureContainer.ServiceSignatureList.each do|servSign|
          if servSign.to_s != "" && servSign.partyGuid == partyGuid
            servSign.destroy
          end
        end
        entity.signatureStatus = ""
      end
    end

    #Deepali Singh 18-08-2015: Method to get agent service signature
    def self.getAgentSignature(entity,signatureContainer)
      agentDeclarationSignature = nil
      agentDeclarationSignature = signatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.signatureTypeCd == "AGENTDECLARATION"}.first if signatureContainer
      # agentDeclarationSignature.signatureDt = MobiSys::BrowserHelper.getScreenDate(agentDeclarationSignature.signatureDt) if agentDeclarationSignature.to_s != "" && agentDeclarationSignature.signatureDt != ""
      if agentDeclarationSignature.to_s == ""
        agentDeclarationSignature = ServiceSignature.new(:signatureTypeCd => "AGENTDECLARATION", :entityGuid => entity.guid,:roleCd => "AGENT")
        signatureContainer.addServiceSignature(agentDeclarationSignature)
      end
      return agentDeclarationSignature
    end

    def self.getCounterOfferSignature(entity,signatureContainer)
      counterOfferSignature = nil
      counterOfferSignature = signatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.signatureTypeCd == "COUNTEROFFER"}.first if signatureContainer

      if counterOfferSignature.to_s == ""
        counterOfferSignature = ServiceSignature.new(:signatureTypeCd => "COUNTEROFFER", :entityGuid => entity.guid)
        signatureContainer.addServiceSignature(counterOfferSignature)
      end
      return counterOfferSignature
    end
  end 
end

begin 
    require 'SignatureContainer/signatureUtil_company'
rescue LoadError => e
    puts 'signatureUtil_company not included'
end