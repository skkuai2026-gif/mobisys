require 'BaseRest/base_rest_controller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/schema_module'
require 'CommonModules/syncmodule'
require 'Search/search_service'


class SearchController < BaseRestController
	include BrowserHelper
	include MobiSys::BrowserHelper

	def initialize
		# logInfo("~~~in AgentRegController initialize")
	end

	def create
		tempHash = {}
        params = @params
		@lookupHash = {}
		
       	tempHash, flag, lookupsToAdd = MobiSys::SearchService.search(params)
		if flag
			lookupsToAdd.each do |lkp|
				addToLookupHash(lkp)
			end
			returnHash = {"data" => tempHash}
			returnHash["lookups"] = @lookupHash
			returnHash['success'] = true
			returnHash['message'] = "Successful"
		else
			returnHash = {"success" => flag, "message" => tempHash}
		end
        render :string => returnHash.to_json
	end
    
end