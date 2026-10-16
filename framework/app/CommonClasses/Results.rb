require 'Quotation/UIGenUtilHelper'

class Object
  attr_accessor :deep_cloning, :deep_cloning_obj
  
  def deep_clone
    return @deep_cloning_obj if @deep_cloning
    @deep_cloning_obj = clone
    @deep_cloning_obj.instance_variables.each do |var|
      val = @deep_cloning_obj.instance_variable_get(var)
      begin
        @deep_cloning = true
        val = val.deep_clone
      rescue TypeError
        next
      ensure
        @deep_cloning = false
      end
      @deep_cloning_obj.instance_variable_set(var, val)
    end
    deep_cloning_obj = @deep_cloning_obj
    @deep_cloning_obj = nil
    deep_cloning_obj
  end
end 

module MobiSys
  module DataObjects
    class Results
      def addAttrs(attrs)
        attrs.each do |var, value|
          addAttr(var, value)
        end
      end
      
      def defineMethod(methodName,expression, replaceStr=false)
        #puts ">>>defining method: #{methodName} expression: #{expression} replaceStr: #{replaceStr}"
        begin
          if expression and expression.include? "\"" and replaceStr
            expression.gsub!(/"/,"\\\"")
          end
          expression.gsub!(/\s/,"") if replaceStr
          str = "self.send :define_singleton_method, :#{methodName} do #{expression}  end"
          #puts ">>>defining method: #{str}"
          eval str
        rescue Exception => boom
          puts ">>Exception occured while definition method #{methodName} with expression: #{expression} exception: #{boom}"
        end    
      end
      
      def createAttr(attr)
        methodName = "#{attr}="
        self.instance_eval { class << self; self end }.send(:attr_accessor, attr) unless self.respond_to? methodName
        setAttr(attr, 0.0)
      end
      
      def setAttr(attr, value)
        methodName = "#{attr}="
        value = 0.0 unless value
        self.send(methodName, value)
      end

      def setAttr1(attr, value)
        value = 0.0 unless value
        self.send(attr, value)
      end

      def setAttr2(attr, value)
        methodName = "#{attr}="
        value = "" unless value
        self.send(methodName, value)
	  end

      def addAttr1(attr, value)
        methodName = "#{attr}="
        self.instance_eval { class << self; self end }.send(:attr_accessor, attr) unless self.respond_to? methodName 
        self.send(methodName, value) if value
        self.send(methodName, 0.0) unless value
      end

      def method_missing(meth, *args, &block)
      #  puts ">>>method_missing: #{meth}"
      #  puts caller
        return 0
      end
      
      def stampStepTime(startTime,stepStr)
        endTime = Time.now
        puts "@@@\t #{stepStr} \t #{endTime-startTime}"
      end
    end
  end
end