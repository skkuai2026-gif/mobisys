require 'LabelValue/label_value'
module CommonFunctions
  def maskDecimal(number,round=2)
    dec='.'
    sep=','
    begin
      num = MobiSys::Math.roundNearest(number,round) if number.to_s != ""
    rescue
      num = number       
    end
    num = number unless number
    num = num.to_f if num.to_s == ""
    num = num.to_s.sub(/\./, dec)
    dec = Regexp.escape dec
    maskedNum = num.reverse.gsub(/(\d{3})(?=\d)(?!\d*#{dec})/, "\\1#{sep}").reverse
    
    if round==0
      if !((maskedNum.to_s).include?("."))
        return maskedNum.to_s+".00" 
      else
        return maskedNum.to_s.split('.')[0]
      end
    end
    return maskedNum
  end
  alias_method :getFormatDoubleTwoDecimalWithComma,:maskDecimal
  
  #Swati Ahire 20-06-2014
  #Method to get lookup decsription based on lookup key and code
  def getLookupValue(lookupKey,lookupDataCd)
    lookup_desc = ""
    lookup_val = Lookupvalue.find( :first, :conditions => {{ :name => 'key'} => lookupKey, {:name => 'cd'} => lookupDataCd}, :op => 'AND')
    lookup_desc = getLabelValue(lookup_val.desc.to_s,"EN") if lookup_val
    return lookup_desc
  end

    def getStateValue(stateCd)
    statedesc = ""
    stateval = PincodeCityStateCountryMapping.find( :first, :conditions => {{ :name => 'stateCd'} => stateCd}, :op => 'AND')
    statedesc = stateval.stateDesc if stateval
    return statedesc
  end

  def getCityValue(cityCd)
    citydesc = ""
    cityval = PincodeCityStateCountryMapping.find( :first, :conditions => {{ :name => 'cityCd'} => cityCd}, :op => 'AND')
    citydesc = cityval.cityDesc if cityval
    return citydesc
  end

  
  
  #Swati Ahire 12-06-2014
  #Method to get occupation code desc, natureofduty desc and occupation class desc based on occupation code, natureofduty id, 
  #occupation class id and element name for which description is to be returned
  def getIndustryNatureOfDuty(occupationCd,natureOfDutyId,occupationClassId,columnType)
    occupationArr = Array.new
    occValues = IndustryNatureofdutyMap.find( :first, :conditions => {{ :name => 'industryId'} => occupationCd.to_s, {:name => 'natureOfDutyId'} => natureOfDutyId.to_s, {:name => 'occupationClassId'} => occupationClassId.to_s}, :op => 'AND')
    if occValues.to_s != ""
      return occValues.industryDesc if columnType == "occupationCd"
      return occValues.natureOfDutyDesc if columnType == "natureOfDuty"
      return occValues.occupationClassDesc if columnType == "occupationClass"
    else
      return ""
    end
  end
  
  #Swati Ahire 12-06-2014
  #Method to get date format in supplied date format
  def formatDate(date, format)
    time = Time.parse(date.to_s)
    newDateTime = time.strftime(format)
    return newDateTime
  end    

  def getFormatedSystemDate(format)
    time = Time.now
    newDateTime = time.strftime(format)
    return newDateTime
  end


  def formatDoubleTwoDecimal(strToFormat) 
    return MobiSys::UIGenUtilHelper.maskDecimal(strToFormat)
      # if strToFormat == nil || strToFormat == ""
      #     strToFormat = "";
      # else
      #   begin             
      #     if(!strToFormat.include?(","))
      #       strToFormat = CommonUtil.getFormattedDouble(strToFormat, "##,##,##,###.##");
      #     else
      #       strToFormat = CommonUtil.getFormattedDouble(strToFormat.replace(",", ""), "##,##,##,###.##");
      #     end
      #     if(strToFormat.include?(".") && strToFormat.subSequence(strToFormat.indexOf(".")+1,strToFormat.length).length<2)
      #       return strToFormat = strToFormat+"0";
      #     elsif(!strToFormat.include?("."))
      #       return strToFormat+".00";
      #     end
      #    rescue
      #       return strToFormat;
      #    end
      # end
      # return strToFormat;
  end

  def getFormatDoubleTwoDecimalWithCommaEapp(number,round=2)
      dec='.'
      sep=','
      begin
        num = MobiSys::Math.roundNearest(number,round) if number.to_s != ""
      rescue
        num = number       
      end
      num = number unless number
      num = num.to_f if num.to_s == ""
      num = num.to_s.sub(/\./, dec)
      dec = Regexp.escape dec
      maskedNum = num.reverse.gsub(/(\d{3})(?=\d)(?!\d*#{dec})/, "\\1#{sep}").reverse
     
      if round==0
        if !((maskedNum.to_s).include?("."))
          return maskedNum.to_s+".00" 
        else
          return maskedNum.to_s.split('.')[0]
        end
      end
      return maskedNum
  end

  def containsFundType(fundList, linkedHashMap, fundDOHashMap, searchText)
    fundList.each do |fd|
      if fd.allocationPerc != nil && fundDOHashMap.has_key?(fd.getFundCd)
        if fundDOHashMap[fd.getFundCd].fundTypeCd != nil && fundDOHashMap[fd.getFundCd].fundTypeCd == searchText
          return true;
        end
      end
    end
    return false;
  end

  def formatDouble(strToFormat)
    return MobiSys::UIGenUtilHelper.maskDecimal(strToFormat,0)
    # if(strToFormat == nil)
    #   strToFormat = "";
    # else
    #   begin
    #     strToFormat = CommonUtil.getFormattedDouble(strToFormat, "##,##,##,###.##################");
    #   rescue
    #      return strToFormat;
    #   end
    # end
    # return strToFormat;
  end


      def formatDoubleEapp(strToFormat)
   return MobiSys::UIGenUtilHelper.maskDecimal(strToFormat,0)
    if(strToFormat == nil)
      strToFormat = "";
    else
      begin
        strToFormat = CommonUtil.getFormattedDouble(strToFormat, "##,##,##,###.##################");
      rescue
         return strToFormat;
      end
    end
    return strToFormat;
    end 
end

module MobiSys
	class UIGenUtilHelper
		include Singleton
		def self.getLabelValue(labelCd, lang)
			labelValue = LabelValue.getLabel(labelCd, lang.downcase!)
			if labelValue == nil or (labelValue and labelValue == "")
				labelValue = labelCd 
			end
			return labelValue.to_s.force_encoding('UTF-8')
		end
		extend CommonFunctions
	end	
end