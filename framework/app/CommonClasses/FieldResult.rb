require 'CommonClasses/FieldValue'
module MobiSys
  module DataObjects
    class FieldResult
      attr_accessor :objectName
      attr_accessor :sortOrder
      attr_accessor :inputOrder
      attr_accessor :fieldValueList
      attr_accessor :fieldResultList
      attr_accessor :hmFieldValues
      attr_accessor :id
      attr_accessor :entityTypeCd
      attr_accessor :versionID
      
      def initialize
        @fieldValueList = Array.new
        @fieldResultList = Array.new
        @hmFieldValues = Hash.new
      end
      
      def addFieldValue(fieldValueDO=nil, fieldCd=nil, fieldValue=nil, fieldLabel=nil, sortOrder=nil)
        if fieldValueDO
          @hmFieldValues[fieldValueDO.fieldCd] = fieldValueDO.fieldValue
          @fieldValueList << fieldValueDO
        else
          fieldValueDO = MobiSys::DataObjects::FieldValue.new(fieldCd, fieldValue, fieldLabel, sortOrder)
          #fieldValueDO.fieldLabel = fieldLabel
          #fieldValueDO.sortOrder = sortOrder
          #addFieldValue(fieldValueDO)
          @hmFieldValues[fieldCd] = fieldValue
          @fieldValueList << fieldValueDO  
        end
      end
      
      def addFieldResult(fieldResult)
        @fieldResultList << fieldResult
      end
      
      def getFieldNames
        fieldNames = Array.new
        @fieldValueList.each do |fieldValue|
          fieldNames << fieldValue.fieldCd
        end
        fieldNames  
      end
      
      def getFieldNamesAsString
        str = ""
        count = 0
        @fieldValueList.each do |fieldValue|
          str << "," if count > 0
          str << fieldValue.fieldCd
          count+=1
        end
        str  
      end
      
      def containsFieldInMap(fieldName)
        return @hmFieldValues.has_key?(fieldName)
      end    
      
      def getFieldValue(fieldName)
        if @hmFieldValues.has_key?(fieldName)
          return @hmFieldValues[fieldName] 
        else
          return nil
        end  
        @fieldValueList.each do |fieldValue|
          return fieldValue.fieldValue if fieldValue.fieldCd == fieldName
        end  
      end

      def getFieldValueObject(fieldName)
        return @hmFieldValues[fieldName] if @hmFieldValues.has_key? fieldName
        @fieldValueList.each do |fieldValue|
          return fieldValue.fieldValue if fieldValue.fieldCd == fieldName
        end  
      end  
      
      def getFieldValueDO(fieldName)
        @fieldValueList.each do |fieldValue|
          return fieldValue if fieldValue.fieldCd == fieldName
        end
      end   
    end
  end
end