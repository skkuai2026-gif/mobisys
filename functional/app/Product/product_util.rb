require 'singleton'
require 'CommonModules/comparators'
require 'CommonModules/valueclasses'
require 'CommonModules/mobisysbrowserhelper'
require 'Policy/PolicyUtil'

module MobiSys
	class ProductUtil
		include Singleton
		include MobiSys::BrowserHelper

		LASTBIRTHDAY = "LASTBIRTHDAY"
		NEXTBIRTHDAY = "NEXTBIRTHDAY"
		NEXTBIRTHDAYALWAYS = "NEXTBIRTHDAYALWAYS"

		ProductDefinitionTableMap = Hash.new
		ProductModelDecisionTableMap = Hash.new
		ProductCache = Hash.new

		#@enableCache = false
		@enableCache = true

		def self.addToCache(key, value)
			ProductDefinitionTableMap[key] = value
		end
		###################################################################################################

		def self.addToDynamicDTCache(key, value)
			ProductModelDecisionTableMap[key] = value
		end
		###################################################################################################

		def self.getFromCache(key)
			return ProductDefinitionTableMap[key]
		end
		###################################################################################################

		def self.getFromDynamicDTCache(key)
			return ProductModelDecisionTableMap[key]
		end
		###################################################################################################

		def self.resetCache()
			GC.enable
			ProductDefinitionTableMap.each do |key, value|
				ProductDefinitionTableMap[key] = nil
				ProductDefinitionTableMap.delete(key)
			end
			ProductModelDecisionTableMap.each do |key, value|
				ProductModelDecisionTableMap[key] = nil
				ProductModelDecisionTableMap.delete(key)
			end
		end
		###################################################################################################


		def self.enableCache()
			@enableCache = true
		end
		###################################################################################################


		def self.disableCache()
			resetCache
			@enableCache = false 
		end
		###################################################################################################


		def self.getProduct(productSeq)    
			product = ProductCache[productSeq]
			unless product
				product = Product.loadObject(:first,:conditions=>{{ :name => 'id' } => productSeq.to_s})
				# if(System.get_property('platform') == 'WINDOWS_DESKTOP')
					ProductCache[productSeq] = product
				# end
			end
			return product
		end
		###################################################################################################


		### loads only product
		def self.findProduct(productSeq)  
			product = Product.find(:first,:conditions=>{{ :name => 'id' } => productSeq.to_s})
			return product
		end
		###################################################################################################


		def self.calculateAge(dob, ageCalculationBasis, commencementDate)
			leapYearDays = 0
			age = ""
			years = 0
			months = 0
			days = 0
			if commencementDate.year % 4 != 0
				leapYearDays = 365
			elsif commencementDate.year % 400 == 0
				leapYearDays = 366
			elsif commencementDate.year % 100 == 0
				leapYearDays = 365
			else
				leapYearDays = 366
			end

			# handle leap year feb
			#if dob.getDate() == 29 && dob.getMonth() == 2 && leapYearDays == 365
			#  dob.setDate(1)
			#  dob.setMonth(3)
			#end

			difference = getDifference(dob, commencementDate)
			years = difference.to_i / 10000
			months = difference.to_i % 10000 / 100
			days = difference.to_i % 100

			years = getPreciseAge(ageCalculationBasis, years, months, days)

			if years < 0
				years = 0
			end
			
			age << years.to_s << "|" << months.to_s << "|" << days.to_s
			return age
		end
		###################################################################################################


		def self.getAge(dob, ageCalculationBasis, commencementDate)
			leapYearDays = 0
			age = ""
			years = 0
			months = 0
			days = 0
			#Time.strptime(commencementDate, "%d/%m/%Y")
			commencementDate = Date.strptime(commencementDate.to_s, "%d/%m/%Y")
			dob = Date.strptime(dob, "%d/%m/%Y")
			if commencementDate.year % 4 != 0
				leapYearDays = 365
			elsif commencementDate.year % 400 == 0
				leapYearDays = 366
			elsif commencementDate.year % 100 == 0
				leapYearDays = 365
			else
				leapYearDays = 366
			end

			# handle leap year feb
			#if dob.getDate() == 29 && dob.getMonth() == 2 && leapYearDays == 365
			#  dob.setDate(1)
			#  dob.setMonth(3)
			#end

			difference = getDifference(dob, commencementDate)
			years = difference.to_i / 10000
			months = difference.to_i % 10000 / 100
			days = difference.to_i % 100

			if ageCalculationBasis == NEXTBIRTHDAY && dob.mday == commencementDate.mday && dob.mon == commencementDate.mon
				years = years
			else
				years = getPreciseAge(ageCalculationBasis, years, months, days)
			end

			if years < 0
				years = 0
			end

			age << years.to_s << "|" << months.to_s << "|" << days.to_s
			return age
		end
		###################################################################################################


		def self.getPreciseAge(ageCalculationBasis, years, months, days) 
			age = 0

			if ageCalculationBasis == LASTBIRTHDAY
				return years
			elsif ageCalculationBasis == NEXTBIRTHDAY
				return years + 1
			elsif ageCalculationBasis == NEXTBIRTHDAYALWAYS
				return years + 1
			else 
				if months < 6
					return years
				else
					return years + 1
				end
			end
		end
		###################################################################################################


		def self.calculateDOB(age, commencementDate)
			yob = commencementDate.year - age.to_i
			dt = Time.new(yob, commencementDate.mon, commencementDate.mday)
			return dt
		end
		###################################################################################################


		def self.getDifference(dateFrom, dateTo)
			yearDiff = dateTo.year - dateFrom.year
			monthDiff = dateTo.mon - dateFrom.mon
			dayDiff = dateTo.mday - dateFrom.mday

			if dayDiff < 0
				monthDiff = monthDiff.to_i - 1
				dayDiff = 30 + dayDiff.to_i
			end

			if monthDiff < 0
				yearDiff = yearDiff.to_i - 1
				monthDiff = 12 + monthDiff.to_i
			end

			return (yearDiff.to_i * 10000 + monthDiff.to_i * 100 + dayDiff.to_i)
		end
		###################################################################################################


		def self.getNearestAge(dobStr, refDtStr, monthInterval=0)
			refDt = Date.parse(refDtStr.to_s) 
			refDt = refDt >> monthInterval.to_i
			dob = Date.parse(dobStr.to_s) 
			yeardiff = refDt.year - dob.year
			monthdiff = refDt.month - dob.month
			daydiff = refDt.day - dob.day
			yeardiff+=1 if ((monthdiff == 6 && daydiff >=0) || (monthdiff > 6))
			yeardiff-=1 if monthdiff < -6
			closest = Date.new(dob.year+yeardiff, dob.month, dob.day)
			age = closest.year - dob.year
			# puts "closest #{closest}"
			# puts "age #{age}"
			return age.to_s
		end
		###################################################################################################


		def self.getProductDefinitionTableDO(tableTypeMappingSeq, quotation, quotationProduct, party=nil, isListRequired=false, sorted=false, quotationIO=nil)
		    # puts ">>>Loading DT with tableTypeMappingSeq: #{tableTypeMappingSeq} isListRequired: #{isListRequired} sorted: #{sorted}"

		    productDefinitionTable = nil
		    productDefinitionTableList = []

		    unless party
				party = quotation.getParty(quotationProduct)
				unless party
					puts ">>>>>>>>>: Insured Party is nil"
					party=QuotationParty.new
				end
   			end
    		quotation.entityDesc = ""

    		dtvDtl = DefinitionTableVersionDtl.loadObject(:first, :conditions=>{{:name=>'tableTypeMappingSeq'}=>tableTypeMappingSeq})
    		if dtvDtl
				dtvHdr = DefinitionTableVersionHdr.loadObject(:first, :conditions=>{{:name=>'object'}=>dtvDtl.parentKey})
				if dtvHdr
					now = MobiSys::ProductUtil.getDBDateTime(quotation.quotationDt.to_s)
					dtvHdr.DefinitionTableVersionDtlList.each do |dtvDtl|
						tableTypeMappingSeq = dtvDtl.tableTypeMappingSeq if MobiSys::ProductUtil.getDBDateTime(dtvDtl.effectiveFromDt) <= now and MobiSys::ProductUtil.getDBDateTime(dtvDtl.effectiveToDt) >= now && dtvDtl.tableTypeMappingSeq.to_s != ""
					end
				end
    		end

		    # Get Dynamic DT Conditions starts
		    tableTypeConditionDOList = getTableTypeConditions(tableTypeMappingSeq)
		    dyntableTypeCondList = []
		    dynamicModelCd = ""
			
		    if tableTypeConditionDOList
		    	tableTypeConditionDOList.each do |ttc|
		    		if ttc.fixedDynamicCondTypeCd.to_s == "DYNAMIC"
		    			if dynamicModelCd.to_s == "" && ttc.modelCd.to_s != ""
		    				dynamicModelCd = ttc.modelCd
		    			end
		    			dyntableTypeCondList.push(ttc)
		    		elsif ttc.modelCd.to_s != "" && ttc.fixedDynamicCondTypeCd.to_s != "FIXED"
		    			dynamicModelCd = ttc.modelCd
		    			break
		    		end
		    	end
		    end
		    # Get Dynamic DT Conditions ends
			if dyntableTypeCondList.empty? && dynamicModelCd.to_s != "" # Dynamic DT Evaluation
				polModelDO = PolicyUtil::PolicyModel.new
				policy = MobiSys::PolicyBO.convertToPolicy(quotation, true)
				policyParty = policy.getPartyByGuid(party.guid)
				policyParty.policyYear = quotation.policyYear 
				# policyProduct = policy.getBaseProduct if policy
				policyProduct = policy.getPolicyProductByGuid(quotationProduct.guid) if policy
				fieldResultDOList = nil
				fieldResultDOList = [] if isListRequired
				@modelResultDO = polModelDO.execute(policy, policyProduct, policyParty, dynamicModelCd, tableTypeMappingSeq, @enableCache, fieldResultDOList, quotationIO) if policyProduct

				if isListRequired && fieldResultDOList != nil && fieldResultDOList.size > 0
					fieldResultDOList.each do |fieldresultDO|
						newProductDefinitionTable = createDynamicDefinitionTableRecord(fieldresultDO)
	      				productDefinitionTableList.push(newProductDefinitionTable)
					end
				elsif @modelResultDO
					productDefinitionTable = createDynamicDefinitionTableRecord(@modelResultDO)
				end
      			quotation.entityDesc += policy.entityDesc if policy.entityDesc.to_s != ""

   			else #Fixed/Dynamic DT Evaluattion
      			# Run dynamic DT model starts
      			if dyntableTypeCondList.size > 0 && dynamicModelCd.to_s != ""
      				polModelDO = PolicyUtil::PolicyModel.new
      				policy = MobiSys::PolicyBO.convertToPolicy(quotation, true)
      				policyParty = policy.getPartyByGuid(party.guid)
					policyParty.policyYear = quotation.policyYear
      				# policyProduct = policy.getBaseProduct if policy
      				policyProduct = policy.getPolicyProductByGuid(quotationProduct.guid) if policy
      				@modelResultDO = polModelDO.execute(policy, policyProduct, policyParty, dynamicModelCd, nil, nil, nil, quotationIO) if policyProduct
      			end
     			# Run dynamic DT model ends
      			productDefinitionTableListFromDB = getProductDefinitionTables(tableTypeMappingSeq, sorted, quotation, quotationProduct, party)

      			flag = true
      			counter = 0;
      			unless productDefinitionTableListFromDB and productDefinitionTableListFromDB.size > 0
      				if isListRequired
      					return productDefinitionTableList
      				else
      					return productDefinitionTable
      				end
      			end

      			dtFilters = getDTConditions(tableTypeMappingSeq)
     			# dtFilters.each{|condition| puts condition}

     			productDefinitionTableListFromDB.each do |dtd|
     				flag = true
     				productDefinitionTable = nil
     				counter += 1
     				dtFilters.each do |conditionClass|
     					productDefinitionTable,flag = conditionClass.send(:compare, quotation, quotationProduct, party, productDefinitionTable, dtd, flag)
     					unless flag
     						quotation.entityDesc = ""
     						break
     					end
     				end
					
        			# Dynamic DT evaluation starts
        			dyntableTypeCondList.each do |ttConDO|
        				expressCond = false
        				mvelExpressValue = @modelResultDO.getFieldValue(ttConDO.condition) if @modelResultDO
        				if mvelExpressValue
        					columnNames = ttConDO.dtColumnNames
        					if ttConDO.rangeValueFl.to_s == "RANGE"
        						colNameArr = columnNames.split(",")
        						dataType = ttConDO.entityDataTypeCd
        						if dataType.to_s != "" && (dataType == 'DOUBLE' || dataType == 'SHORT' || dataType == 'LONG' || dataType == 'INTEGER')
        							dtValueFrom = dtd.send colNameArr[0]
        							dtValueTo = dtd.send colNameArr[1]
        							if dtValueFrom && dtValueTo
        								productDefinitionTable, expressCond = RangeValueComparator.checkDefinitionTableRange1(dtValueFrom,dtValueTo,mvelExpressValue,productDefinitionTable,dtd,flag)
        							end
        						end
        					elsif ttConDO.rangeValueFl.to_s == "VALUE" || ttConDO.rangeValueFl.to_s == "VALUEIN" || ttConDO.rangeValueFl.to_s == "VALUENOTIN" || ttConDO.rangeValueFl.to_s == "VALUEEQUALS"
        						dtValueToCompare = dtd.send columnNames
        						if dtValueToCompare
        							if ttConDO.rangeValueFl.to_s == "VALUE" || ttConDO.rangeValueFl.to_s == "VALUEEQUALS"
        								expressCond = true if dtValueToCompare == mvelExpressValue
        							elsif ttConDO.rangeValueFl.to_s == "VALUEIN"
        								expressCond = true if dtValueToCompare.split(",").include? mvelExpressValue
        							elsif ttConDO.rangeValueFl.to_s == "VALUENOTIN"
        								expressCond = true if !dtValueToCompare.split(",").include? mvelExpressValue
        							end
        						else
        							expressCond = true
        						end
        					elsif ttConDO.rangeValueFl.to_s == "BOTH"
        						colNameArr = columnNames.split(",")
        						dtValueFrom = dtd.send colNameArr[0]
        						dtValueTo = dtd.send colNameArr[1]
        						dtValueToCompare = dtd.send colNameArr[2]
        						if dtValueToCompare.to_s != ""
        							if ttConDO.rangeValueFl.to_s == "VALUE" || ttConDO.rangeValueFl.to_s == "VALUEEQUALS"
        								expressCond = true if dtValueToCompare == mvelExpressValue
        							elsif ttConDO.rangeValueFl.to_s == "VALUEIN"
        								expressCond = true if dtValueToCompare.split(",").include? mvelExpressValue
        							elsif ttConDO.rangeValueFl.to_s == "VALUENOTIN"
        								expressCond = true if !dtValueToCompare.split(",").include? mvelExpressValue
        							end
        						else
        							dataType = ttConDO.entityDataTypeCd
        							if dataType.to_s != "" && (dataType == 'DOUBLE' || dataType == 'SHORT' || dataType == 'LONG' || dataType == 'INTEGER')
	        							if dtValueFrom && dtValueTo
	        								productDefinitionTable, expressCond = RangeValueComparator.checkDefinitionTableRange1(dtValueFrom,dtValueTo,mvelExpressValue,productDefinitionTable,dtd,flag)
	        							end
	        						end
        						end
        					end
        					quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel(ttConDO.condition) + " (" + MobiSys::BrowserHelper.getLabel(mvelExpressValue.to_s) + ")" if expressCond
        					flag = expressCond && flag
        				end
        			end
       				# Dynamic DT evaluation ends
       				quotation.entityDesc = quotation.entityDesc[1..-1] if quotation.entityDesc[0] == ","
       				productDefinitionTable = dtd if flag
       				productDefinitionTable = nil unless flag
       				next unless flag
       				if flag and productDefinitionTable
       					if isListRequired
       						productDefinitionTableList.push(dtd)
       					else
       						break
       					end
       				else
       					productDefinitionTable = nil
       				end
       			end
       		end

    		# puts ">>>tableTypeMappingSeq: #{tableTypeMappingSeq} listSize: #{productDefinitionTableListFromDB.size} conditionCount: #{dtFilters.size} recordPosition:#{counter}"
    		if isListRequired
      			# puts ">>>returning dt list: #{productDefinitionTableList.inspect}"
      			return productDefinitionTableList
   			else
      			# puts ">>>>returning pdt: #{productDefinitionTable.inspect}"
      			return productDefinitionTable
    		end
  		end
		###################################################################################################


		def self.getProductDefinitionTables(tableTypeMappingSeq, sorted=false, quotation=nil,quotationProduct=nil,party=nil)
			#puts ">>>Loading definition tables for seq: #{tableTypeMappingSeq} sorted: #{sorted}"
			productDefinitionTableList = nil
			indexKey = getIndexKey(tableTypeMappingSeq, quotation, quotationProduct, party)
			if @enableCache
				cacheKey = tableTypeMappingSeq.to_s
				cacheKey = cacheKey + "|" + indexKey if indexKey
				productDefinitionTableList = getFromCache(cacheKey)
				unless productDefinitionTableList
					#load
					productDefinitionTableList = loadProductDefinitionTableListByTableTypeMappingSeq(tableTypeMappingSeq,sorted,indexKey)
					#add to cache
					addToCache(cacheKey,productDefinitionTableList)
				end
			else
				#load
				productDefinitionTableList = loadProductDefinitionTableListByTableTypeMappingSeq(tableTypeMappingSeq,sorted, indexKey)
			end    

			#puts ">>>Returning productDefinitionTableList of size: #{productDefinitionTableList.size}"
			return productDefinitionTableList
		end
		###################################################################################################


		def self.loadProductDefinitionTableListByTableTypeMappingSeq(tableTypeMappingSeq, sorted, indexKey=nil)
			#puts ">>>loadProductDefinitionTableListByTableTypeMappingSeq tableTypeMappingSeq: #{tableTypeMappingSeq} sorted: #{sorted}"
			productDefinitionTableList = nil
			actualTableTypeMappingSeq = tableTypeMappingSeq
			# dtvDtl = DefinitionTableVersionDtl.loadObject(:first, :conditions=>{{:name=>'tableTypeMappingSeq'}=>actualTableTypeMappingSeq})
			# if dtvDtl
			# 	if dtvDtl
			# 		dtvHdr = DefinitionTableVersionHdr.loadObject(:first, :conditions=>{{:name=>'object'}=>dtvDtl.parentKey})
			# 		now = Time.new
			# 		dtvHdr.DefinitionTableVersionDtlList.each do |dtvDtl|
			# 			actualTableTypeMappingSeq = dtvDtl.tableTypeMappingSeq if MobiSys::ProductUtil.getDBDateTime(dtvDtl.effectiveFromDt) <= now and MobiSys::ProductUtil.getDBDateTime(dtvDtl.effectiveToDt) >= now
			# 		end
			# 	end
			# end
			#puts ">>>actual tableTypeMappingSeq considering versions: #{actualTableTypeMappingSeq}"
			if sorted
				if indexKey
					productDefinitionTableList = ProductDefinitionTable.loadObject( :all, :conditions => {{ :name => 'tableTypeMappingSeq'} => actualTableTypeMappingSeq, {:name => 'indexKey'} => indexKey}, :op => 'AND', :order=>'definitionTableSeq',:orderdir=>'ASC')
				else
					productDefinitionTableList = ProductDefinitionTable.loadObject( :all, :conditions => {{ :name => 'tableTypeMappingSeq'} => actualTableTypeMappingSeq}, :order=>'definitionTableSeq',:orderdir=>'ASC')
				end
			else
				if indexKey
					productDefinitionTableList = ProductDefinitionTable.loadObject( :all, :conditions => {{ :name => 'tableTypeMappingSeq'} => actualTableTypeMappingSeq, {:name => 'indexKey'} => indexKey}, :op => 'AND')
				else
					productDefinitionTableList = ProductDefinitionTable.loadObject( :all, :conditions => {{ :name => 'tableTypeMappingSeq'} => actualTableTypeMappingSeq})
				end  
			end
			#puts ">>>Returning productDefinitionTableList of size: #{productDefinitionTableList.size}" 
			if productDefinitionTableList
				productDefinitionTableList.sort_by!{ |m| m.associationRelationCd}
				return productDefinitionTableList
			else
				tableTypeConditionDOList = getTableTypeConditions(tableTypeMappingSeq)
				if (tableTypeConditionDOList && tableTypeConditionDOList.size==1 && tableTypeConditionDOList[0].modelCd.to_s != '')
					illustrationModel = nil
					productDefinitionTableList = nil
					illustrationModel = IllustrationModel.loadObject(:first, :conditions => {{:name => 'modelCd'} => tableTypeConditionDOList[0].modelCd})
					if illustrationModel
						productModelDesicionTableList = ProductModelDecisionTable.loadObject( :all, :conditions => {{ :name => 'illustrationModelSeq'} => illustrationModel.id})
						productModelDesicionTableList.each do |pmdt|
							newProductDefinitionTable =  ProductDefinitionTable.new
						    illustrationFacet =	illustrationModel.getIllustrationFacet("associationRelationCd")
						    if illustrationFacet
						    	colName = illustrationFacet.dtColumnNames
						    	dtValue = pmdt.send colName	
						    	if dtValue
						    		newProductDefinitionTable.associationRelationCd = dtValue.to_s
						    		productDefinitionTableList = Array.new if !productDefinitionTableList.is_a?(Array)
						    		productDefinitionTableList.push(newProductDefinitionTable)
						    	end
						    end
						end					
					end
				end
			
				return productDefinitionTableList
			end
		end
		###################################################################################################
		def self.loadProductDefinitionTableListForRidersByTableTypeMappingSeq(tableTypeMappingSeq, sorted, indexKey=nil)
			puts ">>>loadProductDefinitionTableListForRidersByTableTypeMappingSeq tableTypeMappingSeq: #{tableTypeMappingSeq} sorted: #{sorted} indexKey: #{indexKey}"
            RhoLog::error("listDefinitionTable",  "tableTypeMappingSeq>>#{tableTypeMappingSeq}")
			productDefinitionTableList = nil
			actualTableTypeMappingSeq = tableTypeMappingSeq
			if sorted
				if indexKey
					productDefinitionTableList = ProductDefinitionTable.loadObject( :all, :conditions => {{ :name => 'tableTypeMappingSeq'} => actualTableTypeMappingSeq, {:name => 'indexKey'} => indexKey}, :op => 'AND', :order=>'definitionTableSeq',:orderdir=>'ASC')
				else
					productDefinitionTableList = ProductDefinitionTable.loadObject( :all, :conditions => {{ :name => 'tableTypeMappingSeq'} => actualTableTypeMappingSeq}, :order=>'definitionTableSeq',:orderdir=>'ASC')
				end
			else
				if indexKey
					productDefinitionTableList = ProductDefinitionTable.loadObject( :all, :conditions => {{ :name => 'tableTypeMappingSeq'} => actualTableTypeMappingSeq, {:name => 'indexKey'} => indexKey}, :op => 'AND')
				else
					productDefinitionTableList = ProductDefinitionTable.loadObject( :all, :conditions => {{ :name => 'tableTypeMappingSeq'} => actualTableTypeMappingSeq})
				end  
			end
			puts ">>>Returning productDefinitionTableList of size: #{productDefinitionTableList.size}" 
			if productDefinitionTableList.size > 0
				productDefinitionTableList.sort_by!{ |m| m.associationRelationCd}
				return productDefinitionTableList
			else
				tableTypeConditionDOList = getTableTypeConditions(tableTypeMappingSeq)
				if (tableTypeConditionDOList && tableTypeConditionDOList.size==1 && tableTypeConditionDOList[0].modelCd.to_s != '')
					illustrationModel = nil
					productDefinitionTableList = nil
					illustrationModel = IllustrationModel.loadObject(:first, :conditions => {{:name => 'modelCd'} => tableTypeConditionDOList[0].modelCd})
					if illustrationModel
						productModelDesicionTableList = ProductModelDecisionTable.loadObject( :all, :conditions => {{ :name => 'illustrationModelSeq'} => illustrationModel.id})
						productModelDesicionTableList.each do |pmdt|
							newProductDefinitionTable =  ProductDefinitionTable.new
						    illustrationFacet =	illustrationModel.getIllustrationFacet("associationRelationCd")
						    RhoLog::error("listDefinitionTable",   "illustrationFacet :- #{illustrationFacet.inspect}")
						    if illustrationFacet
						    	colName = illustrationFacet.dtColumnNames
						    	RhoLog::error("listDefinitionTable",   "colName :- #{colName.inspect}")
						    	dtValue = pmdt.send colName	
						    	RhoLog::error("listDefinitionTable",   "dtValue :- #{dtValue.inspect}")
						    	if dtValue
						    		newProductDefinitionTable.associationRelationCd = dtValue.to_s
						    		productDefinitionTableList = Array.new if !productDefinitionTableList.is_a?(Array)
						    		RhoLog::error("listDefinitionTable",   "newProductDefinitionTable :- #{newProductDefinitionTable.inspect}")
						    		productDefinitionTableList.push(newProductDefinitionTable)
						    		RhoLog::error("listDefinitionTable",   "productDefinitionTableList :- #{productDefinitionTableList.inspect}")
						    	end
						    end
						end					
					end
				end
				RhoLog::error("listDefinitionTable",   "~~~~productDefinitionTableList:#{productDefinitionTableList}")
				return productDefinitionTableList
			end
		end


		def self.createFieldValue( evaluatedValue, elementLabel, displayColumnOrder )
			fieldValue = Hash.new

			fieldValue["value"] = evaluatedValue
			fieldValue["label"] = elementLabel
			fieldValue["sortOrder"] = displayColumnOrder

			return fieldValue
		end
		###################################################################################################


		def self.getFrequencyMultiplier( frequencyCd )
			multiplier = 0

			if "YEARLY" == frequencyCd
				multiplier = 1
			elsif "MONTHLY" == frequencyCd
				multiplier = 12
			elsif "HALFYEARLY" == frequencyCd
				multiplier = 2
			elsif "QUARTERLY" == frequencyCd
				multiplier = 4   
			elsif "SINGLE" == frequencyCd
				multiplier = 1
			end

			return multiplier
		end
		###################################################################################################


		def self.getDBDateTime(screenDateTime)
			dateTime = nil
			if screenDateTime != nil && screenDateTime != "" 
				dateTimeParts = screenDateTime.split(" ")
				dateParts = dateTimeParts[0].split("-")
				timeParts = dateTimeParts[1].split(":")

				year = dateParts[0].to_i
				month = dateParts[1].to_i
				day = dateParts[2].to_i

				hours = timeParts[0].to_i
				minutes = timeParts[1].to_i
				secondParts = timeParts[2].split(".")
				seconds = secondParts[0].to_i
				milliSeconds = secondParts[1].to_i

				dateTime = Time.new(year, month, day, hours, minutes, seconds)
			end

			return dateTime
		end
		###################################################################################################


