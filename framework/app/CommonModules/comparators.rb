require 'CommonModules/mobisysbrowserhelper'

class ValueInComparator
  def self.checkDefinitionTableValueIn1(dtValues, value,productDefinitionTable,dtd,flag)
    if value
      dtValuesList = dtValues.to_s.split(",")
      dtValuesList.each do |dtValue|
        if dtValue.to_s.casecmp(value.to_s) == 0
         return dtd,true
        else
         #return productDefinitionTable,false
        end
      end 
      return productDefinitionTable,false 
    end
    return productDefinitionTable,false
  end #
end

class ValueComparator
  def self.checkDefinitionTableValue1(dtValue, value, productDefinitionTable, dtd, flag)
    return productDefinitionTable, false if value == nil
    if value.is_a?(String) && value.match(/^[0-9]*(\.[0-9]+)?$/).to_s==""
      if value == dtValue
        return dtd, true
      else
        return productDefinitionTable, false
      end
    else  
      if value.to_f == dtValue.to_f
        return dtd, true
      else
        return productDefinitionTable, false
      end    
    end
    return productDefinitionTable, false
  end # checkDefinitionTableValue1
end

class RangeValueComparator
  def self.checkDefinitionTableRange1(dtValueFrom, dtValueTo, value, productDefinitionTable, dtd, flag)
    if value
      if value.to_f >= dtValueFrom.to_f and value.to_f <= dtValueTo.to_f
        return dtd, true
      else
        return productDefinitionTable, false
      end    
    end
    return productDefinitionTable, false  
  end # checkDefinitionTableRange

  def self.checkDefinitionTableRange2(dtValueFrom, dtValueTo, valueFrom, valueTo, productDefinitionTable, dtd, flag)
    if valueFrom && valueTo
      if valueFrom.to_f >= dtValueFrom.to_f and valueTo.to_f <= dtValueTo.to_f
        return dtd, true
      else
        return productDefinitionTable, false
      end    
    end
    return productDefinitionTable, false  
  end # checkDefinitionTableRange
end

class GENDERCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.genderCd and dtd.genderCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.genderCd,party.genderCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("genderCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.genderCd.to_s) if flag
      return productDefinitionTable, flag
    else  
      return productDefinitionTable, flag
    end  
  end
end

class PARTYROLECD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.partyRoleCd and dtd.partyRoleCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.partyRoleCd,party.roleCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("partyRoleCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.partyRoleCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class ENTRYAGE < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.entryAge and dtd.entryAge != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.entryAge,quotationProduct.combinedEntryAge,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("entryAge") + " " + dtd.entryAge.to_s if flag
      return productDefinitionTable, flag
    else  
      return productDefinitionTable, flag
    end  
  end
end

class ENTRYAGERANGE < RangeValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.entryAgeFrom and dtd.entryAgeFrom != "" and dtd.entryAgeTo and dtd.entryAgeTo != ""
      ageInFromUnits = quotationProduct.combinedEntryAge
      if dtd.minValueUnits != nil
        if "DAY" == dtd.minValueUnits
          ageInFromUnits = MobiSys::DateTimeUtils.dateDifferenceInDays(party.dob, quotation.quotationDt)
        elsif "MONTH" == dtd.minValueUnits
          ageInFromUnits = MobiSys::DateTimeUtils.dateDifferenceInMonths(party.dob, quotation.quotationDt)
        end
      end

      ageInToUnits = quotationProduct.combinedEntryAge
      if dtd.maxValueUnits != nil
        if "DAY" == dtd.maxValueUnits
          ageInToUnits = MobiSys::DateTimeUtils.dateDifferenceInDays(party.dob, quotation.quotationDt)
        elsif "MONTH" == dtd.maxValueUnits
          ageInToUnits = MobiSys::DateTimeUtils.dateDifferenceInMonths(party.dob, quotation.quotationDt)
        end
      end
      productDefinitionTable, flag = self.checkDefinitionTableRange2(dtd.entryAgeFrom,dtd.entryAgeTo,ageInFromUnits,ageInToUnits,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("entryAge") + "(" + dtd.entryAgeFrom.to_s + "-" + dtd.entryAgeTo.to_s + ")" if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class TERM < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.term and dtd.term != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.term,quotationProduct.productTerm,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("Product Term") + " " + dtd.term.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end   
  end
end

class TERMRANGE < RangeValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.termFrom and dtd.termFrom != "" and dtd.termTo and dtd.termTo != ""
      productDefinitionTable, flag = self.checkDefinitionTableRange1(dtd.termFrom,dtd.termTo,quotationProduct.productTerm,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("Product Term") + "(" + dtd.termFrom.to_s + "-" + dtd.termTo.to_s + ")" if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class PAYMENTTYPECD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.paymentTypeCd and dtd.paymentTypeCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.paymentTypeCd,quotationProduct.paymentTypeCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("paymentTypeCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.paymentTypeCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end     
  end
end

class LOADINGTYPECD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.loadingTypeCd and dtd.loadingTypeCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.loadingTypeCd,quotationProduct.loadingTypeCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("loadingTypeCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.loadingTypeCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class LOADINGPERCENT < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.loadingPercent.to_s != ""
      quotationProductExtra = quotationProduct.getExtraQuotationProducts[0]
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.loadingPercent,quotationProductExtra.extraPercent,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("loadingPercent") + " " + dtd.loadingPercent.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class EXTRATYPECD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.extraTypeCd and dtd.extraTypeCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.extraTypeCd,quotationProduct.loadingTypeCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("extraTypeCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.extraTypeCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class PAYMENTFREQUENCYCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.paymentFrequencyCd and dtd.paymentFrequencyCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.paymentFrequencyCd,quotationProduct.paymentFrequencyCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("paymentFrequencyCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.paymentFrequencyCd.to_s) if flag
      return productDefinitionTable, flag
    else  
      return productDefinitionTable, flag
    end  
  end
end

class RIDERPRODUCTID < ValueInComparator
  def self.compare(quotation,quotationProduct, party, productDefinitionTable, dtd, flag)
    riders = quotation.getRiders
    if dtd.riderProductId and dtd.riderProductId != "" #and not riders.empty?
      count = 0
      riderProductIdList = dtd.riderProductId.split(",")
      riderProductIdList.each do |riderProductId|
        riders.each do |rider|
          if riderProductId == rider.productId
            count +=1
            break            
          else
            next
          end #if riderProductId == rider.productId
        end #riders.each do |rider|
      end #riderProductIdList.each do |riderProductId|
      if count == riderProductIdList.length
        productDefinitionTable = dtd
        flag=true
        quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("riderProductId") + " " + MobiSys::BrowserHelper.getLabel(dtd.riderProductId.to_s)
        return productDefinitionTable, flag
      else
        return productDefinitionTable, false  
      end #if count == riderProductIdList.length
    else
      return productDefinitionTable, flag
    end #if dtd.riderProductId and dtd.riderProductId != "" and not riders.empty?
  end
end

class PAYMENTMETHODCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.paymentMethodCd and dtd.paymentMethodCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.paymentMethodCd,quotationProduct.paymentMethodCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("paymentMethodCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.paymentMethodCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class PLANOPTIONCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.planOptionCd and dtd.planOptionCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.planOptionCd,quotationProduct.productPlanOptionCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("planOptionCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.planOptionCd.to_s) if flag
      return productDefinitionTable, flag
    else    
      return productDefinitionTable, flag
    end  
  end
end

class POLICYYEARRANGE < RangeValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.policyYearFrom and dtd.policyYearFrom != "" and dtd.policyYearTo and dtd.policyYearTo != ""
      productDefinitionTable, flag = self.checkDefinitionTableRange1(dtd.policyYearFrom,dtd.policyYearTo,quotation.policyYear,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("policyYear") + "(" + dtd.policyYearFrom.to_s + "-" + dtd.policyYearTo.to_s + ")" if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class ANNUALPREMIUMRANGE < RangeValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.annualPremiumFrom.to_s!="" || dtd.annualPremiumTo.to_s!=""
      productDefinitionTable, flag = self.checkDefinitionTableRange1(dtd.annualPremiumFrom, dtd.annualPremiumTo, quotationProduct.baseAnnualPremium, productDefinitionTable, dtd, flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("annualPremium") + "(" + dtd.annualPremiumFrom.to_s + "-" + dtd.annualPremiumTo.to_s + ")" if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable,flag
    end
  end
end

class ANNUALPREMIUM < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.annualPremium and dtd.annualPremium != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.annualPremium,quotationProduct.annualPremium,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("annualPremium") + " " + dtd.annualPremium.to_s if flag  
      return productDefinitionTable, flag
    else   
      return productDefinitionTable, flag
    end  
  end
end

class PREMIUMRANGE < RangeValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.premiumFrom.to_s!="" || dtd.premiumTo.to_s!=""
      productDefinitionTable, flag = self.checkDefinitionTableRange1(dtd.premiumFrom, dtd.premiumTo, quotationProduct.modalPremium, productDefinitionTable, dtd, flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("modalPremium") + "(" + dtd.premiumFrom.to_s + "-" + dtd.premiumTo.to_s + ")" if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable,flag
    end
  end
end

class PREMIUM < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.premium and dtd.premium != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.premium,quotationProduct.modalPremium,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("modalPremium") + " " + dtd.premium.to_s if flag  
      return productDefinitionTable, flag
    else   
      return productDefinitionTable, flag
    end  
  end
end

class ATTAINEDAGERANGE < RangeValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.attainedAgeFrom.to_s != "" and dtd.attainedAgeTo.to_s != ""
      ageInFromUnits = party.age
      forwardPolicyIssueDt = quotation.quotationDt
      if party.policyYear.to_i > 0
        forwardPolicyIssueDt = MobiSys::DateTimeUtils.getForwardDateByMonths(forwardPolicyIssueDt, (12*party.policyYear.to_i))
      end
      if dtd.minValueUnits != nil
        if "DAY" == dtd.minValueUnits
          ageInFromUnits = MobiSys::DateTimeUtils.dateDifferenceInDays(party.dob, forwardPolicyIssueDt)
        elsif "MONTH" == dtd.minValueUnits
          ageInFromUnits = MobiSys::DateTimeUtils.dateDifferenceInMonths(party.dob, forwardPolicyIssueDt)
        end
      end

      ageInToUnits = party.age
      if dtd.maxValueUnits != nil
        if "DAY" == dtd.maxValueUnits
          ageInToUnits = MobiSys::DateTimeUtils.dateDifferenceInDays(party.dob, forwardPolicyIssueDt)
        elsif "MONTH" == dtd.maxValueUnits
          ageInToUnits = MobiSys::DateTimeUtils.dateDifferenceInMonths(party.dob, forwardPolicyIssueDt)
        end
      end
      productDefinitionTable, flag = self.checkDefinitionTableRange2(dtd.attainedAgeFrom,dtd.attainedAgeTo,ageInFromUnits,ageInToUnits,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("attainedAge") + "(" + dtd.attainedAgeFrom.to_s + "-" + dtd.attainedAgeTo.to_s + ")" if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end
  end
end

class ATTAINEDAGE < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.attainedAge and dtd.attainedAge != ""
      if party.age.to_s != ""
        productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.attainedAge,party.age,productDefinitionTable,dtd,flag)
      end  
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("attainedAge") + " " + dtd.attainedAge.to_s if flag  
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class COMPUTEDFIELD < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    #puts "computedField DT-> #{dtd.computedField} normal -> #{quotation.additionalField}"
    if dtd.computedField and dtd.computedField != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.computedField,quotation.additionalField,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("computedField") + " " + dtd.computedField.to_s if flag  
      return productDefinitionTable, flag
    else   
      return productDefinitionTable, flag
    end  
  end
end

class COMPUTEDFIELDRANGE < RangeValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.computedFieldFrom and dtd.computedFieldFrom != "" and dtd.computedFieldTo and dtd.computedFieldTo != ""
      productDefinitionTable, flag = self.checkDefinitionTableRange1(dtd.computedFieldFrom,dtd.computedFieldTo,quotation.additionalField,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("computedField") + "(" + dtd.computedFieldFrom.to_s + "-" + dtd.computedFieldTo.to_s + ")" if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end     
  end
end

class OCCUPATIONCLASS < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    partyEmployment = party.PartyEmploymentList[0]
    if dtd.occupationClass and dtd.occupationClass != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.occupationClass,partyEmployment.occupationCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("occupationCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.occupationClass.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end     
  end
end

class CURRENCYCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.currencyCd.to_s !=""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.currencyCd,quotationProduct.currencyCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("currencyCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.currencyCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class PLANCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.planCd and dtd.planCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.planCd,quotationProduct.planCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("planCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.planCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end     
  end
end

class ROLECD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.roleCd and dtd.roleCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.roleCd,party.roleCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("roleCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.roleCd.to_s) if flag
      return productDefinitionTable, flag
    else
    end
    return productDefinitionTable, flag
  end
end

class TOPUPTYPECD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.topUpTypeCd and dtd.topUpTypeCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.topUpTypeCd,quotationProduct.topUpTypeCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("topUpTypeCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.topUpTypeCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end  
  end
end

class RELATIONCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.relationCd and dtd.relationCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.relationCd,party.relationCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("relationCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.relationCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end  
  end
end

class INDUSTRYCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.industryCd and dtd.industryCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.industryCd,party.industryCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("industryCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.industryCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class CITIZENSHIPCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.citizenshipCd and dtd.citizenshipCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.citizenshipCd,party.citizenshipCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("citizenshipCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.citizenshipCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class INTIMATIONSOURCECD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.intimationSourceCd and dtd.intimationSourceCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.intimationSourceCd,quotation.intimationSourceCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("intimationSourceCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.intimationSourceCd.to_s) if flag
      return productDefinitionTable, flag
    else   
      return productDefinitionTable, flag
    end  
  end
end

class POLICYYEAR < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.policyYear and dtd.policyYear != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.policyYear,quotation.policyYear,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("policyYear") + " " + dtd.policyYear.to_s if flag
      return productDefinitionTable, flag
    else  
      return productDefinitionTable, flag
    end  
  end
end

class SMOKER < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.smoker and dtd.smoker != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.smoker,party.smoker,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("smoker") + " " + dtd.smoker.to_s if flag
      return productDefinitionTable, flag
    else  
      return productDefinitionTable, flag
    end  
  end
end

class SARANGE < RangeValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.saFrom and dtd.saFrom != "" and dtd.saTo and dtd.saFrom != ""
      productDefinitionTable, flag = self.checkDefinitionTableRange1(dtd.saFrom,dtd.saTo,quotationProduct.baseSumAssured,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("baseSumAssured") + "(" + dtd.saFrom.to_s + "-" + dtd.saTo.to_s + ")" if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class SA < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.sa.to_s != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.sa,quotationProduct.baseSumAssured,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("baseSumAssured") + " " + dtd.sa.to_s if flag
      return productDefinitionTable, flag
    else  
      return productDefinitionTable, flag
    end  
  end
end

class ILLUSTRATIONRATERANGE < RangeValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.illustrationRateFrom.to_s != "" and dtd.illustrationRateTo.to_s != ""
      productDefinitionTable, flag = self.checkDefinitionTableRange1(dtd.illustrationRateFrom,dtd.illustrationRateTo,quotationProduct.illustrationRate,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("illustrationRate") + "(" + dtd.illustrationRateFrom.to_s + "-" + dtd.illustrationRateTo.to_s + ")" if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class ILLUSTRATIONRATE < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.illustrationRate.to_s != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.illustrationRate,quotationProduct.illustrationRate,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("illustrationRate") + " " + dtd.illustrationRate.to_s if flag
      return productDefinitionTable, flag
    else  
      return productDefinitionTable, flag
    end  
  end
end

class COVERAGECOUNTRYCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.countryCd and dtd.countryCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.countryCd,party.coverageCountryCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("coverageCountryCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.countryCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class COVERAGECITYCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.cityCd and dtd.cityCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.cityCd,party.coverageCityCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("coverageCityCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.cityCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class ADDTNFIELD1 < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.addtnField1 and dtd.addtnField1 != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.addtnField1,quotationProduct.addtnField1,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("addtnField1") + " " + dtd.addtnField1.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class ADDTNFIELD2 < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.addtnField2 and dtd.addtnField2 != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.addtnField2,quotationProduct.addtnField2,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("addtnField2") + " " + dtd.addtnField2.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class ADDTNFIELD3 < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.addtnField3 and dtd.addtnField3 != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.addtnField3,quotationProduct.addtnField3,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("addtnField3") + " " + dtd.addtnField3.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class PARTYTYPECD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.partyTypeCd and dtd.partyTypeCd != ""
      proposerParty = quotation.getPartyByRole("PROPOSER")
      partyTypeCd = ""
      partyTypeCd = proposerParty.partyTypeCd if proposerParty && proposerParty.partyTypeCd.to_s != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.partyTypeCd,partyTypeCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("partyTypeCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.partyTypeCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class PLANPRODUCTCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.planProductCd and dtd.planProductCd != ""
      quotationBaseProduct = quotation.getBaseProduct
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.planProductCd,quotationBaseProduct.productId,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("planProductCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.planProductCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class PPTERM < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.ppTerm and dtd.ppTerm != ""
      quotationBaseProduct = quotation.getBaseProduct
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.ppTerm,quotationBaseProduct.premiumPayingTerm,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("premiumPayingTerm") + " " + dtd.ppTerm.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class FUNDCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.fundCd and dtd.fundCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.fundCd,quotationProduct.fundCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("fundCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.fundCd.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class COUNTRYCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.countryCd
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.countryCd,party.coverageCountryCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("countryCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.countryCd.to_s) if flag
      return productDefinitionTable, flag
    else
    end
    return productDefinitionTable, flag
  end
end

class CITYCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.cityCd
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.cityCd,party.coverageCityCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("cityCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.cityCd.to_s) if flag
    else
    end
    return productDefinitionTable,flag
  end
end

class PROPOSERAGE < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    proposer = quotation.getPartyByRole("PROPOSER")
    if proposer && proposer.age.to_s != "" && dtd.proposerAge and dtd.proposerAge != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.proposerAge,proposer.age,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("proposerAge") + " " + dtd.proposerAge.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end  

class PROPOSERAGERANGE < RangeValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    proposer = quotation.getPartyByRole("PROPOSER")
    if proposer && proposer.age.to_s != "" && dtd.proposerAgeFrom and dtd.proposerAgeFrom != "" and dtd.proposerAgeTo and dtd.proposerAgeTo != ""
      productDefinitionTable, flag = self.checkDefinitionTableRange1(dtd.proposerAgeFrom,dtd.proposerAgeTo,proposer.age,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("proposerAge") + "(" + dtd.proposerAgeFrom.to_s + "-" + dtd.proposerAgeTo.to_s + ")" if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end  
  end
end

class PRIMARYAGE < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    primary = quotation.getPartyByRole("PRIMARY")
    if primary && primary.age.to_s != "" && dtd.primaryAge.to_s != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.primaryAge, primary.age, productDefinitionTable ,dtd, flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("primaryAge") + " " + dtd.primaryAge.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class PRIMARYAGERANGE < RangeValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    primary = quotation.getPartyByRole("PRIMARY")
    if primary && primary.age.to_s != "" && dtd.primaryAgeFrom.to_s != "" && dtd.primaryAgeTo.to_s != ""
      productDefinitionTable, flag = self.checkDefinitionTableRange1(dtd.primaryAgeFrom, dtd.primaryAgeTo, primary.age, productDefinitionTable, dtd, flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("primaryAge") + "(" + dtd.primaryAgeFrom.to_s + "-" + dtd.primaryAgeTo.to_s + ")" if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end  
  end
end

class JOINTLIFEAGE < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    jointLife = quotation.getPartyByRole("JOINT")
    if jointLife && jointLife.age.to_s != "" && dtd.jointLifeAge.to_s != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.jointLifeAge, jointLife.age, productDefinitionTable ,dtd, flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("jointLifeAge") + " " + dtd.jointLifeAge.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class JOINTLIFEAGERANGE < RangeValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    jointLife = quotation.getPartyByRole("JOINT")
    if jointLife && jointLife.age.to_s != "" && dtd.jointLifeAgeFrom.to_s != "" && dtd.jointLifeAgeTo.to_s != ""
      productDefinitionTable, flag = self.checkDefinitionTableRange1(dtd.jointLifeAgeFrom, dtd.jointLifeAgeTo, jointLife.age, productDefinitionTable, dtd, flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("jointLifeAge") + "(" + dtd.jointLifeAgeFrom.to_s + "-" + dtd.jointLifeAgeTo.to_s + ")" if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end  
  end
end

class PPTERMRANGE < RangeValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.ppTermFrom and dtd.ppTermFrom != "" and dtd.ppTermTo and dtd.ppTermTo != ""
      quotationBaseProduct = quotation.getBaseProduct
      productDefinitionTable, flag = self.checkDefinitionTableRange1(dtd.ppTermFrom,dtd.ppTermTo,quotationBaseProduct.premiumPayingTerm,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("premiumPayingTerm") + "(" + dtd.ppTermFrom.to_s + "-" + dtd.ppTermTo.to_s + ")" if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end  
  end
end

class QUOTADDTNLFIELD1 < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.quotAddtnlField1 and dtd.quotAddtnlField1.to_s != ""
      if dtd.quotAddtnlField1.to_s.include?(',')
        productDefinitionTable, flag = ValueInComparator.checkDefinitionTableValueIn1(dtd.quotAddtnlField1,quotation.quotAddtnlField1,productDefinitionTable,dtd,flag) 
      else
        productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.quotAddtnlField1,quotation.quotAddtnlField1,productDefinitionTable,dtd,flag)
      end
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotAddtnlField1") + " " + dtd.quotAddtnlField1.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class QUOTADDTNLFIELD2 < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.quotAddtnlField2 and dtd.quotAddtnlField2.to_s != ""
      if dtd.quotAddtnlField2.to_s.include?(',')
        productDefinitionTable, flag = ValueInComparator.checkDefinitionTableValueIn1(dtd.quotAddtnlField2,quotation.quotAddtnlField2,productDefinitionTable,dtd,flag)
      else
        productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.quotAddtnlField2,quotation.quotAddtnlField2,productDefinitionTable,dtd,flag)
      end
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotAddtnlField2") + " " + dtd.quotAddtnlField2.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class QUOTADDTNLFIELD3 < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.quotAddtnlField3 and dtd.quotAddtnlField3.to_s != ""
      if dtd.quotAddtnlField3.to_s.include?(',')
        productDefinitionTable, flag = ValueInComparator.checkDefinitionTableValueIn1(dtd.quotAddtnlField3,quotation.quotAddtnlField3,productDefinitionTable,dtd,flag)
      else
        productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.quotAddtnlField3,quotation.quotAddtnlField3,productDefinitionTable,dtd,flag)
      end
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotAddtnlField3") + " " + dtd.quotAddtnlField3.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end  

class QUOTADDTNLFIELD4 < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.quotAddtnlField4 and dtd.quotAddtnlField4.to_s != ""
      if dtd.quotAddtnlField4.to_s.include?(',')
        productDefinitionTable, flag = ValueInComparator.checkDefinitionTableValueIn1(dtd.quotAddtnlField4,quotation.quotAddtnlField4,productDefinitionTable,dtd,flag)
      else
        productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.quotAddtnlField4,quotation.quotAddtnlField4,productDefinitionTable,dtd,flag)
      end
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotAddtnlField4") + " " + dtd.quotAddtnlField4.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end 

class QUOTPARTYADDTNFIELD1 < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.quotPartyAddtnField1.to_s != "" && party != nil
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.quotPartyAddtnField1, party.quotPartyAddtnField1, productDefinitionTable, dtd, flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotPartyAddtnField1") + " " + dtd.quotPartyAddtnField1.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class QUOTPARTYADDTNFIELD2 < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.quotPartyAddtnField2.to_s != "" && party != nil
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.quotPartyAddtnField2, party.quotPartyAddtnField2, productDefinitionTable, dtd, flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotPartyAddtnField2") + " " + dtd.quotPartyAddtnField2.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class QUOTPARTYADDTNFIELD3 < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.quotPartyAddtnField3.to_s != "" && party != nil
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.quotPartyAddtnField3, party.quotPartyAddtnField3, productDefinitionTable, dtd, flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotPartyAddtnField3") + " " + dtd.quotPartyAddtnField3.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class QUOTPARTYADDTNFIELD4 < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.quotPartyAddtnField4.to_s != "" && party != nil
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.quotPartyAddtnField4, party.quotPartyAddtnField4, productDefinitionTable, dtd, flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("quotPartyAddtnField4") + " " + dtd.quotPartyAddtnField4.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class NATUREOFDUTYID < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.natureOfDutyId and dtd.natureOfDutyId != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.natureOfDutyId,party.natureOfDuty,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("natureOfDuty") + " " + MobiSys::BrowserHelper.getLabel(dtd.natureOfDutyId.to_s) if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class ANNUALINCOME < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.annualIncome and dtd.annualIncome != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.annualIncome,party.annualIncome,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("annualIncome") + " " + dtd.annualIncome.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class MONTHLYINCOME < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.monthlyIncome and dtd.monthlyIncome != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.monthlyIncome,party.monthlyIncome,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("monthlyIncome") + " " + dtd.monthlyIncome.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class PARENTAGENCYID < ValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.parentAgencyId.to_s != ""
      productDefinitionTable, flag = self.checkDefinitionTableValue1(dtd.parentAgencyId,quotation.parentAgency,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("parentAgency") + " " + dtd.parentAgencyId.to_s if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end    
  end
end

class MARITALSTATUSCD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.maritalStatusCd and dtd.maritalStatusCd != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.maritalStatusCd,party.maritalStatusCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("maritalStatusCd") + " " + MobiSys::BrowserHelper.getLabel(dtd.maritalStatusCd.to_s) if flag
      return productDefinitionTable, flag
    else  
      return productDefinitionTable, flag
    end  
  end
end

class CHANNELID < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.channelId.to_s != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.channelId,quotation.channel,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("channelId") + " " + MobiSys::BrowserHelper.getLabel(dtd.channelId.to_s) if flag
      return productDefinitionTable, flag
    else  
      return productDefinitionTable, flag
    end  
  end
end

class SUBCHANNELID < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.subChannelId.to_s != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.subChannelId,quotation.subChannel,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("subChannelId") + " " + MobiSys::BrowserHelper.getLabel(dtd.subChannelId.to_s) if flag
      return productDefinitionTable, flag
    else  
      return productDefinitionTable, flag
    end  
  end
end

class RIDERPLANOPTIONS < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    riders = quotation.getRiders
    if dtd.riderProductId.to_s != "" #and not riders.empty?
      riderProductIdList = dtd.riderProductId.split(",")
      isMatched = false
      riderProductIdList.each do |riderProductId|
        riders.each do |rider|
          isMatched = false
          if riderProductId == rider.productId
            isMatched = true
            if dtd.riderPlanOptions.to_s != '' 
              if dtd.riderPlanOptions == rider.productPlanOptionCd
                isMatched = true
                break
              else
                isMatched = false  
              end
            end            
          end
          break if isMatched
        end   
        if isMatched
          productDefinitionTable = dtd
          flag = true            
        else
          flag = false   
        end
        if flag
          quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("riderProductId") + " ( " + MobiSys::BrowserHelper.getLabel(dtd.riderProductId.to_s)  + " )"
          if dtd.riderPlanOptions.to_s != ''
            quotation.entityDesc += " " + MobiSys::BrowserHelper.getLabel("riderPlanOptions") + " ( " + MobiSys::BrowserHelper.getLabel(dtd.riderPlanOptions.to_s) + " )"
          end  
        end
        return productDefinitionTable, flag     
      end
    else
      return productDefinitionTable, flag
    end        
  end
end

class RIDERPRODUCTIDNOTIN < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.riderProductIdNotIn.to_s != ""
      riders = quotation.getRiders
      if riders.size > 0
        riders.each do |rider|
          if rider.productId.to_s != ''
            productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.riderProductIdNotIn,rider.productId.to_s,productDefinitionTable,dtd,flag) 
            if flag
              flag = false
              quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("riderProductIdNotIn") + " " + MobiSys::BrowserHelper.getLabel(dtd.riderProductIdNotIn.to_s)
              break
            else  
              flag = true
            end
          end
        end
        return productDefinitionTable, flag
      else
        return productDefinitionTable, true
      end
    else
      return productDefinitionTable, flag
    end
  end
end


class PAYMENTINSTRUCTIONTYPECD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.paymentInstructionTypeCd.to_s != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.paymentInstructionTypeCd,quotation.paymentInstructionTypeCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("paymentInstructionTypeCd") + "(" + MobiSys::BrowserHelper.getLabel(dtd.paymentInstructionTypeCd.to_s) + ")" if flag
      return productDefinitionTable, flag
    else  
      return productDefinitionTable, flag
    end  
  end
end

class INSURANCETYPECD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.insuranceTypeCd.to_s != ""
      productDefinitionTable, flag = self.checkDefinitionTableValueIn1(dtd.insuranceTypeCd,quotation.insuranceTypeCd,productDefinitionTable,dtd,flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("insuranceTypeCd") + "(" + MobiSys::BrowserHelper.getLabel(dtd.insuranceTypeCd.to_s) + ")" if flag
      return productDefinitionTable, flag
    else  
      return productDefinitionTable, false
    end  
  end
end

class DEPENDENTRIDERROLECD < ValueInComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    riders = quotation.getRiders
    if dtd.riderProductId.to_s != "" #and not riders.empty?
      riderProductIdList = dtd.riderProductId.split(",")
      isMatched = false
      riderProductIdList.each do |riderProductId|
        riders.each do |rider|
          isMatched = false
          if riderProductId == rider.productId
            isMatched = true
            if dtd.dependentRiderRoleCd.to_s != '' && rider.partyRoleCd != ''
              if dtd.dependentRiderRoleCd == rider.partyRoleCd
                isMatched = true
                break
              else
                isMatched = false  
              end
            end            
          end
          break if isMatched
        end  
        if isMatched
          productDefinitionTable = dtd
          flag = true            
        else
          flag = false   
        end
        if flag
          quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("riderProductId") + " ( " + MobiSys::BrowserHelper.getLabel(dtd.riderProductId.to_s)  + " )"
          if dtd.dependentRiderRoleCd.to_s != ''
            quotation.entityDesc += " " + MobiSys::BrowserHelper.getLabel("dependentRiderRoleCd") + " ( " + MobiSys::BrowserHelper.getLabel(dtd.dependentRiderRoleCd.to_s) + " )"
          end  
        end
        return productDefinitionTable, flag     
      end
    else
      return productDefinitionTable, flag
    end        
  end
end

class MONTHLYINCOMERANGE < RangeValueComparator
  def self.compare(quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
    if dtd.monthlyIncomeFrom and dtd.monthlyIncomeFrom != "" and dtd.monthlyIncomeTo and dtd.monthlyIncomeTo != ""
      productDefinitionTable, flag = self.checkDefinitionTableRange1(dtd.monthlyIncomeFrom, dtd.monthlyIncomeTo, party.monthlyIncome, productDefinitionTable, dtd, flag)
      quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel("monthlyIncome") + "(" + dtd.monthlyIncomeFrom.to_s + "-" + dtd.monthlyIncomeTo.to_s + ")" if flag
      return productDefinitionTable, flag
    else
      return productDefinitionTable, flag
    end 
  end 
end
