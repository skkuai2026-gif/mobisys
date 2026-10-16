require 'CommonModules/encryption'

module MobiSys
	module MobiSysEntitySchema
		include Rhom::FixedSchema
		property :userId, :string
		property :parentKey, :string
		property :versionID, :integer
		property :id, :integer
		property :guid, :string
		property :systemCreatedDt, :time
		property :systemUpdatedDt, :time
		property :removed, :string
		attr_accessor :parentBaseDO
		attr_accessor :contextGuid

		@@children = Hash.new

		def self.clearChildren
			@@children.clear
		end
		#####################################################################################################


		def self.included(model)
			model.extend MobiSysEntitySchema
			model.extend Rhom::FixedSchema
			class << model

				def loadObject(*args)
					objects = Array.new
					loadChild = true
					parentObj = nil
					userConditions = {:conditions=>{:userId=>AgentReg.forUserId($userId, true).userId}}
					args = args.flatten
					if args.length > 2
						parentObj = args[2]
					end

					if args.length > 1
						hash = args[1]
						if hash.is_a? Hash
							if hash.has_key?(:loadChild)
								loadChild = false
							end
							if hash.has_key?(:parentObj)
								parentObj = hash[:parentObj]
							end
							if hash.has_key?(:conditions)
								originalConditions = {:conditions=>hash[:conditions],:op=>hash[:op]}
							else
								originalConditions = {:conditions=>{1=>1}}
							end
							objects = find(args[0],:conditions=>[userConditions,originalConditions],:op=>'AND',:order=>hash[:order],:orderdir=>hash[:orderdir],:per_page=>hash[:per_page])
						end
					else
						objects = find(args[0],userConditions)
					end

					if objects.is_a? MobiSys::MobiSysEntitySchema
						objects.parentBaseDO = parentObj
						if loadChild
							childClassArray = $childClasses[objects.class.name.to_s]
							if childClassArray and childClassArray.length > 0
								childClassArray.each do |childClass|
									children = Object.const_get(childClass).loadObject(:all,:conditions=>{:parentKey =>objects.object},:parentObj => objects)
									# exp = childClass + ".loadObject(:all,:conditions=>{:parentKey =>'" + objects.object + "'},:parentObj => parentObj)"
									# children = eval(exp)
									if children and children.length > 0
										method_name = ("set" + childClass.to_s + "List").to_sym
										objects.send(method_name,children)
									end
								end
							end
						end

						##################################
						##  Check if field encrypted
						##################################
						#Deepali Singh 14-06-2016: restoring datatype after decrypting data
						if $rhoconfig.has_key?(:encrypt_db_on_platform) 
							platforms = $rhoconfig[:encrypt_db_on_platform].split(',')
							if platforms.include? System.get_property('platform').to_s
								if objects.class.respond_to?(:encryptedFields)
									encryptedFields = objects.class.encryptedFields
									modelSource = Rho::RhoConfig.sources[objects.class.name.to_s]
									modelSource["schema"]["property"].each do |property, valueArray|
										if encryptedFields.include?property
											propertyStatement = "objects.#{property}"
											columnValue = eval(propertyStatement)
											if columnValue.to_s != ""
												if valueArray[0].to_sym == :integer
													stmt = "objects.#{property} = MobiSys::Encryption.decryptContent(objects.#{property}).to_i"
													eval(stmt)
												elsif valueArray[0].to_sym == :float
													stmt = "objects.#{property} = MobiSys::Encryption.decryptContent(objects.#{property}).to_f"
													eval(stmt)
												elsif valueArray[0].to_sym == :string
													stmt = "objects.#{property} = MobiSys::Encryption.decryptContent(objects.#{property}).to_s"
													eval(stmt)
												else
													stmt = "objects.#{property} = MobiSys::Encryption.decryptContent(objects.#{property}).to_s"
													eval(stmt)
												end
											end
										end
									end
								end
							end
						end
						##################################
						##  End encryption check
						##################################            
						return objects
					elsif objects.kind_of? Array
						objects.each do |object|
							object.parentBaseDO = parentObj
							if loadChild
								childClassArray = $childClasses[object.class.name.to_s]
								if childClassArray and childClassArray.length > 0
									childClassArray.each do |childClass|
										children = Object.const_get(childClass).loadObject(:all,:conditions=>{:parentKey =>object.object},:parentObj => object)
										# exp = childClass + ".loadObject(:all,:conditions=>{:parentKey =>'" + object.object + "'},:parentObj=>parentObj)"
										# puts "exp :- #{exp}"
										# children = eval(exp)
										if children and children.length > 0
											method_name = ("set" + childClass.to_s + "List").to_sym
											object.send(method_name,children)
										end
									end
								end
							end
							##################################
							##  Check if field encrypted
							##################################             
							#Deepali Singh 14-06-2016: restoring datatype after decrypting data
							if $rhoconfig.has_key?(:encrypt_db_on_platform) 
								platforms = $rhoconfig[:encrypt_db_on_platform].split(',')
								if platforms.include? System.get_property('platform').to_s
									if object.class.respond_to?(:encryptedFields)
										encryptedFields = object.class.encryptedFields
										modelSource = Rho::RhoConfig.sources[object.class.name.to_s]
										modelSource["schema"]["property"].each do |property, valueArray|
											if encryptedFields.include?property
												propertyStatement = "object.#{property}"
												columnValue = eval(propertyStatement)
												if columnValue.to_s != ""
													if valueArray[0].to_sym == :integer
														stmt = "object.#{property} = MobiSys::Encryption.decryptContent(object.#{property}).to_i"
														eval(stmt)
													elsif valueArray[0].to_sym == :float
														stmt = "object.#{property} = MobiSys::Encryption.decryptContent(object.#{property}).to_f"
														eval(stmt)
													elsif valueArray[0].to_sym == :string
														stmt = "object.#{property} = MobiSys::Encryption.decryptContent(object.#{property}).to_s"
														eval(stmt)
													else
														stmt = "object.#{property} = MobiSys::Encryption.decryptContent(object.#{property}).to_s"
														eval(stmt)
													end
												end
											end
										end
									end
								end
							end
							##################################
							##  End encryption check
							##################################
						end
						return objects 
					end
				end

				def delete_all(*args)
					args.unshift(:all)
					objects = loadObject(args)
					objects.each do |object|
						object.delete
					end
				end
			end
		end
		#####################################################################################################


		def uniqueKey
			uniqueKey = self.object.gsub(".","_")
			uniqueKey = self.guid if self.guid
			uniqueKey
		end
		#####################################################################################################


		def persistAll(*args)
			db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
			db.start_transaction
			begin
				persist(args)
				db.commit
			rescue Exception => e
				db.rollback
		        puts "persistAll Failed for "+self.class.name.to_s + "#{e}\n#{e.backtrace}"
			end
		end

		#####################################################################################################

		
		def persist(*args)
			updateDate = true
			if args and args.size > 0
				if args[0] == 'fromSync'
					updateDate = false
				end
			end
			if self.guid.to_s == ""
				self.systemCreatedDt = Time.now
				self.guid = self.uniqueKey
			end
			self.systemCreatedDt = Time.now if self.systemCreatedDt.to_s == ""
			self.userId = AgentReg.forUserId($userId, true).userId
			# self.versionID = 1 unless self.versionID
			# commenting versionID default value setting as this field has no significance in offline
			self.systemUpdatedDt = Time.now if updateDate

			##################################
			##  Check if field encrypted
			##################################
			if $rhoconfig.has_key?(:encrypt_db_on_platform) 
				platforms = $rhoconfig[:encrypt_db_on_platform].split(',')
				if platforms.include? System.get_property('platform').to_s
					if self.class.respond_to?(:encryptedFields)
						encryptedFields = self.class.encryptedFields
						encryptedFields.each do |encryptedField|
							colVal = self.send encryptedField
							if colVal.to_s != ""
								self.send("#{encryptedField}=".to_sym, MobiSys::Encryption.encryptContent(self.send encryptedField.to_sym))
							end
						end
					end
				end
			end      
			##################################
			##  End encryption check
			##################################   
			#If value is NaN, set it to 0.0
			self.vars.each do |key,value|
				if value.to_s == "NaN"
					stmt = "self.#{key}=0.0"
					eval(stmt)
				end
			end

			save
	      
			#Swati Ahire 26-12-2014: Data decrypted to avoid double encryption
			#Deepali Singh 14-06-2016: restoring datatype after decrypting data
			if $rhoconfig.has_key?(:encrypt_db_on_platform) 
				platforms = $rhoconfig[:encrypt_db_on_platform].split(',')
				if platforms.include? System.get_property('platform').to_s
					if self.class.respond_to?(:encryptedFields)
						encryptedFields = self.class.encryptedFields
						modelSource = Rho::RhoConfig.sources[self.class.name.to_s]
						modelSource["schema"]["property"].each do |property, valueArray|
							if encryptedFields.include?property
								propertyStatement = "self.#{property}"
								columnValue = eval(propertyStatement)
								if columnValue.to_s != ""
									if valueArray[0].to_sym == :integer
										stmt = "self.#{property} = MobiSys::Encryption.decryptContent(self.#{property}).to_i"
										eval(stmt)
									elsif valueArray[0].to_sym == :float
										stmt = "self.#{property} = MobiSys::Encryption.decryptContent(self.#{property}).to_f"
										eval(stmt)
									elsif valueArray[0].to_sym == :string
										stmt = "self.#{property} = MobiSys::Encryption.decryptContent(self.#{property}).to_s"
										eval(stmt)
									else
										stmt = "self.#{property} = MobiSys::Encryption.decryptContent(self.#{property}).to_s"
										eval(stmt)
									end
								end
							end
						end
					end
				end
			end

			childrenHash = @@children[@vars[:object].to_s]
			if childrenHash
				childrenHash.each do |key,value|
					childArray = value
					deleteIndexes = [] # code for not skipping alternative rows for deletion
					childArray.each_with_index do |child,index|
						deleteIndexes << index if child.removed && child.removed != ""
						begin
							child.delete if child.removed && child.removed != ""
						rescue StandardError => boom
							#do nothing. Record probably not saved in DB.
						end
						child.parentKey = self.object unless child.removed && child.removed != ""
						child.persist unless child.removed && child.removed != ""
					end
					deleteIndexes.reverse.each do |index|
						childArray.delete_at index
					end
				end
			end
		end
		#####################################################################################################


		def delete
			childrenHash = @@children[@vars[:object].to_s]
			if childrenHash
				childrenHash.each do |key,value|
					childArray = value
					childArray.each do |child|
						child.delete
					end
				end
			end
			destroy
		end
		#####################################################################################################


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
						#For API add parentKey to child before persist
						child.parentKey = self.object if Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='1'
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
							#For API add parentKey to child before persist
							child.parentKey = self.object if Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='1'
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
							if child.guid && child.guid != ""
								existingChild.removed = 'YES' if existingChild.guid == child.guid 
							else
								childArray.delete(existingChild) if existingChild.object == child.object
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
		#####################################################################################################


		def delete_all_for_user(userId)
			delete_all(:conditions => {'userId'=>:userId})
		end
		#####################################################################################################


		def clone
			obj = self.class.new
			obj.vars = self.vars.clone
			obj.object = "#{generate_id}"
			return obj
		end
		#####################################################################################################


		def cloneObject
			obj = self.clone
			childrenHash = @@children[@vars[:object].to_s]
			if childrenHash
				childrenHash.each do |key,value|
					value.each do |child|
						childClone = child.cloneObject
						methodName = "add#{child.class.name}".to_sym
						obj.send methodName, childClone
					end
				end
			end
			obj
		end
		#####################################################################################################


		def self.from_hash(className,hash)
			#className = self.class.name
			objClass = Object.const_get(className)
			obj = objClass.new
			hash.each do |key,value|
				next if key.to_s=='object'
				next if value == nil
				next if value.class.name.to_s == 'Array'
	        
				begin
					# puts '>>Evaluating ' + key.to_s
					methodExists = obj.respond_to? key
					# puts '>>Method exists? ' + methodExists.to_s
					methodExists = true
					if methodExists
						# puts 'Assigning value'
						exp = 'obj.'+key+"='"+value.to_s.gsub("'","\\\\'")+"'"
						eval(exp)
						# puts 'Assigned value' 
					end
				rescue StandardError => boom
					# puts boom
				end
			end
			#Now populate the children
			childClassArray = $childClasses[className]
			if childClassArray
				childClassArray.each do |childClass|
					# puts "Child class: " + childClass.to_s
					#online class name has "D" in upper case in MetaData, so use ValidationMetaData with upper case D in online context
          			childClassName = childClass.to_s == "ValidationMetadata" ? "ValidationMetaData" : childClass
					childClassListName = 'list' + childClassName + 'DOList'
					childList = hash[childClassListName]
					# puts childList.to_s
					next unless childList
					if childList
						childList.each do |child|
							childObj = MobiSys::MobiSysEntitySchema.from_hash(childClass.to_s,child)
							exp = 'obj.add' + childClass.to_s + '(childObj)'
							# puts exp
							eval(exp)  
						end
					end
				end
			end
			return obj
		end
		#####################################################################################################

		#neha comments
		#add a parameter to ignore children in hash
		def hashForSync
			hash = Hash.new
			modelSource = Rho::RhoConfig.sources[self.class.name.to_s]
			dataTypes = modelSource["schema"]["property"]
			self.vars.each do |key,value|
				next if value == nil
				next if value == ""
				dataType = nil
				dataType = dataTypes[key.to_s][0] if dataTypes[key.to_s]
				hashKey = key.to_sym
				if hashKey == :userId && value.to_s != ''
					hash[hashKey] = MobiSys::Encryption.decryptContent(value.to_s)
				else
					hash[hashKey] = value.to_s if dataType and dataType == "string".to_sym
					hash[hashKey] = value unless dataType and dataType == "string".to_sym
				end
			end
			self.instance_variables.each do |x|
				#skip @status as it is added for new object deletion in API and should not be added as sent for online sync
				next if (x.to_s == "@vars" || x.to_s == "@status")
				hash[x.to_s.gsub("@","").to_sym] = self.instance_variable_get(x)
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

		def hashForApi(childrenRequired=true, allowdAttributes=[])
			hash = Hash.new
			modelSource = Rho::RhoConfig.sources[self.class.name.to_s]
			attrToSend = $attributeHash[$entityClassName] if $attributeHash && $attributeHash[$entityClassName]
			hash[:object] = self.vars[:object] if self.vars.has_key?(:object)
			allowdAttributes << "contextGuid"
			allowdAttributes << "status"
			modelSource["schema"]["property"].each do |property, valueArray|
				hashKey = property.to_sym
				next if attrToSend != nil && (!attrToSend.include? hashKey)
				value = nil
				value = self.vars[hashKey] if self.vars.has_key?(hashKey)
				value = self.uniqueKey if value == nil && hashKey.to_s == "guid"
				if hashKey == :userId && value.to_s != ''
					hash[hashKey] = MobiSys::Encryption.decryptContent(value.to_s)
				else
					# hash[hashKey] = value.to_s if valueArray[0] and valueArray[0] == "string".to_sym
					# hash[hashKey] = value unless valueArray[0] and valueArray[0] == "string".to_sym
					if value.to_s != "" and valueArray[0] and [:date,:time].include? valueArray[0]
						if value.to_s != "" && value != nil #.to_s.match(/\d+/).to_s==date.to_s   
							d = DateTime.parse(value.to_s)       
							apiDate = d.strftime('%Q').to_i
						else
							apiDate = value.to_i
						end
						hash[hashKey] = apiDate
					elsif value.to_s != "" and valueArray[0] and valueArray[0] == :integer
						hash[hashKey] = value.to_i	
					elsif value.to_s != "" and valueArray[0] and (valueArray[0] == :float|| valueArray[0] == :double)
						hash[hashKey] = value.to_f
					else
						hash[hashKey] = value	
					end
				end
			end
			attraccssorToSend = Object.const_get(self.class.name.to_s).instance_methods(false)
			if attraccssorToSend
				attraccssorToSend.each do |x|
					next if attrToSend != nil && (!attrToSend.include? x)
					if self.instance_variables.include?("@#{x.to_s}".to_sym) 
						hash[x] = self.instance_variable_get("@#{x}".to_sym) 
					elsif (!hash.has_key?(x))
						hash[x] = nil
					end
				end
			end

			allowdAttributes.each do |x|
				if self.instance_variables.include?("@#{x}".to_sym)
					hash[x.to_sym] = self.instance_variable_get("@#{x}".to_sym) 
				end
            end
			# exp = self.class.name.to_s + ".onlineClassName"
			# className = eval(exp)
			# hash['class'] = className
			children = @@children[self.object.to_s]
			if childrenRequired && children
				children.each do |key,value|
					childArray = Array.new
					value.each do |child|
						childArray.push child.hashForApi
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

		
		def objectToHash
			hash = Hash.new
			modelSource = Rho::RhoConfig.sources[self.class.name.to_s]
			dataTypes = modelSource["schema"]["property"]
			self.vars.each do |key,value|
				next if value == nil && (!Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0'))
				dataType = nil
				dataType = dataTypes[key.to_s][0] if dataTypes[key.to_s]
				hashKey = key.to_sym
				if hashKey == :userId && value.to_s != ''
					hash[hashKey] = MobiSys::Encryption.decryptContent(value.to_s)
				else
					hash[hashKey] = value.to_s if dataType and dataType == "string".to_sym
					hash[hashKey] = value unless dataType and dataType == "string".to_sym
				end
			end
			self.instance_variables.each do |x|
				next if x.to_s == "@parentBaseDO"
				next if x.to_s == "@vars"
				hash[x.to_s.gsub("@","").to_sym] = self.instance_variable_get(x)
            end
			exp = self.class.name.to_s + ".onlineClassName"
			className = eval(exp)
			hash['class'] = className
			children = @@children[self.object.to_s]
			if children
				children.each do |key,value|
					childArray = Array.new
					value.each do |child|
						childArray.push child.objectToHash
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
		##################################################################################################


		def merge(onlineEntity)
			onlineEntity.vars.each do |key,value|
				next if key == 'object'.to_sym or key == 'removed'.to_sym
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
					# puts exp
					originalChildClassList = eval(exp)
					exp = 'onlineEntity.' + childClass.to_s + 'List'
					onlineChildClassList = eval(exp)
					originalChildClassList.each do |originalChild|
						matchFound = false
						onlineChildClassList.each do |onlineChild|
							if onlineChild.guid == originalChild.guid
								originalChild.merge onlineChild
								matchFound = true
							end  
						end
						if !matchFound
							originalChild.removed = "YES"
						end
					end
					#Adding handling for cases where a new child is added when DO returned from online.
					onlineChildClassList.each do |onlineChild|
						addChild = true
						originalChildClassList.each do |offlineChild|
							if onlineChild.guid == offlineChild.guid
								addChild = false
								break
							end
						end
						originalChildClassList.push onlineChild if addChild  
					end
					#Handling end
				end
			end
		end
		#####################################################################################################
	end
end

