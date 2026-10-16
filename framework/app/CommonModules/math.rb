require 'time'

class Numeric
  def rnd(index)
    self_f = self.class.to_s == "BigDecimal" ? self.to_f : self
    rndValue = self_f
    strValue = self_f.to_s
    if strValue.include?('e')
      exp = strValue[strValue.index("e")+2..-1].to_i
      if strValue.include?('e-')
        d_length = strValue[strValue.index(".")+1..strValue.index("e")-1].to_s.length
        exp = exp + d_length
      end
      strValue = "%.#{exp.to_i}f" % self
    end
    arr = strValue.split(".")
    if arr.length > 1 and arr[1].length > index
      strValue << "1"
      floatValue = strValue.to_f
      rndValue = floatValue.round(index)
    end
    rndValue
  end
end

class String
  def substring(startIndex,endIndex=nil)
    if endIndex
      self[startIndex..endIndex-1]
    else
      self[startIndex..-1]
    end
  end

  def indexOf(needle)
    needleIndex = self.index(needle)
    needleIndex = needleIndex == nil ? -1 : needleIndex
  end

  def numeric?
    Float(self) != nil rescue false
  end
end

module MobiSys

  module Math
    
    def self.ceiling(number, significance=0)
      if significance == 0
        return number
      else
      significance = significance.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && $rhoconfig[:useBigDecimal]
        number = number.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && number.class.to_s == "Float" && !number.nan? && $rhoconfig[:useBigDecimal]
        return ((number % significance) == 0 ? number : (number - (number % significance) + significance))
      end
    end
    
    def self.floor(number, significance=0)
      if significance == 0
        return number
      else
      significance = significance.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && $rhoconfig[:useBigDecimal]
        number = number.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && number.class.to_s == "Float" && !number.nan? && $rhoconfig[:useBigDecimal]
        return ((number % significance) == 0 ? number : (number - (number % significance)))
      end
    end
    
    def self.round(number, precision=0)
	  return number.to_i if precision==0
      precision = precision.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && $rhoconfig[:useBigDecimal]
      number = number.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && number.class.to_s == "Float" && !number.nan? && $rhoconfig[:useBigDecimal]
      result = (number.rnd(precision))
      result = 0 if result.to_s == "NaN"
      if defined?(BigDecimal) && Float.method_defined?(:to_d) && $rhoconfig[:useBigDecimal]
        return result.to_d
      else
        return result
      end
    end
    
    def self.toInt(number)
      return number.to_i
    end
    
    def self.pow(a,b)
      a = a.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && a.class.to_s == "Float" && !a.nan? && $rhoconfig[:useBigDecimal]
      b = b.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && b.class.to_s == "Float" && !b.nan? && $rhoconfig[:useBigDecimal]
      return a ** b
    end
    
    def self.roundUp(number, precision)
      return 0.0 unless number
      precision = precision.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && $rhoconfig[:useBigDecimal]
      number = number.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && number.class.to_s == "Float" && !number.nan? && $rhoconfig[:useBigDecimal]
      if defined?(BigDecimal) && Float.method_defined?(:to_d) && $rhoconfig[:useBigDecimal]
        return ((number * 10**precision).ceil.to_d / 10**precision).to_d
      else
        return ((number * 10**precision).ceil.to_f / 10**precision)
      end
    end
    
    def self.roundDown(number, precision)
      return 0.0 unless number
      precision = precision.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && $rhoconfig[:useBigDecimal]
      number = number.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && number.class.to_s == "Float" && !number.nan? && $rhoconfig[:useBigDecimal]
      if defined?(BigDecimal) && Float.method_defined?(:to_d) && $rhoconfig[:useBigDecimal]
        return ((number * 10**precision).floor.to_d / 10**precision).to_d
      else
        return ((number * 10**precision).floor.to_f / 10**precision)
      end
    end
    
    def self.roundNearest(number,precision=0)
      return 0.0 unless number
      precision = precision.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && $rhoconfig[:useBigDecimal]
      number = number.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && number.class.to_s == "Float" && !number.nan? && $rhoconfig[:useBigDecimal]
      result = (number.rnd(precision))
      result = 0 if result.to_s == "NaN"
      if defined?(BigDecimal) && Float.method_defined?(:to_d) && $rhoconfig[:useBigDecimal]
        return result.to_d
      else
        return result
      end
    end
    
    def self.mround(number,precision=1)
      return 0.0 unless number
      precision = precision.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && $rhoconfig[:useBigDecimal]
      number = number.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && number.class.to_s == "Float" && !number.nan? && $rhoconfig[:useBigDecimal]
      if defined?(BigDecimal) && Float.method_defined?(:to_d) && $rhoconfig[:useBigDecimal]
        return ((number/precision).round.to_d * precision).to_d
      else
        return ((number/precision).round * precision)
      end
    end
    
    def self.roundNearestDecimal(number,precision=0)
      return 0.0 unless number
      precision = precision.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && $rhoconfig[:useBigDecimal]
      number = number.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && number.class.to_s == "Float" && !number.nan? && $rhoconfig[:useBigDecimal]
      result = (number.rnd(precision))
      result = 0 if result.to_s == "NaN"
      if defined?(BigDecimal) && Float.method_defined?(:to_d) && $rhoconfig[:useBigDecimal]
        return result.to_d
      else
        return result
      end
    end
    
    def self.negativeSign(number)
      return 0.0 unless number
      number = number.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && number.class.to_s == "Float" && !number.nan? && $rhoconfig[:useBigDecimal]
      return (number * -1)
    end

    #method to format amount as per currency
    def self.getAmountFormat(amount,currencyCd)
      formattedAmountStr = ""

      if currencyCd != nil
        currencyFormat = nil
        lookupValueOfCurrencyMaster = Lookupvalue.find(:first, :conditions =>  {
                        {
                            :name => 'key',
                        } => 'CURRENCYMASTER',
                        {
                            :name => 'cd',
                        } => currencyCd
                    },
                    :op => 'AND'
                )

                if lookupValueOfCurrencyMaster != nil
                  #additional field 1 corresponds to the decimal string format
                    currencyFormat = lookupValueOfCurrencyMaster.additionalField1 if lookupValueOfCurrencyMaster.additionalField1 != nil
                end

                currencyFormat = $rhoconfig[:number_format_pattern].to_s if currencyFormat == nil

                formattedAmountStr = MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(amount,2), currencyFormat)
      end

      return formattedAmountStr
    end
  end
  
  module DateTimeUtils
    def self.dateDifferenceInDays(date1, date2)
      if date2.is_a?(String) && date2.to_s != ""
        date2 = DateTime.strptime(date2,'%Y-%m-%d')
      end 
      if date1.is_a?(String) && date1.to_s != ""
        date1 = DateTime.strptime(date1,'%Y-%m-%d')
      end
      if date1.to_s != "" && date2.to_s != ""
        return date2.to_date.mjd - date1.to_date.mjd
      else
        return 0
      end
    end
    
    def self.dateDifferenceInMonths(date1, date2)
      if date2.is_a?(String) && date2.to_s != ''
        date2 = DateTime.strptime(date2,'%Y-%m-%d')
      end 
      if date1.is_a?(String) && date1.to_s != ''
        date1 = DateTime.strptime(date1,'%Y-%m-%d')
      end
      if date1.to_s != '' && date2.to_s != ''
        return (date2.year * 12 + date2.month) - (date1.year * 12 + date1.month)
      else
        return 0
      end
    end

    def self.dateDifferenceInYears(date1, date2)
      if date2.is_a?(String)
        date2 = DateTime.strptime(date2,'%Y-%m-%d')
      end 
      if date1.is_a?(String)
        date1 = DateTime.strptime(date1,'%Y-%m-%d')
      end
      return date2.year - date1.year
    end    
    
    def self.year(date)
      dtDate = date
      if date.is_a?(String)
        dtDate = DateTime.strptime(date,'%Y-%m-%d')
      end  
      return dtDate.year
    end
    
    def self.month(date)
      dtDate = date
      if date.is_a?(String)
        dtDate = DateTime.strptime(date,'%Y-%m-%d')
      end  
      return dtDate.month
    end
    
    def self.day(date)
      dtDate = date
      if date.is_a?(String)
        dtDate = DateTime.strptime(date,'%Y-%m-%d')
      end  
      return dtDate.day
    end
    
    #Returns string in dd/mm/yyyy format
    def self.formatDate(date)
      return date.strftime("%d/%m/%Y")
    end

    def self.getForwardDateByMonths(date, months)
      if date.is_a?(String) && date.to_s != ""
        date = DateTime.strptime(date,'%Y-%m-%d') >> months.to_i
      end
      return date 
    end

    def self.getBackwardDateByMonths(date, months)
      if date.is_a?(String) && date.to_s != ""
        date = DateTime.strptime(date,'%Y-%m-%d') << months.to_i
      end
      return date
    end

    def self.forwardSqlDateByDays(date, days)
      if date.to_s != ""
        date = DateTime.strptime(date.to_s,'%Y-%m-%d') + days.to_i
      end
      return date
    end

    def self.forwardSqlDateByMonths(date, months)
      if date.to_s != ""
        date = DateTime.strptime(date.to_s,'%Y-%m-%d') >> months.to_i
      end
      return date
    end

    def self.forwardSqlDateByYear(date, years)
      if date.to_s != ""
        date = DateTime.strptime(date.to_s,'%Y-%m-%d').next_year(years.to_i)
      end
      return date
    end

    def self.convertDateFormatJavaToRuby(onlineFormat)
      if onlineFormat.to_s != ""
        datetime_format_map = {
          "MMMM"=> "%B", # January - Full month name
          "MMM" => "%b", # Jan - Shortened month name
          "MM"  => "%m", # "01" - Numbered month of the year (01..12)
          "dd"  => "%d", # "15" - Day of the month (01..31)
          "D"   => "%j", # "123" - Day of the year (001..366)
          "EEEE"=> "%A", # "Monday" - Full weekday name
          "EEE" => "%a", # "Mon" - Shortened weekday name
          "u"   => "%w", # "1" - The numeric day of the week (0..6)
          "w"   => "%U", # "22" - Numeric week number in the year (0..53) [starting with the first Sunday]
          ""    => "%W", # "22" - Numeric week number in the year (0..53) [starting with the first Monday]
          "yyyy"=> "%Y", # "2023" - Four digit year
          "yy"  => "%y", # "99" - Two-digit year (00..99)
          "H"   => "%H", # "18" - Hour of the day (military time) (00..23)
          "h"   => "%I", # "08" - Hour of the day (12-hour clock) (01..12)
          "m"   => "%M", # "15" - Minute of the hour (0..59)
          "s"   => "%S", # "30" - Second of the minute (0..59)
          "a"   => "%p", # "PM" - AM or PM
          "z"   => "%Z" # "Central Time (US & Canada)" - Time zone name
        }
        date_separators = ["/"," ",".",","]
        offineFormat = ""
        date_separators.each do |x| 
          splittedOnlineFormat = onlineFormat.split(x.to_s)
          if !splittedOnlineFormat.empty? && splittedOnlineFormat.length > 1
            splittedOnlineFormat.each do |y|
              datetime_format_map.each do |key, value|
                offineFormat << value.to_s + x.to_s if key.to_s == y.to_s
              end
            end
          end
        end
        return offineFormat
      end
    end
  end
end

begin 
    require 'CommonModules/math_company'
rescue LoadError => e
    puts 'math_company not included'
end