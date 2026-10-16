require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'

class LookupvalueController < Rho::RhoController
	include BrowserHelper
	include MobiSys::BrowserHelper

	def getLookupData
		data_hash = @params
		lookupKey = data_hash['lookupKey']
		@selectedValue = data_hash['selectedValue']
		
		offline_lookup_m = OfflineLookupM.find(:first,:conditions => {:lookupKey => lookupKey})
		
		data_hash.delete ('lookupKey')
		data_hash.delete ('selectedValue')
		@selectLookup = []
		lookups = []
		globalLookup = Lookupvalue.new
        globalLookup.cd = ""
        globalLookup.desc = getLabelValue("select")
		
		if offline_lookup_m
			partition = offline_lookup_m.offlineDBPartition.to_s != '' ? offline_lookup_m.offlineDBPartition.to_s : 'master'
			db = Rho::Database.new(Rho::Application.databaseFilePath(partition),partition)
			db.start_transaction
			if offline_lookup_m.lookupDataSortOrderName.to_s != ""
				sql = "SELECT #{offline_lookup_m.lookupDataCodeName}, #{offline_lookup_m.lookupDataDescName}, #{offline_lookup_m.lookupDataSortOrderName} as sortingKey FROM #{offline_lookup_m.lookupEntityName} "
			else
				sql = "SELECT #{offline_lookup_m.lookupDataCodeName}, #{offline_lookup_m.lookupDataDescName} FROM #{offline_lookup_m.lookupEntityName} "
			end
			filterCriteria = offline_lookup_m.lookupFilterCriteria.to_s
			data_hash.each do |key,value|
				filterCriteria.gsub!("$#{key}", value)
			end
			sql << "WHERE #{filterCriteria} " if filterCriteria.to_s != ""
			sql << "ORDER BY #{offline_lookup_m.lookupDataSortOrderName}" if offline_lookup_m.lookupDataSortOrderName.to_s != ""
			results = db.execute_sql(sql)
			db.commit
			results.each do |result|
				tempLookup = Lookupvalue.new
		        tempLookup.cd = result.values[0].to_s
		        tempLookup.desc = getLabelValue(result.values[1].to_s)
		        tempLookup.sortOrder = result.values[2].to_s if offline_lookup_m.lookupDataSortOrderName.to_s != "" && result.values[2]
		        lookups.push tempLookup
			end
		else
			lookups = Lookupvalue.getValue(lookupKey)
		end
		if lookups && lookups.size > 0
	        sortByOrderLookups,remainingLookups = lookups.partition{|lookup| lookup.sortOrder.to_s != ""}
	        sortByOrderLookups.sort_by!{|lookUp| lookUp.sortOrder.to_i} if sortByOrderLookups.size > 0
	        remainingLookups.sort!{|a, b| a.desc.to_s <=> b.desc.to_s} if remainingLookups.size > 0
	        @selectLookup = sortByOrderLookups.concat remainingLookups
      	end
		@selectLookup.unshift(globalLookup)
        render :action => :filterLookupData, :layout => false
	end

	# method to run policy model and return lookup values
	def getPolicyModelLookupData
		className = @params['className']
		facetId = @params['facetId']
		productSeq = @params['productSeq']
		results = {}
		if facetId.to_s != "" && productSeq.to_s != "" && @params.has_key?(className)
			entity = MobiSys::BrowserHelper.convertToObjectWithMerge(className, @params[className])
			if entity.class.name.to_s == "Quotation"
				policy = MobiSys::PolicyBO.convertToPolicy(entity, true)
			else
				policy = entity
			end
			product = MobiSys::ProductUtil.getProduct(productSeq)
            modelCd = product.getFacetValue(facetId) if product 
			if modelCd.to_s == ""
				$companyFacetCache ||= CompanyFacet.loadObject(:all)
				$companyFacetCache.each do |obj|
					if obj.facetCd == facetId
						modelCd = obj.actionValue
						break
					end
				end
			end
           	polModelDO = PolicyUtil::PolicyModel.new
			policyParty = policy.getParty('PRIMARY')
			policyParty.policyYear = entity.policyYear
			# policyProduct = policy.getBaseProduct if policy
			policyProduct = policy.getBaseProduct if policy
			modelResultDO = polModelDO.execute(policy, policyProduct, policyParty, modelCd) if policyProduct
			if modelResultDO != nil && modelResultDO.hmFieldValues != nil
				results = modelResultDO.hmFieldValues
			end
		end
		render :string => results.to_json
	end
end
