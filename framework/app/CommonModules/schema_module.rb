module MobiSys
  MOBISYSDEVICEID = 'mobiSysDeviceId'
  DEVICEDISABLED = 'deviceDisabled'
  USERDISABLED = 'userDisabled'
  BUNDLEURL = 'bundleURL'
  AUTHENTICATIONMESSAGE = 'AUTHENTICATIONMESSAGE';
  #variable key,online registration date and device seq updated in application db
  VIEWCD = 'viewCd'
  ONLINEREGDT = 'onlineRegDt'
  DEVICESEQ = 'deviceSeq'
  DEVICESYSTIME = 'deviceSysTime'
  
  class ApplicationKeyDuplicateError < StandardError
      
  end
  
  class ApplicationKeyDoesNotExistError < StandardError
    
  end  
  
  module MobiSysFixedSchema
    include Rhom::FixedSchema
#    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :removed, :string
    #property :systemCreatedDt, :time
    #property :systemUpdatedDt, :time
    
    @@children = Hash.new
    
    def self.included(model)
      model.extend MobiSysFixedSchema
      model.extend Rhom::FixedSchema
      class << model
        def loadObject(*args)
          objects = find(*args)
          if objects.is_a? MobiSys::MobiSysFixedSchema
            childClassArray = $childClasses[objects.class.name.to_s]
            if childClassArray and childClassArray.length > 0 
              childClassArray.each do |childClass|
                exp = childClass + ".loadObject(:all,:conditions=>{:parentKey =>'" + objects.object + "'})"
                children = eval(exp)
                if children and children.length > 0
                  method_name = ("set" + childClass.to_s + "List").to_sym
                  objects.send(method_name,children)
                end
              end
            end
            return objects
          elsif objects.kind_of? Array
            objects.each do |object|
              childClassArray = $childClasses[object.class.name.to_s]
              if childClassArray and childClassArray.length > 0 
                childClassArray.each do |childClass|
                  exp = childClass + ".loadObject(:all,:conditions=>{:parentKey =>'" + object.object + "'})"
                  children = eval(exp)
                  if children and children.length > 0
                    method_name = ("add" + childClass.to_s + "List").to_sym
                    object.send(method_name,children)
                  end
                end
              end
            end
            return objects 
          end
        end        
      end
    end
    
    def persist(*args)
      updateDate = true
      if args and args.size > 0
        if args[0] == 'fromSync'
          updateDate = false
        end        
      end
      self.versionID = 1 unless self.versionID
      #self.versionId = self.versionId + 1 if self.versionId
      self.guid = self.object unless self.guid
      #self.systemCreatedDt = Time.now unless self.createdDt
      #self.systemUpdatedDt = Time.now if updateDate
      save
      childrenHash = @@children[@vars[:object].to_s]
      if childrenHash
        childrenHash.each do |key,value|
          childArray = value
          deleteIndexes = [] # code for not skipping alternative rows for deletion
          childArray.each_with_index do |child,index|
            deleteIndexes << index if child.removed && child.removed != ""
            child.delete if child.removed && child.removed != ""
            child.parentKey = self.object unless child.removed && child.removed != ""
            child.persist unless child.removed && child.removed != ""
          end
          deleteIndexes.reverse.each do |index|
            childArray.delete_at index
          end
        end
      end
    end
    
    def delete
      childrenHash = @@children[@vars[:object].to_s]
      if childrenHash
        childrenHash.each do |key,value|
          childArray = value
          childArray.each do |child|
            child.destroy
          end
        end
      end
      destroy
    end
    
    def has_many(*childClasses)
      className = self.name
      childClassArray = $childClasses[className.to_s]
      unless childClassArray
        childClassArray = Array.new
        $childClasses[className.to_s] = childClassArray
      end
      
      childClasses.each do |childClass| 
        childClassArray.push childClass.to_s unless childClassArray.include? childClass.to_s
        
        #Adding add* method. For example, if the child class is named Address, the method will be
        #generated as addAddress(addressObject)
        method_name = ("add" + childClass.to_s).to_sym
        send :define_method, method_name do |child|
          exp = "child.is_a? " + childClass.to_s
          result = eval(exp)
          if result
            @@children[@vars[:object].to_s] = Hash.new unless @@children[@vars[:object].to_s]
            @@children[@vars[:object].to_s][childClass.to_s] = Array.new unless @@children[@vars[:object].to_s][childClass.to_s]
            childArray = @@children[@vars[:object].to_s][childClass.to_s]
            childArray.each do |object|
              if object.object == child.object
                childArray.delete object
              end
            end
            childArray.push child  
          else
            raise ArgumentError.new("This method accepts argument of class " + childClass.to_s)
          end
        end
        
        #Adding *ListSize method. For example, if the child class is named Address, the method will be
        #generated as AddressListSize()
        method_name = (childClass.to_s + "ListSize").to_sym
        send :define_method, method_name do
          childArray = @@children[@vars[:object].to_s][childClass.to_s]
          return childArray.size if childArray
          return 0 unless childArray
        end
        
        #Adding add*List(*children) method. For example, if the child class is named Address, the method will be
        #generated as addAddressList(*children)
        method_name = ("add" + childClass.to_s + "List").to_sym
        send :define_method, method_name do |children|
          if children.is_a? Array
            children.each do |child|
              exp = "child.is_a? " + childClass.to_s
              result = eval(exp)
              unless result
                raise ArgumentError.new("This method accepts as argument an Array having members of class " + childClass.to_s)
              end
            end
            @@children[@vars[:object].to_s] = Hash.new unless @@children[@vars[:object].to_s]
            @@children[@vars[:object].to_s][childClass.to_s] = Array.new unless @@children[@vars[:object].to_s][childClass.to_s]
            childArray = @@children[@vars[:object].to_s][childClass.to_s] 
            children.each do |child|
              childArray.each do |object|
                if object.object == child.object
                  childArray.delete object
                end
              end
              childArray.push child
            end
          else
            raise ArgumentError.new("This method accepts as argument an Array having members of class " + childClass.to_s)
          end  
        end
        
        #Adding remove*(child) method. For example, if the child class is named Address, the method will be
        #generated as removeAddress(address).
        #This method is used to remove a specific child object from the list in parent.
        method_name = ("remove" + childClass.to_s).to_sym
        send :define_method, method_name do |child|
          exp = "child.is_a? " + childClass.to_s
          result = eval(exp)
          if result
            @@children[@vars[:object].to_s] = Hash.new unless @@children[@vars[:object].to_s]
            @@children[@vars[:object].to_s][childClass.to_s] = Array.new unless @@children[@vars[:object].to_s][childClass.to_s]
            childArray = @@children[@vars[:object].to_s][childClass.to_s]
            childArray.each do |existingChild|
              if existingChild.guid == child.guid
                existingChild.removed = true
              end  
            end  
          else
            raise ArgumentError.new("This method accepts argument of class " + childClass.to_s)
          end
        end
        
        #Adding *List() method. For example, if the child class is named Address, the method will be
        #generated as addressList.
        #The method returns the child list
        method_name = (childClass.to_s + "List").to_sym
        send :define_method, method_name do 
          @@children[@vars[:object].to_s] = Hash.new unless @@children[@vars[:object].to_s]
          @@children[@vars[:object].to_s][childClass.to_s] = Array.new unless @@children[@vars[:object].to_s][childClass.to_s]
          childArray = @@children[@vars[:object].to_s][childClass.to_s]  
        end
        
        #Adding set*List(childList) method. For example, if the child class is named Address, the method will be
        #generated as setAddressList(addressList)
        method_name =("set" + childClass.to_s + "List").to_sym
        send :define_method, method_name do |childList|
          if childList.is_a? Array
            childList.each do |child|
              exp = "child.is_a? " + childClass.to_s
              result = eval(exp)
              unless result
                raise ArgumentError.new("This method accepts as argument an Array having members of class " + childClass.to_s)
              end
            end
            @@children[@vars[:object].to_s] = Hash.new unless @@children[@vars[:object].to_s]
            @@children[@vars[:object].to_s][childClass.to_s] = childList
          else
            raise ArgumentError.new("This method accepts as argument an Array having members of class " + childClass.to_s)
          end
        end
      end
    end
    
