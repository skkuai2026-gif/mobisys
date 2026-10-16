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
      agentSign = proposerSign = insuredSign = supplementarySign = beneficiarySign = nil
        
      serviceSignArr = []
      serviceSignArr = signatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.signatureTypeCd == "SIGNATURECAPTURE" || serviceSign.signatureTypeCd == "AGENTSIGNATURECAPTURE" } if signatureContainer
      serviceSignArr.each do |serviceSign|
        # serviceSign.signatureDt = MobiSys::BrowserHelper.getScreenDate(serviceSign.signatureDt) if serviceSign.signatureDt != ""
        case serviceSign.roleCd
        when "PROPOSER"
          proposerSign = serviceSign
        when "PRIMARY", "GUARDIAN"
          insuredSign = serviceSign
        when "SUPPLEMENTARY"
           supplementarySigns.push(serviceSign)
        else
          agentSign = serviceSign
        end
      end
      
      insuredPartyRole = entity.getPolicyPartyRole("PRIMARY")

      if agentSign.to_s == ""
        agentSign = ServiceSignature.new(:signatureTypeCd => "AGENTSIGNATURECAPTURE", :entityGuid => entity.guid, :entityType => entity.class.name.to_s,:roleCd => "AGENT")
        signatureContainer.addServiceSignature(agentSign)
      end

      if entity.class.name.to_s == "Policy"
        if proposerSign.to_s == ""
          proposer = entity.getParty("PROPOSER")
          if proposer
            proposerSign = ServiceSignature.new(:signatureTypeCd => "SIGNATURECAPTURE", :entityGuid => entity.guid ,:partyGuid => proposer.guid, :roleCd => "PROPOSER", :entityType => entity.class.name.to_s)
            signatureContainer.addServiceSignature(proposerSign)
          end
        end

        if insuredSign.to_s == ""
          insured = entity.getParty("PRIMARY")
          if insured && insuredPartyRole.partySameAsCd.to_s == ""
            roleCd = (insured.age.to_s!="" && insured.age.to_i < 18) ? "GUARDIAN" : "PRIMARY"
            insuredSign = ServiceSignature.new(:signatureTypeCd => "SIGNATURECAPTURE", :entityGuid => entity.guid ,:partyGuid =>  insured.guid, :roleCd => roleCd, :entityType => entity.class.name.to_s)
            signatureContainer.addServiceSignature(insuredSign)
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
            roleCd = (insured.age.to_s!="" && insured.age < 18) ? "GUARDIAN" : "PRIMARY"
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
      return agentSign, proposerSign, insuredSign, supplementarySigns
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