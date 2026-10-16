module MobiSys
	class ProductUtil

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

		def self.getDBDate(screenDate)
			if screenDate != nil && screenDate != "" && screenDate.is_a?(String)
				dateParts = screenDate.split(/[\-\/ ]/)
				if dateParts[2].length < 3
					screenDate = Time.new(dateParts[0].to_i,dateParts[1].to_i,dateParts[2].to_i)
				else
					screenDate = Time.new(dateParts[2].to_i,dateParts[1].to_s,dateParts[0].to_i)
				end
			elsif screenDate.to_s != "" && screenDate.is_a?(Integer)
				screenDate = Time.at(screenDate)
			end
			return screenDate
		end

	end   
end