=begin    
		def self.stampStepTime(startTime,stepStr)
			endTime = Time.now
			puts "@@@\t #{stepStr} \t #{endTime-startTime}"
		end
=end


		def self.stampStepTime(startTime,stepStr)
			$messages ||= Array.new
			endTime = Time.now
			$messages.push "#{stepStr} \t #{endTime-startTime}"
		end
		###################################################################################################


		def self.getTableTypeConditions(tableTypeMappingSeq)
			$dtFilters ||= Hash.new
			tableTypeConditions = $dtFilters[tableTypeMappingSeq]
			unless tableTypeConditions
				#Swati Ahire 17-06-2014: Changed sortOrderKey to sortOrderForKey
				tableTypeConditions = OfflineTableTypeCondition.loadObject(:all,:conditions=>{{:name=>'tableTypeMappingSeq'}=>tableTypeMappingSeq},:order=>'sortOrderForKey')
				$dtFilters[tableTypeMappingSeq] = tableTypeConditions
			end
			return tableTypeConditions
		end
		###################################################################################################


		def self.getDTConditions(tableTypeMappingSeq)
			classArray = Array.new
			tableTypeConditions = getTableTypeConditions(tableTypeMappingSeq)
			tableTypeConditions.each do |condition|
				next if condition.fixedDynamicCondTypeCd == "DYNAMIC" or (@enableCache and condition.cacheCondition == 'YES')
				case condition.rangeValueFl
				when "RANGE"
					next unless Object.const_defined?(condition.condition.upcase << "RANGE",false)
					classArray.push Object.const_get(condition.condition.upcase << "RANGE")
				when "VALUE", "VALUEEQUALS"
					next unless Object.const_defined?(condition.condition.upcase.to_s, false)
					classArray.push Object.const_get(condition.condition.upcase.to_s)
				else
					# next unless Object.const_defined?(condition.condition.upcase << "RANGE",false) && Object.const_defined?(condition.condition.upcase.to_s,false)
					classArray.push Object.const_get(condition.condition.upcase << "RANGE")
					classArray.push Object.const_get(condition.condition.upcase.to_s)
				end
			end
			return classArray
		end
		###################################################################################################


		def self.getIndexKey(tableTypeMappingSeq, quotation, quotationProduct, party)
			indexKey = ""
			valueClassList = getValueClasses(tableTypeMappingSeq)
			return nil unless valueClassList.size > 0
			valueClassList.each do |valueClass|
				if(valueClass.to_s.include? "_DYNAMIC")
					valueClass = valueClass.gsub("_DYNAMIC", "")
					value = @modelResultDO.getFieldValue(valueClass) if @modelResultDO
					quotation.entityDesc += "," + MobiSys::BrowserHelper.getLabel(valueClass) + "("
				else
					value = valueClass.send(:getValue,quotation,quotationProduct,party)
				end
				indexKey << value.to_s << '|' if value
				quotation.entityDesc += MobiSys::BrowserHelper.getLabel(value.to_s) + ")" if value
			end
			indexKey = indexKey[0,indexKey.length-1] if indexKey.end_with? '|'
		end
		###################################################################################################


		def self.getValueClasses(tableTypeMappingSeq)
			$valueClasses ||= Hash.new
			valueClasses = $valueClasses[tableTypeMappingSeq]
			unless valueClasses
				tableTypeConditions = getTableTypeConditions(tableTypeMappingSeq)
				valueClasses = Array.new
				tableTypeConditions.each do |ttc|
					next unless ttc.cacheCondition == "YES"
					case ttc.rangeValueFl
					when "VALUE", "VALUEEQUALS"
						if ttc.fixedDynamicCondTypeCd == "DYNAMIC"
							valueClasses.push (ttc.condition + "_DYNAMIC")
						else
							next unless Object.const_defined?(ttc.condition.upcase.to_s << "VALUE", false)
							valueClasses.push Object.const_get(ttc.condition.upcase.to_s << "VALUE")
						end
					end
				end
				$valueClasses[tableTypeMappingSeq] = valueClasses
			end
			return valueClasses
		end
		###################################################################################################


		def self.resetProductCache
			ProductCache.each do |key, value|
				ProductCache[key] = nil
				ProductCache.delete(key)
			end
		end
		###################################################################################################


		def self.getApplicableProducts(baseDO)
			productFamilyHash = {}
			productIdHash = {}
			productVersionHash = {}
			productPlanOptionHash = {}
			prdSelectionProductHash = {}
			prdSelectionProductIdList = nil
			# Fetching record from OfflineApplication table for ENVIRONMENT type
			offlineApplicationEnvironmentRecord = OfflineApplication.find(
				:first,
				:conditions => {
					{ :name => 'PROPERTY' } => 'ENVIRONMENT'
				}
			)

			if offlineApplicationEnvironmentRecord != nil
				offlineApplicationEnvironmentRecord.value = "PRODUCTION" if offlineApplicationEnvironmentRecord.value.to_s == ""
			else
				offlineApplicationEnvironmentRecord = OfflineApplication.new
				offlineApplicationEnvironmentRecord.property = 'ENVIRONMENT'
				offlineApplicationEnvironmentRecord.value = "PRODUCTION"
			end
			offlineApplicationEnvironment = offlineApplicationEnvironmentRecord.value.to_s

			# Applicable products base on PRDSELECTION Company Facet
			$prdSelectionFacet ||= $rhoconfig[:prdSelection]
			prdSelectionFacetValue = getCompanyFacetValue($prdSelectionFacet)
			if prdSelectionFacetValue.to_s != "" && !prdSelectionFacetValue.to_s.match(/[A-Za-z]/)
				if baseDO.class.name.to_s == "Policy"
					quotation = MobiSys::PolicyBO.convertToQuotation(baseDO)
				else
					quotation = baseDO
				end
				quotationBasePlan = quotation.getBaseProduct
				party = quotation.getPartyByRole("PRIMARY")
				if quotationBasePlan
					quotationBasePlan.combinedEntryAge = party.age.to_i if party
					prdSelectionDtList = getProductDefinitionTableDO(prdSelectionFacetValue.to_s, quotation, quotationBasePlan, party, true, true)
					if prdSelectionDtList.size > 0
						prdSelectionDtList.each do |prdSelectionDt|
							tempProductIdList = []
							results = MobiSys::DataObjects::Results.new
							if (prdSelectionDt.outputAction and prdSelectionDt.outputAction != "")
								results.createAttr("quotation")
								results.quotation = quotation
								results.createAttr("quotationProduct")
								results.quotationProduct = quotationBasePlan
								results.createAttr("basePlan")
								results.basePlan = quotation.getBaseProduct()
								results.createAttr("mainRider")
								results.mainRider = quotation.getMainRider(results.quotationProduct)
							end

							if prdSelectionDt.outputAction.to_s != ""
								results.defineMethod("outputActionValue",prdSelectionDt.outputAction)
								outputActionValue = results.outputActionValue
							end

							if outputActionValue.to_s.include?"["
								outputActionValue.to_s.split('],[').each do |elem|
									elem1 = elem.gsub('[', "")
									elem1 = elem1.gsub(']', "")
									if prdSelectionProductHash.has_key?(elem1.split(":")[0]) 
										prdSelectionProductHash[elem1.split(":")[0]] = prdSelectionProductHash[elem1.split(":")[0]] | elem1.split(":")[1].to_s.split(',')
									else
										prdSelectionProductHash[elem1.split(":")[0]] = elem1.split(":")[1].to_s.split(',')
									end

								end
								tempProductIdList = prdSelectionProductHash.keys
							else
								tempProductIdList = outputActionValue.to_s.split(',')
							end
							
							if prdSelectionProductIdList != nil && prdSelectionProductIdList.is_a?(Array)
								prdSelectionProductIdList += tempProductIdList
							else
								prdSelectionProductIdList = tempProductIdList
							end
						end
					else
						prdSelectionProductIdList = []
					end
				end
			elsif prdSelectionFacetValue.to_s != "" && prdSelectionFacetValue.to_s.match(/[A-Za-z]/)
				#modelSet evaluation code here.
				policyModelSet = nil
				prdSelectionProductIdList = []
				policyModelSet = PolicyUtil::ModelUtil.getModelSet(prdSelectionFacetValue.to_s)
				begin
					if policyModelSet
						if baseDO.class.name.to_s == "Quotation"
							policy = MobiSys::PolicyBO.convertToPolicy(baseDO)
						else
							policy = baseDO
						end
						party = policy.getParty("PRIMARY")
						party.policyYear = policy.policyYear
						policyProduct = policy.getBaseProduct if policy
						policyModelSet.ModelSetModelMapList.each do |modelSetModelMap|
							policyModel = PolicyUtil::PolicyModel.new
							modelResultDO = policyModel.execute(policy, policyProduct, party, modelSetModelMap.modelCd)
							if(modelResultDO == nil)
							 	next
							end
						  	prdSelectionProductCd = modelResultDO.getFieldValue("prdSelectionProductCd");
						  	if prdSelectionProductCd.to_s != ""
							  	prdSelectionProductPlanOptionCd = modelResultDO.getFieldValue("prdSelectionProductPlanOptionCd");
							  	prdSelectionProductIdList += prdSelectionProductCd.to_s.split(',') if prdSelectionProductCd.to_s != ""
							  	if prdSelectionProductPlanOptionCd.to_s != ""
								  	if prdSelectionProductHash.has_key?(prdSelectionProductCd) 
										prdSelectionProductHash[prdSelectionProductCd] = prdSelectionProductHash[prdSelectionProductCd] | prdSelectionProductPlanOptionCd.to_s.split(',')
									else
										prdSelectionProductHash[prdSelectionProductCd] = prdSelectionProductPlanOptionCd.to_s.split(',')
									end
								end
							else 
						  		prdSelectionMultiProductCumPlanOptionCd = modelResultDO.getFieldValue("prdSelectionMultiProductCumPlanOptionCd");
								if prdSelectionMultiProductCumPlanOptionCd.to_s.include?"["
									prdSelectionMultiProductCumPlanOptionCd.to_s.split('],[').each do |elem|
										elem1 = elem.gsub('[', "")
										elem1 = elem1.gsub(']', "")
										if prdSelectionProductHash.has_key?(elem1.split(":")[0]) 
											prdSelectionProductHash[elem1.split(":")[0]] = prdSelectionProductHash[elem1.split(":")[0]] | elem1.split(":")[1].to_s.split(',')
										else
											prdSelectionProductHash[elem1.split(":")[0]] = elem1.split(":")[1].to_s.split(',')
										end

									end
									tempProductIdList = prdSelectionProductHash.keys
								else
									tempProductIdList = prdSelectionMultiProductCumPlanOptionCd.to_s.split(',')
								end
								if prdSelectionProductIdList != nil && prdSelectionProductIdList.is_a?(Array)
									prdSelectionProductIdList += tempProductIdList
								else
									prdSelectionProductIdList = tempProductIdList
								end
							end
						end
					end
				rescue Exception => e
					puts "Error in policy model set evaluation --->#{e}\n#{e.backtrace}"
				end
			end

			# Applicable products for user/agent
			agentProductIdList = AgentReg.getCurrentAgentReg.applicableProducts.split(',')
			
			if prdSelectionProductIdList
				agentProductIdList = agentProductIdList & prdSelectionProductIdList
			end
			# Fetching applicable products
			applicableProducts = Product.loadObject(
				:all,
				:conditions => {
					{:name => 'productTypeCd'} => "PLAN",
					{:name => 'productId', :op => 'IN'} => agentProductIdList
				},
				:op => 'AND'
			)
			applicableProductFamilyIdList = []
			applicableProducts.each do |applicableProduct|
				validProduct = true
				validProduct = false if applicableProduct.getFacetValue('SINOTAPPLICABLE').to_s == "YES"

				if offlineApplicationEnvironment == "UAT"
					validProduct = true
				else
					# launchDt & withdrawDt validation
					if applicableProduct.launchDt.to_s != "" && Time.parse(applicableProduct.launchDt.to_s) <= Time.now
						if (applicableProduct.withdrawDt.to_s != '' && Time.parse(applicableProduct.withdrawDt.to_s) >= Time.now) || (applicableProduct.withdrawDt.to_s == '')
							validProduct = true
						else
							validProduct = false
						end
					else
						validProduct = false
					end
				end

				if validProduct
					applicableProductFamilyIdList.push(applicableProduct.productFamilyId)
					
					# Populating Product Hash
					productIdHash[applicableProduct.productFamilyId.to_sym] ||= []
					productIdLookup = {
						:id => applicableProduct.id.to_s,
						:key => applicableProduct.productId.to_s.strip,
						:value => MobiSys::BrowserHelper.getLabel(applicableProduct.longName.to_s).strip,
						:sortOrder => applicableProduct.sortOrder.to_s.strip
					}
					productIdHash[applicableProduct.productFamilyId.to_sym].push(productIdLookup)
					productIdHash[applicableProduct.productFamilyId.to_sym].uniq!{|x| x[:key]}
					productIdHash[applicableProduct.productFamilyId.to_sym].sort_by!{|x| x[:value]}

					# Populating Product Version Hash
					if offlineApplicationEnvironment == "UAT"
						productVersionHash[applicableProduct.productId.to_s.to_sym] ||= []
						productVersionLookup = {
							:id => applicableProduct.id.to_s,
							:key => applicableProduct.id.to_s.strip,
							:value => MobiSys::BrowserHelper.getLabel(applicableProduct.versionName.to_s).strip
						}
						productVersionHash[applicableProduct.productId.to_s.to_sym].push(productVersionLookup)
						productVersionHash[applicableProduct.productId.to_s.to_sym].uniq!{|x| x[:id]}
						productVersionHash[applicableProduct.productId.to_s.to_sym].sort_by!{|x| x[:value]}
					end

					# Populating Product Plan Option Hash
					applicableProduct.OfflineFacetList.each do |offlineFacet|
						if offlineFacet.facetId.to_s == 'PLANOPTION'
							productPlanOptionHash[applicableProduct.id.to_s.to_sym] ||= []
							offlineFacet.OfflinePlanOptionList.each do |offlinePlanOption|
								if prdSelectionProductHash[applicableProduct.productId] == nil || prdSelectionProductHash[applicableProduct.productId].empty?
									offlinePlanOptionLookup = {
										:id => offlinePlanOption.optionCd.to_s,
										:key => offlinePlanOption.optionCd.to_s.strip,
										:value => MobiSys::BrowserHelper.getLabel(offlinePlanOption.description.to_s).strip,
										:sortOrder => offlinePlanOption.sortOrder.to_s.strip,
										:SA => offlinePlanOption.defaultSumAssured.to_s.strip
									}
									productPlanOptionHash[applicableProduct.id.to_s.to_sym].push(offlinePlanOptionLookup)
								elsif prdSelectionProductHash[applicableProduct.productId].include? offlinePlanOption.optionCd
									offlinePlanOptionLookup = {
										:id => offlinePlanOption.optionCd.to_s,
										:key => offlinePlanOption.optionCd.to_s.strip,
										:value => MobiSys::BrowserHelper.getLabel(offlinePlanOption.description.to_s).strip,
										:sortOrder => offlinePlanOption.sortOrder.to_s.strip,
										:SA => offlinePlanOption.defaultSumAssured.to_s.strip
									}
									productPlanOptionHash[applicableProduct.id.to_s.to_sym].push(offlinePlanOptionLookup)
								end
							end
							productPlanOptionHash[applicableProduct.id.to_s.to_sym].uniq!{|x| x[:id]}
							productPlanOptionHash[applicableProduct.id.to_s.to_sym].sort_by!{|a| a[:sortOrder].upcase}

							break
						end
					end
				end
			end

			applicableProductFamilies = ProductFamily.find(
				:all,
				:conditions => {
					{:name => 'productFamilyId', :op => 'IN'} => applicableProductFamilyIdList
				},
			)
			applicableProductFamilies.each do |productFamily|
				productFamilyHash[productFamily.productFamilyId.to_s.to_sym] ||= []
				productFamilyLookup = {
					:id => productFamily.productFamilyId.to_s,
					:key => productFamily.productFamilyId.to_s.strip,
					:value => MobiSys::BrowserHelper.getLabel(productFamily.description.to_s).strip,
					:sortOrder => productFamily.sortOrder.to_s.strip
				}
				productFamilyHash[productFamily.productFamilyId.to_s.to_sym].push(productFamilyLookup)
			end

			productFamilyHashArray = []
			productFamilyHash.each do |key,value|
				productFamilyHashArray << value[0]
			end

			productFamilyHash = {}

			productFamilyHashArraySorted = []
			if productFamilyHashArray and productFamilyHashArray.size > 0
				sortByOrderFamilies,remainingFamilies = productFamilyHashArray.partition{|family| family[:sortOrder].to_s != ""}
				sortByOrderFamilies.sort_by!{|family| family[:sortOrder].to_i} if sortByOrderFamilies.size > 0
				remainingFamilies.sort!{|a, b| a[:value].to_s <=> b[:value].to_s} if remainingFamilies.size > 0
				productFamilyHashArraySorted = sortByOrderFamilies.concat remainingFamilies
			end

			productFamilyHashArraySorted.each do |family|
				arrayWrapper = []
				arrayWrapper << family
				productFamilyHash[(family[:key]).to_sym] = arrayWrapper
			end

			productIdHash.each do |key,value|
				if value && value.size > 0
					sortByOrderProducts,remainingProducts = value.partition{|product| product[:sortOrder].to_s != ""}
					sortByOrderProducts.sort_by!{|product| product[:sortOrder].to_i} if sortByOrderProducts.size > 0
					remainingProducts.sort!{|a, b| a[:value].to_s <=> b[:value].to_s} if remainingProducts.size > 0
					productIdHash[key] = sortByOrderProducts.concat remainingProducts
				end
			end

			return offlineApplicationEnvironment,productFamilyHash,productIdHash,productVersionHash,productPlanOptionHash
		end
		##########################################################################################
		
		def self.getCompanyFacetValue(facetDO)
			actionValue = nil
			if facetDO
				if(facetDO.actionTypeCd.to_s == "VALUE" || facetDO.actionTypeCd.to_s == "LOOKUP")
					actionValue = facetDO.actionValue
				elsif facetDO.actionTypeCd.to_s == "RULE"
					actionValue = facetDO.ruleSeq
				end
			end
			return actionValue
		end
		##########################################################################################

		def self.getApplicableProductsForApi(baseDO)
			productFamilyList = []
			productIdHash = {}
			# productVersionHash = {}
			productPlanOptionHash = {}
			prdSelectionProductHash = {}
			prdSelectionProductIdList = nil
			quotation = nil
			quotationBasePlan = nil
			# Fetching record from OfflineApplication table for ENVIRONMENT type
			offlineApplicationEnvironmentRecord = OfflineApplication.find(
				:first,
				:conditions => {
					{ :name => 'PROPERTY' } => 'ENVIRONMENT'
				}
			)

			if offlineApplicationEnvironmentRecord != nil
				offlineApplicationEnvironmentRecord.value = "PRODUCTION" if offlineApplicationEnvironmentRecord.value.to_s == ""
			else
				offlineApplicationEnvironmentRecord = OfflineApplication.new
				offlineApplicationEnvironmentRecord.property = 'ENVIRONMENT'
				offlineApplicationEnvironmentRecord.value = "PRODUCTION"
			end
			offlineApplicationEnvironment = offlineApplicationEnvironmentRecord.value.to_s

			# Applicable products base on PRDSELECTION Company Facet
			$prdSelectionFacet ||= $rhoconfig[:prdSelection]
			prdSelectionFacetValue = getCompanyFacetValue($prdSelectionFacet)
			# Applicable products for user/agent
			agentProductIdList = AgentReg.getCurrentAgentReg.applicableProducts.split(',')

			prdSelectionProductHash, applicableProducts = filterProducts(baseDO, prdSelectionFacetValue, agentProductIdList) if prdSelectionFacetValue.to_s != ""

			applicableProductFamilyIdList = []
			productFamilyMap = {}

			applicableProducts.each do |applicableProduct|
				productCollateralMap = {}
				validProduct = true
				validProduct = false if applicableProduct.getFacetValue('SINOTAPPLICABLE').to_s == "YES"

				if offlineApplicationEnvironment == "UAT"
					validProduct = true
				else
					# launchDt & withdrawDt validation
					if applicableProduct.launchDt.to_s != "" && Time.parse(applicableProduct.launchDt.to_s) <= Time.now
						if (applicableProduct.withdrawDt.to_s != '' && Time.parse(applicableProduct.withdrawDt.to_s) >= Time.now) || (applicableProduct.withdrawDt.to_s == '')
							validProduct = true
						else
							validProduct = false
						end
					else
						validProduct = false
					end
				end

				if validProduct
					applicableProductFamilyIdList.push(applicableProduct.productFamilyId)
					
					# Populating Product Hash
					productIdHash[applicableProduct.productFamilyId.to_sym] ||= []
					productIdLookup = {
						:id => applicableProduct.id.to_s,
						:cd => applicableProduct.productId.to_s.strip,
						:desc => MobiSys::BrowserHelper.getLabel(applicableProduct.longName.to_s).strip,
						:version => applicableProduct.productVersion.to_s.strip,
						:versionName => applicableProduct.versionName.to_s.strip,
						:sortOrder => applicableProduct.sortOrder.to_s.strip
					} 
					productCollateralMap[applicableProduct.productFamilyId] = applicableProduct.collateralLevelCd if applicableProduct.collateralLevelCd.to_s != ""

					#Collateral Data
					collateralLevelCd = productCollateralMap[applicableProduct.productFamilyId]
					if collateralLevelCd.to_s != ""
						collateralRenderLevel = CollateralRenderLevel.find(:first,:conditions => {:levelCd => collateralLevelCd})
						if collateralRenderLevel != nil
							productIdLookup["text"] = MobiSys::BrowserHelper.getLabel(collateralRenderLevel.header1.to_s).strip
							if collateralRenderLevel.contentPart1TypeCd.to_s == "HTML" and collateralRenderLevel.contentPart1.to_s != ""
								productIdLookup["learnHtmlText"] = MobiSys::BrowserHelper.getLabel(collateralRenderLevel.contentPart1.to_s).strip 
							end
							collateralCdToFind = []
							collateralCdToFind.push(collateralRenderLevel.contentPart1) if(collateralRenderLevel.contentPart1TypeCd.to_s == "MEDIA" and collateralRenderLevel.contentPart1.to_s != "")
							collateralCdToFind.push(collateralRenderLevel.contentPart2) if(collateralRenderLevel.contentPart2TypeCd.to_s == "MEDIA" and collateralRenderLevel.contentPart2.to_s != "")
							collateralCdToFind.push(collateralRenderLevel.icon) if collateralRenderLevel.icon.to_s != ""
							if collateralCdToFind.size > 0
								collateralList = Collateral.find(
									:all,
									:conditions => {
										{:name => "collateralCd", :op => 'IN'} => collateralCdToFind
									},
								)
								collateralMap = CommonUtil.getLinkedHashedList("collateralCd",collateralList)
								collateral = collateralMap[collateralRenderLevel.icon]
								productIdLookup["image"] = collateral.first.fileName if collateral 
								collateral = collateralMap[collateralRenderLevel.contentPart1]
								productIdLookup["media"] = collateral.first.fileName if collateral
								collateral = collateralMap[collateralRenderLevel.contentPart2]
								productIdLookup["pdf"] = collateral.first.fileName if collateral
							end
							if collateralRenderLevel.footer1.to_s != ""
								productIdLookup["footer"] = collateralRenderLevel.footer1.to_s
							end
							if collateralRenderLevel.header2.to_s != ""
								productIdLookup["header"] = collateralRenderLevel.header2.to_s
							end
						end
					end

					productIdHash[applicableProduct.productFamilyId.to_sym].push(productIdLookup)
					productIdHash[applicableProduct.productFamilyId.to_sym].uniq!{|x| x[:cd]}
					productIdHash[applicableProduct.productFamilyId.to_sym].sort_by!{|x| x[:value]}
					
					# Populating Product Version Hash
					# if offlineApplicationEnvironment == "UAT"
					# 	productVersionHash[applicableProduct.productId.to_s.to_sym] ||= []
					# 	productVersionLookup = {
					# 		:id => applicableProduct.id.to_s,
					# 		:cd => applicableProduct.id.to_s.strip,
					# 		:value => MobiSys::BrowserHelper.getLabel(applicableProduct.versionName.to_s).strip
					# 	}
					# 	productVersionHash[applicableProduct.productId.to_s.to_sym].push(productVersionLookup)
					# 	productVersionHash[applicableProduct.productId.to_s.to_sym].uniq!{|x| x[:id]}
					# 	productVersionHash[applicableProduct.productId.to_s.to_sym].sort_by!{|x| x[:value]}
					# end

					# Populating Product Plan Option Hash
					populateProductPlanOptions(applicableProduct, prdSelectionProductHash, productPlanOptionHash)
				end
			end
			productIdHash.each_value do |family|
				family.collect{|element| 
					element.select!{|x| 
						x != :sortOrder
					}
				}
			end
			
			applicableInsuranceTypeCdList, applicableProductFamilies = [], []
			applicableInsuranceTypeCdList << baseDO.insuranceTypeCd.to_s
			applicableInsuranceTypeCdList << "" if baseDO.insuranceTypeCd.to_s == "LIFE"
			
			ProductFamily.find(:all).each do |productFamily|
				if applicableProductFamilyIdList.include?(productFamily.productFamilyId.to_s) && applicableInsuranceTypeCdList.include?(productFamily.insuranceTypeCd.to_s)
					applicableProductFamilies << productFamily
				end
 			end

			applicableProductFamilies.each do |productFamily|
				productFamilyCollateralMap = {}
				productFamilyLookup = {
					:cd => productFamily.productFamilyId.to_s.strip,
					# :key => productFamily.productFamilyId.to_s.strip,
					:desc => MobiSys::BrowserHelper.getLabel(productFamily.description.to_s).strip,
					:sortOrder => productFamily.sortOrder.to_s.strip
				}
				
				productFamilyCollateralMap[productFamily.productFamilyId.to_s.strip] = productFamily.collateralLevelCd if productFamily.collateralLevelCd.to_s != ""
				#productFamilyMap[productFamily.productFamilyId.to_s.strip] = MobiSys::BrowserHelper.getLabel(productFamily.description.to_s).strip

				#Collateral Data
				collateralLevelCd = productFamilyCollateralMap[productFamily.productFamilyId.to_s.strip]

				if collateralLevelCd.to_s != ""
					collateralRenderLevel = CollateralRenderLevel.find(:first,:conditions => {:levelCd => collateralLevelCd})
					if collateralRenderLevel != nil
						text = ((collateralRenderLevel.contentPart1TypeCd.to_s == "HTML" and collateralRenderLevel.contentPart1.to_s != "") ? collateralRenderLevel.contentPart1 : collateralRenderLevel.header1)
						productFamilyLookup["text"] = text

						collateralCdToFind = []
						collateralCdToFind.push(collateralRenderLevel.contentPart1) if(collateralRenderLevel.contentPart1TypeCd.to_s == "MEDIA" and collateralRenderLevel.contentPart1.to_s != "")
						collateralCdToFind.push(collateralRenderLevel.icon) if collateralRenderLevel.icon.to_s != ""
						if collateralCdToFind.size > 0
							collateralList = Collateral.find(
								:all,
								:conditions => {
									{:name => "collateralCd", :op => 'IN'} => collateralCdToFind
								},
							)
							collateralMap = CommonUtil.getLinkedHashedList("collateralCd",collateralList)
							collateral = collateralMap[collateralRenderLevel.icon]
							productFamilyLookup["image"] = collateral.first.fileName if collateral 
							collateral = collateralMap[collateralRenderLevel.contentPart1]
							productFamilyLookup["media"] = collateral.first.fileName if collateral
						end
					end
				end

				productFamilyList.push(productFamilyLookup)
			end

			# productFamilyHashArray = []
			# productFamilyHash.each do |key,value|
			# 	productFamilyHashArray << value[0]
			# end

			# productFamilyHash = {}

			# productFamilyList = []
			if productFamilyList and productFamilyList.size > 0
				sortByOrderFamilies,remainingFamilies = productFamilyList.partition{|family| family[:sortOrder].to_s != ""}
				sortByOrderFamilies.sort_by!{|family| family[:sortOrder].to_i} if sortByOrderFamilies.size > 0
				remainingFamilies.sort!{|a, b| a[:value].to_s <=> b[:value].to_s} if remainingFamilies.size > 0
				productFamilyList = sortByOrderFamilies.concat remainingFamilies
				productFamilyList.collect{|element| 
					element.select!{|x| 
						x != :sortOrder
					}
				}
			end

			# productFamilyHashArraySorted.each do |family|
			# 	arrayWrapper = []
			# 	arrayWrapper << family
			# 	productFamilyHash[(family[:key]).to_sym] = arrayWrapper
			# end

			productIdHash.each do |key,value|
				if value && value.size > 0
					selectedProduct,value = value.partition{|product| product[:id].to_s == quotationBasePlan.productSeq.to_s} if quotationBasePlan
					sortByOrderProducts,remainingProducts = value.partition{|product| product[:sortOrder].to_s != ""}
					sortByOrderProducts.sort_by!{|product| product[:sortOrder].to_i} if sortByOrderProducts.size > 0
					remainingProducts.sort!{|a, b| a[:desc].to_s.upcase <=> b[:desc].to_s.upcase} if remainingProducts.size > 0
					sortByOrderProducts = sortByOrderProducts.concat selectedProduct if selectedProduct && selectedProduct.size > 0
					productIdHash[key] = sortByOrderProducts.concat remainingProducts
				end
			end

			productPlanOptionHash.each do |key,value|
				if value && value.size > 0
					sortByOrderPlans,remainingPlans = value.partition{|plan| plan[:sortOrder].to_s != ""}
					sortByOrderPlans.sort_by!{|plan| plan[:sortOrder].to_i} if sortByOrderPlans.size > 0
					remainingPlans.sort!{|a, b| a[:value].to_s <=> b[:value].to_s} if remainingPlans.size > 0
					productPlanOptionHash[key] = sortByOrderPlans.concat remainingPlans
				end
			end

			return offlineApplicationEnvironment,productFamilyList,productIdHash,productPlanOptionHash
		end
		##########################################################################################

		def self.filterProducts(baseDO, prdSelectionFacetValue, productsByUser)
			prdSelectionProductHash = {}
			prdSelectionProductIdList = nil #prdSelectionFacetValue.to_s != "" && 

			if !prdSelectionFacetValue.to_s.match(/[A-Za-z]/)
				if baseDO.class.name.to_s == "Policy"
					quotation = MobiSys::PolicyBO.convertToQuotation(baseDO)
				else
					quotation = baseDO
				end
				quotationBasePlan = quotation.getBaseProduct
				party = quotation.getPartyByRole("PRIMARY")
				if quotationBasePlan
					quotationBasePlan.combinedEntryAge = party.age.to_i if party
					prdSelectionDtList = getProductDefinitionTableDO(prdSelectionFacetValue.to_s, quotation, quotationBasePlan, party, true, true)
					if prdSelectionDtList.size > 0
						prdSelectionDtList.each do |prdSelectionDt|
							tempProductIdList = []
							results = MobiSys::DataObjects::Results.new
							if (prdSelectionDt.outputAction and prdSelectionDt.outputAction != "")
								results.createAttr("quotation")
								results.quotation = quotation
								results.createAttr("quotationProduct")
								results.quotationProduct = quotationBasePlan
								results.createAttr("basePlan")
								results.basePlan = quotation.getBaseProduct()
								results.createAttr("mainRider")
								results.mainRider = quotation.getMainRider(results.quotationProduct)
							end

							if prdSelectionDt.outputAction.to_s != ""
								results.defineMethod("outputActionValue",prdSelectionDt.outputAction)
								outputActionValue = results.outputActionValue
							end
							if outputActionValue.to_s.include?"["
								outputActionValue.to_s.split('],[').each do |elem|
									elem1 = elem.gsub('[', "")
									elem1 = elem1.gsub(']', "")
									if prdSelectionProductHash.has_key?(elem1.split(":")[0]) 
										prdSelectionProductHash[elem1.split(":")[0]] = prdSelectionProductHash[elem1.split(":")[0]] | elem1.split(":")[1].to_s.split(',')
									else
										prdSelectionProductHash[elem1.split(":")[0]] = elem1.split(":")[1].to_s.split(',')
									end

								end
								tempProductIdList = prdSelectionProductHash.keys
							else
								tempProductIdList = outputActionValue.to_s.split(',')
							end
							
							if prdSelectionProductIdList != nil && prdSelectionProductIdList.is_a?(Array)
								prdSelectionProductIdList += tempProductIdList
							else
								prdSelectionProductIdList = tempProductIdList
							end
						end
					else
						prdSelectionProductIdList = []
					end
				end
			elsif prdSelectionFacetValue.to_s.match(/[A-Za-z]/)
				#modelSet evaluation code here.
				policyModelSet = nil
				prdSelectionProductIdList = []
				policyModelSet = PolicyUtil::ModelUtil.getModelSet(prdSelectionFacetValue.to_s)
				begin
					if policyModelSet
						if baseDO.class.name.to_s == "Quotation"
							policy = MobiSys::PolicyBO.convertToPolicy(baseDO)
						else
							policy = baseDO
						end
						party = policy.getParty("PRIMARY")
						party.policyYear = policy.policyYear
						policyProduct = policy.getBaseProduct if policy
						expressionHash = {}
						policyModelSet.ModelSetModelMapList.each do |modelSetModelMap|
							policyModel = PolicyUtil::PolicyModel.new
							modelResultDO = policyModel.execute(policy, policyProduct, party, modelSetModelMap.modelCd, nil, nil, nil, nil, nil, expressionHash)
							if(modelResultDO == nil)
							 	next
							end
						  	prdSelectionProductCd = modelResultDO.getFieldValue("prdSelectionProductCd");
						  	if prdSelectionProductCd.to_s != ""
							  	prdSelectionProductPlanOptionCd = modelResultDO.getFieldValue("prdSelectionProductPlanOptionCd");
							  	#If user has selected product, check if current product is in that list
							  	if productsByUser.size > 0 
							  		prdSelectionProductIdList += prdSelectionProductCd.to_s.split(',') if prdSelectionProductCd.to_s != ""
							  	else
							  		prdSelectionProductIdList += prdSelectionProductCd.to_s.split(',') if prdSelectionProductCd.to_s != ""
							  	end

							  	if prdSelectionProductPlanOptionCd.to_s != ""
								  	if prdSelectionProductHash.has_key?(prdSelectionProductCd) 
										prdSelectionProductHash[prdSelectionProductCd] = prdSelectionProductHash[prdSelectionProductCd] | prdSelectionProductPlanOptionCd.to_s.split(',')
									else
										prdSelectionProductHash[prdSelectionProductCd] = prdSelectionProductPlanOptionCd.to_s.split(',')
									end
								else
									if !prdSelectionProductHash.has_key?(prdSelectionProductCd) 
										prdSelectionProductHash[prdSelectionProductCd] = prdSelectionProductCd.to_s
									end
								end
							else 
						  		prdSelectionMultiProductCumPlanOptionCd = modelResultDO.getFieldValue("prdSelectionMultiProductCumPlanOptionCd");
								if prdSelectionMultiProductCumPlanOptionCd.to_s.include?"["
									prdSelectionMultiProductCumPlanOptionCd.to_s.split('],[').each do |elem|
										elem1 = elem.gsub('[', "")
										elem1 = elem1.gsub(']', "")
										if prdSelectionProductHash.has_key?(elem1.split(":")[0]) 
											prdSelectionProductHash[elem1.split(":")[0]] = prdSelectionProductHash[elem1.split(":")[0]] | elem1.split(":")[1].to_s.split(',')
										else
											prdSelectionProductHash[elem1.split(":")[0]] = elem1.split(":")[1].to_s.split(',')
										end

									end
									tempProductIdList = prdSelectionProductHash.keys
								else
									tempProductIdList = prdSelectionMultiProductCumPlanOptionCd.to_s.split(',')
								end
								if prdSelectionProductIdList != nil && prdSelectionProductIdList.is_a?(Array)
									prdSelectionProductIdList += tempProductIdList
								else
									prdSelectionProductIdList = tempProductIdList
								end
							end
						end
					end
				rescue Exception => e
					puts "Error in policy model set evaluation --->#{e}\n#{e.backtrace}"
				end
			end

			agentProductIdList = productsByUser
			if prdSelectionProductIdList && agentProductIdList
				agentProductIdList = agentProductIdList & prdSelectionProductIdList
			end

			# Fetching applicable products
			applicableProducts = Product.find(
				:all,
				:conditions => {
					{:name => 'productTypeCd'} => "PLAN",
					{:name => 'productId', :op => 'IN'} => agentProductIdList
				},
				:op => 'AND'
			)

			return prdSelectionProductHash, applicableProducts
		end
		##########################################################################################

		def self.populateProductPlanOptions(applicableProduct, prdSelectionProductHash, productPlanOptionHash)
			applicableProduct.OfflineFacetList.each do |offlineFacet|
				if offlineFacet.facetId.to_s == 'PLANOPTION'
					productPlanOptionHash[applicableProduct.id.to_s.to_sym] ||= []
					offlineFacet.OfflinePlanOptionList.each do |offlinePlanOption|
						collateralRenderLevel = CollateralRenderLevel.find(:first,:conditions => {:levelCd => offlinePlanOption.collateralLevelCd})
						html = ""
						if collateralRenderLevel != nil
							html = collateralRenderLevel.header1.to_s
							if collateralRenderLevel.contentPart1TypeCd.to_s == "HTML" && collateralRenderLevel.contentPart1.to_s != ""
								html = collateralRenderLevel.contentPart1.to_s
							end
						end
						if prdSelectionProductHash[applicableProduct.productId] == nil || prdSelectionProductHash[applicableProduct.productId].empty?
							offlinePlanOptionLookup = {
								:cd => offlinePlanOption.optionCd.to_s.strip,
								# :key => offlinePlanOption.optionCd.to_s.strip,
								:desc => MobiSys::BrowserHelper.getLabel(offlinePlanOption.description.to_s).strip,
								:sortOrder => offlinePlanOption.sortOrder,
								:html => html
								# :SA => offlinePlanOption.defaultSumAssured.to_s.strip
							}
							productPlanOptionHash[applicableProduct.id.to_s.to_sym].push(offlinePlanOptionLookup)
						elsif prdSelectionProductHash[applicableProduct.productId].include? offlinePlanOption.optionCd
							offlinePlanOptionLookup = {
								:cd => offlinePlanOption.optionCd.to_s.strip,
								# :key => offlinePlanOption.optionCd.to_s.strip,
								:desc => MobiSys::BrowserHelper.getLabel(offlinePlanOption.description.to_s).strip,
								:sortOrder => offlinePlanOption.sortOrder,
								:html => html
								# :SA => offlinePlanOption.defaultSumAssured.to_s.strip
							}
							productPlanOptionHash[applicableProduct.id.to_s.to_sym].push(offlinePlanOptionLookup)
						end
					end
					productPlanOptionHash[applicableProduct.id.to_s.to_sym].uniq!{|x| x[:cd]}
					# productPlanOptionHash[applicableProduct.id.to_s.to_sym].sort_by!{|a| a[:sortOrder].upcase}

					break
				end
			end
		end
		##########################################################################################

		def self.createDynamicDefinitionTableRecord(modelResultDO)
			newProductDefinitionTable =  ProductDefinitionTable.new
			pdtProperties = Rho::RhoConfig.sources["ProductDefinitionTable"]["schema"]["property"]
			modelResultDO.fieldValueList.each do |fieldValue|
				if fieldValue.fieldCd != nil && pdtProperties.has_key?(fieldValue.fieldCd.to_s)
					begin
						newProductDefinitionTable.send("#{fieldValue.fieldCd}=", fieldValue.fieldValue)
					rescue
					end
				end
			end
			return newProductDefinitionTable
		end

		def self.filterLookupDataOnBasisOfProduct(productDO, lookupKey)
	        listLookupDataFiltered = []
	        if("CURRENCYMASTER" == lookupKey || 
	                    "PLANOPTION" == lookupKey || 
	                "PREMIUMTYPE" == lookupKey||
	                "FREQUENCY" == lookupKey ||
	                "PAYMENTMETHOD" == lookupKey
	                )
	            if(productDO != nil)
	                facet = productDO.getFacet("PREMIUMDETAILS")
	                premiumDetails = facet.getPremiumDetails
	                lookupDataListStr = ""
	                case lookupKey
	                when "CURRENCYMASTER"
	                        lookupDataListStr = premiumDetails.currencyCd
	                when "PREMIUMTYPE"
	                        lookupDataListStr = premiumDetails.premiumTypeCd
	                when "FREQUENCY"
	                        lookupDataListStr = premiumDetails.paymentFrequencyCd
	                when "PAYMENTMETHOD"
	                        lookupDataListStr = premiumDetails.paymentMethodCd
	                end
	                if lookupDataListStr.to_s != ""
	                    listLookupDataFiltered = lookupDataListStr.split(",") 
	                else
	                    listLookupDataFiltered = nil
	                end

	            end
	        elsif("PLANOPTION" == lookupKey)
	            if(productDO != nil)
	                listLookupDataFiltered = nil
	            end
	        elsif("FUND" == lookupKey)
	            if(productDO != nil)
	                listLookupDataFiltered = nil
	            end
	        elsif("RIDERPRODUCT" == lookupKey)
	            if(productDO != nil)
	                listLookupDataFiltered = nil
	            end
	        end
	        return listLookupDataFiltered
	    end

	    def self.getProductData(product)
	        uiFacetHash = {}
	        facetTypeCds = ["PRDSELECTION", "PRDOTHERS"]
	        productFacets = product.OfflineFacetList.select{|facet| facet if(facetTypeCds.include?(facet.facetTypeCd) && facet.actionTypeCd != "rule")}
	        if productFacets
	            productFacets.each do |facet|
	                if facet.actionValue.to_s != ""
	                    uiFacetHash[facet.facetId] = facet.actionValue
	                else
	                    uiFacetHash[facet.facetId] = facet.ruleSeq
	                end
	            end
	        end
	        facetRADO = product.getFacet('RIDERASSOCIATION')
	        uiFacetHash["RIDERASSOCIATION"] = "YES" if facetRADO
	        #add other features, properties of product as well 
	        uiFacetHash["productId"] = product.productId.to_s
	        uiFacetHash["longName"] = product.longName.to_s
	        uiFacetHash["shortName"] = product.shortName.to_s
	        uiFacetHash["isWOPFl"] = nil
	        otherDetailsFacet = product.getFacetFast("OTHERDETAILS")
	        if otherDetailsFacet
	            otherDetailsDO = otherDetailsFacet.OfflineOtherDetailsList[0]
	            if (otherDetailsDO)
	                uiFacetHash["isWOPFl"] = otherDetailsDO.isWOPFl
	                if(otherDetailsDO.illustrationFormat.to_s != "")
	                    uiFacetHash["ILLUSTRATIONMODEL"] = "YES"
	                end
	            end
	        end
	        planFacetDO = product.getFacet("PLANOPTION")
	        if(planFacetDO)
	            planOptionHmList = []
	            planFacetDO.OfflinePlanOptionList.each do |planOptionDO|
	                planOptionHm = planOptionDO.objectToHash
	                planOptionHmList << planOptionHm
	            end
	            uiFacetHash["PLANOPTION"] = planOptionHmList
	        end

	        return uiFacetHash
	    end
	end   
end

begin 
    require 'Product/product_util_company'
rescue LoadError => e
    puts 'product_util_company not included'
end 