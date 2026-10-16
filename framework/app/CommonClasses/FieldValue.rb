module MobiSys
  module DataObjects
    class FieldValue
      attr_accessor :fieldCd
      attr_accessor :fieldValue
      attr_accessor :fieldLabel
      attr_accessor :sortOrder
      
      def initialize(fieldCd=nil, fieldValue=nil, fieldLabel=nil, sortOrder=nil)
        @fieldCd = fieldCd
        @fieldValue = fieldValue
        @fieldLabel = fieldLabel
        @sortOrder = sortOrder
      end
    end
  end
end