#    def delete_all_for_user(userId)
#      delete_all(:conditions => {'userId'=>:userId})
#    end
      
    def clone
      className = self.class.name
      objClass = Object.const_get(className)
      obj = objClass.new
      self.vars.each do |key,value|
        next if key.to_s=='object'
        next if key.to_s=='source_id'
        exp = 'obj.'+key.to_s+"='"+value.to_s.gsub("'",'"')+"'"
        eval(exp)
      end
      return obj
    end

    def cloneObject
      obj = self.clone
      childrenHash = @@children[@vars[:object].to_s]
      if childrenHash
        childrenHash.each do |key,value|
          value.each do |child|
            childClone = child.cloneObject
            stmt = "obj.add#{child.class.name.to_s} childClone"
            eval(stmt)
          end
        end  
      end  
      obj
    end
    
    def self.from_hash(className,hash)
      #className = self.class.name
      objClass = Object.const_get(className)
      obj = objClass.new
      hash.each do |key,value|
        next if key.to_s=='object'
        next if value == nil or value == ''
        #puts ">>key: " + key.to_s
        next if value.class.name.to_s == 'Array'
        
        #exp = 'obj.'+key+"='"+value.to_s+"'"
        #exp = "obj.#{key}=#{value.to_s}"
        #puts ">>>value:#{value.to_s}:"
        begin  
          #eval(exp)
          obj.send "#{key}=",value
        rescue StandardError => boom
          #puts "boom: #{boom}"
        end  
      end
      #Now populate the children
      childClassArray = $childClasses[className]
      if childClassArray
        childClassArray.each do |childClass|
          #online class name has "D" in upper case in MetaData, so use ValidationMetaData with upper case D in online context
          childClassName = childClass.to_s == "ValidationMetadata" ? "ValidationMetaData" : childClass
          #puts "Child class: " + childClassName.to_s
          childClassListName = 'list' + childClassName + 'DOList'
          childList = hash[childClassListName]
          #puts childList.to_s
          next unless childList
          childList.each do |child|
            childObj = MobiSys::MobiSysFixedSchema.from_hash(childClass.to_s,child)
            exp = 'obj.add' + childClass.to_s + '(childObj)'
            #puts exp
            eval(exp)  
          end  
        end
      end
      return obj
    end
    
    def hashForSync
      hash = Hash.new
      self.vars.each do |key,value|
        next if value == nil
        next if value == ""
        hashKey = key.to_sym
        if hashKey == :userId && value.to_s != ''
          hash[hashKey] = MobiSys::Encryption.decryptContent(value.to_s)
        else
          hash[hashKey] = value
        end
      end
      exp = self.class.name.to_s + ".onlineClassName"
      className = eval(exp)
      hash['class'] = className
      children = @@children[self.object.to_s]
      if children
        children.each do |key,value|
          childArray = Array.new
          value.each do |child|
            childArray.push child.hashForSync
          end
          className = key.dup
          #online class name has "D" in upper case in MetaData, so use ValidationMetaData with upper case D in online context
          childClassName = className.to_s == "ValidationMetadata" ? "ValidationMetaData" : className
          className = 'list' + childClassName + 'DOList'
          hash[className] = childArray
        end
      end  
      return hash
    end
    
    
    #Add method
    def merge(onlineEntity)
      onlineEntity.vars.each do |key,value|
        next if key == 'object'.to_sym
        self.vars[key] = onlineEntity.vars[key]
      end
      #self.vars.each do |key,value|
      #  next if key == 'object'.to_sym
      #  self.vars[key] = onlineEntity.vars[key]
      #end
      childClassArray = $childClasses[self.class.name.to_s]
      if childClassArray
        childClassArray.each do |childClass|
          exp = 'self.' + childClass.to_s + 'List'
          #puts exp
          originalChildClassList = eval(exp)
          exp = 'onlineEntity.' + childClass.to_s + 'List'
          onlineChildClassList = eval(exp)
          originalChildClassList.each do |originalChild|
            onlineChildClassList.each do |onlineChild|
              if onlineChild.guid == originalChild.guid
                originalChild.merge onlineChild
              end  
            end
          end
        end
      end
    end
    #End method
    
  end
end