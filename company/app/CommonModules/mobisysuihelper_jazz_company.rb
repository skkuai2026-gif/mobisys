#encoding: UTF-8
require 'helpers/browser_helper'
require 'time'
require 'CommonModules/metadata'

module MobiSys
	#UIhelper module contains utility methods used by the functional modules
	#Add any new method which is used by the UI/Controller for UI actions in this module
	module UIHelper
		ENTITYCONTEXT_SET_DO_MAP = {
			:InwardDetails 			=> :CollectionSet,
			:Inward 				=> :CollectionSet,
			:InwardPolicy 			=> :CollectionSet,
			:Party 					=> :PartySet,
			:PartyContact 			=> :PartySet,
			:PartyAddress 			=> :PartySet,
			:PartyIdentity 			=> :PartySet,
			:PartyEmail 			=> :PartySet,
			:PartyEmployment 		=> :PartySet,
			:PartyFinancialAccount 	=> :PartySet,
			:Service 				=> :ServiceSet,
			:ServiceDocument 		=> :ServiceDocumentSet,
			:Quotation 				=> :QuotationSet,
			:QuotationProduct 		=> :QuotationSet,
			:QuotationTopUp 		=> :QuotationSet,
			:QuotationParty 		=> :QuotationSet,
			:QuotationProductExtra 	=> :QuotationSet,
			:QuotationWithdrawal 	=> :QuotationSet,
			:Policy 				=> :PolicySet,
			:PolicyPayment 			=> :PolicySet,
			:PolicyProduct 			=> :PolicySet,
			:PolicyPartyRole 		=> :PolicySet,
			:PolicyTopUp 			=> :PolicySet
		}
		LOGCATEGORY = "UIHelper"

		def formSearchQuery(search, inputCriteria = nil)
		    queryString = ""
		    isFirstCriterion = true
		    sql = search.mainQuery.to_s.gsub('$userId' , "#{AgentReg.forUserId($userId, true).userId}")
		    if !sql.downcase.start_with?('select')
		        queryString << "select "
		        resultSize = search.SearchResultFieldList
		            .sort{|x,y| x.position.to_i<=>y.position.to_i}
		            .select{|f| f.resultFieldQuery.to_s != ""}
		        resultSize.each_with_index do |searchResultFieldDO, index|
		            queryString << searchResultFieldDO.resultFieldQuery.to_s
		            if index < resultSize.size - 1
		                queryString << " , "
		            end
		        end
		        queryString << " from "
		    end
		    queryString << sql #main Query
		    if inputCriteria && !inputCriteria.empty?
		        staticSearchCriteriaList = search.SearchCriterionList.sort_by(&:columnPosition)
		        staticSearchCriteriaList.each do |criterionDO|
		            if criterionDO.metaDataCd.to_s != "" && criterionDO.subQueryOffline.to_s != ""
		                value = inputCriteria[criterionDO.metaDataCd].to_s
		                next if value.empty?
		                metaDataClass = criterionDO.metaDataCd.to_s.split('.')[0].to_sym
		                if $uiMetaDataCache.has_key?(metaDataClass) && $uiMetaDataCache[metaDataClass].has_key?(criterionDO.metaDataCd.to_sym)
		                    uiMetaDataDOList = $uiMetaDataCache[metaDataClass][criterionDO.metaDataCd.to_sym]
		                    ui = MobiSys::UIMetaData.getUiMetadataPropDO("INPUTTYPECD", uiMetaDataDOList, [])
		                    inputType = (ui == nil ? "" : ui.propertyValue.to_s)
		                end
		                if inputType.to_s == "DATE"
		                    date = Date.parse(value)
		                    value = date.strftime('%d/%m/%Y')
		                end
		                if isFirstCriterion && !search.mainQuery.downcase.include?(" where ") && !search.mainQuery.downcase.include?("\nwhere ")
		                    queryString << " where "
		                else
		                    queryString << " and " unless criterionDO.subQueryOffline.downcase.include?(" or ") || criterionDO.subQueryOffline.downcase.include?(" and ")
		                end
		                isFirstCriterion = false
		                if criterionDO.subQueryOffline.downcase.include?("like")
		                    queryString << "#{criterionDO.subQueryOffline} '%#{value}%'"
		                else
		                    queryString << "#{criterionDO.subQueryOffline} '#{value}'"
		                end
		                if (criterionDO.postSubQuery.to_s != "")
		                    queryString << "  #{criterionDO.postSubQuery.to_s}"
		                end
		            end
		        end
		    end
		    
		    # append the post main query
		    if (search.postQuery.to_s != "")
		        queryString << "  #{search.postQuery.to_s}"
		    end
		    puts "SQL Search Query: #{search.searchName} :#{queryString.to_s}"
		    return queryString
		end


	end
end
