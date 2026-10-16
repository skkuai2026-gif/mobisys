class ENTRYAGEVALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotationProduct
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("entryAge") + "("
  	  return quotationProduct.combinedEntryAge
    else
      return nil
    end 
  end
end

class PPTERMVALUE
  def self.getValue(quotation, quotationProduct,party)
    if quotationProduct
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("premiumPayingTerm") + "("
      return quotationProduct.premiumPayingTerm.to_i
    else
      return nil
    end
  end
end

class POLICYYEARVALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotation
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("policyYear") + "("
      return quotation.policyYear
    else
      return nil
    end
  end
end

class GENDERCDVALUE
  def self.getValue(quotation, quotationProduct,party)
    if party
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("genderCd") + "("
      return party.genderCd
    else
      return nil
    end
  end
end

class QUOTADDTNLFIELD1
  def self.getValue(quotation, quotationProduct,party)
    if quotation
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotAddtnlField1") + "("
      return quotation.quotAddtnlField1
    else
      return nil
    end
  end
end

class QUOTADDTNLFIELD2
  def self.getValue(quotation, quotationProduct,party)
    if quotation
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotAddtnlField2") + "("
      return quotation.quotAddtnlField2
    else
      return nil
    end
  end
end

class QUOTADDTNLFIELD3
  def self.getValue(quotation, quotationProduct,party)
    if quotation
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotAddtnlField3") + "("
      return quotation.quotAddtnlField3
    else
      return nil
    end
  end
end

class QUOTADDTNLFIELD4
  def self.getValue(quotation, quotationProduct,party)
    if quotation
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotAddtnlField4") + "("
      return quotation.quotAddtnlField4
    else
      return nil
    end
  end
end

class QUOTPARTYADDTNFIELD1VALUE
  def self.getValue(quotation, quotationProduct,party)
    if party
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotPartyAddtnField1") + "("
      return party.quotPartyAddtnField1
    else
      return nil
    end
  end
end

class QUOTPARTYADDTNFIELD2VALUE
  def self.getValue(quotation, quotationProduct,party)
    if party
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotPartyAddtnField2") + "("
      return party.quotPartyAddtnField2
    else
      return nil
    end
  end
end

class QUOTPARTYADDTNFIELD3VALUE
  def self.getValue(quotation, quotationProduct,party)
    if party
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotPartyAddtnField3") + "("
      return party.quotPartyAddtnField3
    else
      return nil
    end
  end
end

class QUOTPARTYADDTNFIELD4VALUE
  def self.getValue(quotation, quotationProduct,party)
    if party
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotPartyAddtnField4") + "("
      return party.quotPartyAddtnField4
    else
      return nil
    end
  end
end

class SMOKERVALUE
  def self.getValue(quotation, quotationProduct, party)
    if party
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("smoker") + "("
      return party.smoker
    else
      return nil
    end
  end
end

class PLANOPTIONCDVALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotationProduct and quotationProduct.productPlanOptionCd
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("planOptionCd") + "("
      return quotationProduct.productPlanOptionCd
    else
      return nil
    end
  end
end

class ILLUSTRATIONRATEVALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotationProduct and quotationProduct.illustrationRate
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("illustrationRate") + "("
      return quotationProduct.illustrationRate
    else
      return nil
    end
  end
end

#Swati Ahire 30-06-2014: Added ATTAINEDAGEVALUE, OCCUPATIONCLASSVALUE and ADDTNFIELD2VALUE
class ATTAINEDAGEVALUE
  def self.getValue(quotation, quotationProduct, party)
    if party
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("attainedAge") + "("
      return party.age
    else
      return nil
    end
  end
end

class OCCUPATIONCLASSVALUE
  def self.getValue(quotation, quotationProduct, party)
    if party
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("occupationCd") + "("
      return party.occupationCd
    else
      return nil
    end
  end
end

class ADDTNFIELD1VALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotationProduct
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("addtnField1") + "("
      return quotationProduct.addtnField1
    else
      return nil
    end
  end
end

class ADDTNFIELD2VALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotationProduct
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("addtnField2") + "("
      return quotationProduct.addtnField2
    else
      return nil
    end
  end
end

class COMPUTEDFIELDVALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotation
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("computedField") + "("
      return quotation.additionalField
    else
      return nil
    end  
  end  
end

class CURRENCYCDVALUE
  def self.getValue(quotation,quotationProduct, party)
    if quotation and quotation.getBasePlan
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("currencyCd") + "("
      return quotation.getBasePlan.currencyCd
    else
      return nil
    end  
  end  
end  

class PAYMENTFREQUENCYCDVALUE
  def self.getValue(quotation,quotationProduct, party)
    if quotation and quotation.getBasePlan
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("paymentFrequencyCd") + "("
      return quotation.getBasePlan.paymentFrequencyCd
    else
      return nil
    end  
  end
end   

class PAYMENTTYPECDVALUE
  def self.getValue(quotation,quotationProduct, party)
    if quotation and quotation.getBasePlan
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("paymentTypeCd") + "("
      return quotation.getBasePlan.paymentTypeCd
    else
      return nil
    end  
  end
end  

class TERMVALUE
  def self.getValue(quotation,quotationProduct, party)
    if quotationProduct and quotationProduct.productTerm
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("Product Term") + "("
      return quotationProduct.productTerm.to_i
    else
      return nil
    end  
  end
end  

class PROPOSERAGEVALUE
  def self.getValue(quotation,quotationProduct,party)
    if quotation
      proposer = quotation.getPartyByRole("PROPOSER")
      if proposer
        quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("proposerAge") + "("
        return proposer.age
      else  
        return nil  
      end
    else
      return nil    
    end  
  end  
end  

class PRIMARYAGEVALUE
  def self.getValue(quotation,quotationProduct,party)
    if quotation
      primary = quotation.getPartyByRole("PRIMARY")
      if primary
        quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("primaryAge") + "("
        return primary.age
      else  
        return nil  
      end
    else
      return nil    
    end  
  end  
end   

class JOINTLIFEAGEVALUE
  def self.getValue(quotation,quotationProduct,party)
    if quotation
      jointLife = quotation.getPartyByRole("JOINT")
      if jointLife
        quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("jointLifeAge") + "("
        return jointLife.age
      else  
        return nil  
      end
    else
      return nil    
    end  
  end  
end  

#Swati Ahire 14-07-2014: Added ADDTNFIELD3VALUE
class ADDTNFIELD3VALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotationProduct
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("addtnField3") + "("
      return quotationProduct.addtnField3
    else
      return nil
    end
  end
end

class FUNDCDVALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotationProduct and quotationProduct.fundCd
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("fundCd") + "("
      return quotationProduct.fundCd
    else
      return nil
    end
  end
end  

class NATUREOFDUTYID
  def self.getValue(quotation, quotationProduct, party)
    if party and party.natureOfDuty
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("natureOfDuty") + "("
      return party.natureOfDuty
    else
      return nil
    end
  end
end

class TOPUPTYPECDVALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotationProduct and quotationProduct.topUpTypeCd
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("topUpTypeCd") + "("
      return quotationProduct.topUpTypeCd
    else
      return nil
    end
  end
end

class NATUREOFDUTYIDVALUE
  def self.getValue(quotation, quotationProduct, party)
    if party and party.natureOfDuty
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("natureOfDuty") + "("
      return party.natureOfDuty
    else
      return nil
    end
  end
end

class RIDERPRODUCTIDVALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotationProduct
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("riderProductId") + "("
      return quotationProduct.productId
    else
      return nil
    end
  end
end 

class EXTRATYPECDVALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotationProduct
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("extraTypeCd") + "("
      return quotationProduct.loadingTypeCd
    else
      return nil
    end
  end
end

class ROLECDVALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotationProduct
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("roleCd") + "("
      return quotationProduct.partyRoleCd
    else
      return nil
    end
  end
end

#Swati Ahire 04-11-2014: Added PARTYTYPECDVALUE
#Deepali Singh 02-07-2015: ALtered PARTYTYPECDVALUE to get partytypecd as Proposer
class PARTYTYPECDVALUE
  def self.getValue(quotation, quotationProduct, party)
    if party
      proposer = quotation.getPartyByRole("PROPOSER")
      if proposer
        quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("partyTypeCd") + "("
        return proposer.partyTypeCd
      else
        return nil
      end          
    else
      return nil
    end
  end
end

#Swati Ahire 27-03-2015: Added RELATIONCDVALUE
class RELATIONCDVALUE
  def self.getValue(quotation, quotationProduct, party)
    if party
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("relationCd") + "("
      return party.relationCd
    else
      return nil
    end  
  end  
end

class PARTYROLECDVALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotationProduct
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("partyRoleCd") + "("
      return quotationProduct.partyRoleCd
    else
      return nil
    end
  end
end

class CITIZENSHIPCDVALUE
  def self.getValue(quotation, quotationProduct, party)
    if party
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("citizenshipCd") + "("
      return party.citizenshipCd
    else
      return nil
    end
  end
end

class PARENTAGENCYIDVALUE
  def self.getValue(quotation, quotationProduct,party)
    if quotation
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("parentAgency") + "("
      return quotation.parentAgency
    else
      return nil
    end
  end
end

class MARITALSTATUSCDVALUE
  def self.getValue(quotation, quotationProduct,party)
    if party
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("maritalStatus") + "("
      return party.maritalStatus
    else
      return nil
    end
  end
end

class CHANNELIDVALUE
  def self.getValue(quotation, quotationProduct,party)
    if quotation
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("channelId") + "("
      return quotation.channel
    else
      return nil
    end
  end
end

class SUBCHANNELIDVALUE
  def self.getValue(quotation, quotationProduct,party)
    if quotation
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("subChannelId") + "("
      return quotation.subChannel
    else
      return nil
    end
  end
end

class LOADINGPERCENTVALUE
  def self.getValue(quotation, quotationProduct,party)
    if quotationProduct && quotationProduct.getExtraQuotationProducts[0]
      quotationProductExtra = quotationProduct.getExtraQuotationProducts[0]
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("loadingPercent") + "("
      return quotationProductExtra.extraPercent
    else
      return nil
    end
  end
end

class PAYMENTINSTRUCTIONTYPECDVALUE
  def self.getValue(quotation, quotationProduct, party)
    if quotation
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("paymentInstructionTypeCd") + "("
      return quotation.paymentInstructionTypeCd
    else
      return nil
    end
  end
end

begin 
    require 'CommonModules/valueclasses_company'
rescue LoadError => e
    puts 'valueclasses_company not included'
end