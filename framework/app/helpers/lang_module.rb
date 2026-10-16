#encoding: UTF-8
require 'singleton'
module Commonlang
  class BaseLang
    include Singleton
    
    def init(lang)
      lang = Application.getValue('DEFAULTLOCALE').value
      resetLabels(lang)
    end

    def resetLabels(lang)
      labelValues = LabelValue.find(
      :all,
      :conditions => {
        {
        :name => "lang",
        :op => "IN"
        } =>lang
      }
      )

      @labelvalues =  Hash.new
      @labelvaluesForToolTip =  Hash.new
      @labelvaluesForExtraValue =  Hash.new

      labelValues.each do |labelvalue|
        @labelvalues[labelvalue.key.to_sym] = labelvalue.value.to_s.force_encoding("UTF-8")
        @labelvaluesForToolTip[labelvalue.key.to_sym] = labelvalue.toolTipValue.to_s.force_encoding("UTF-8")
        @labelvaluesForExtraValue[labelvalue.key.to_sym] = labelvalue.labelValueExtra.to_s.force_encoding("UTF-8")
      end

    end
    
    def getLabel(keyStr)
      labelvalue = @labelvalues[keyStr.to_sym]

      if @labelvalues.include? keyStr.to_sym
        return  labelvalue
      else
        return  keyStr.to_s
      end
    end

    def getLabelToolTipValue(keyStr)
      labelvalue = @labelvaluesForToolTip[keyStr.to_sym]

      if labelvalue!=nil
        return  labelvalue
      else
        return  keyStr.to_s
      end
    end

    def getlabelExtraValue(keyStr)
      labelvalue = @labelvaluesForExtraValue[keyStr.to_sym]

      if labelvalue!=nil
        return  labelvalue
      else
        return  keyStr.to_s
      end
    end
    
    def updateLabel(keyStr, valueStr)
      @labelvalues[keyStr.to_sym] = valueStr if keyStr != nil
    end
    
  end

end