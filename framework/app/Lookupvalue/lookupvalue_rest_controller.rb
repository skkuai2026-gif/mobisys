require 'BaseRest/base_rest_controller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'

class LookupvalueController < BaseRestController
    include BrowserHelper
    include MobiSys::BrowserHelper

    def initialize
        # logInfo "~~~in lookupvalue rest initialize"
    end

    def loadLookupData
        parsedData = parseRequestBodyParams
        responseHash = {}
        lookupKey = nil
        if parsedData['offlineLookupKey'].to_s != ""
            lookupKey = parsedData['offlineLookupKey']
        else
            lookupKey = parsedData['onlineLookupKey']
        end
        if parsedData['offlineFilterCond'].to_s == "" && lookupKey == nil
            responseHash = {'success' => false, 'message' => "Input Data missing"}
        elsif parsedData["offlineFilterCond"].to_s != "" && parsedData["offlineFilterCond"]["mappingkey"].to_s != ""
            # p "inside mapping key************"
            data = {}
            data['values'] = []
            tableResult = FieldTargetValueMap.find(
                :all,
                :conditions => {
                    {:name=>'mappingKey'} => parsedData["offlineFilterCond"]["mappingkey"].to_s
                }
            )
            # puts "tableResult.....#{tableResult.size}"
            if tableResult.size > 0
                lookupsArray = Lookupvalue.find(:all,:conditions=>{'key'=>tableResult[0].targetLookupCd}) if tableResult[0]
                lookupHash = {}
                lookupsArray.each do |lookup|
                    if getLabelValue(lookup.desc).to_s != ""
                        lookupHash[lookup.cd] = getLabelValue(lookup.desc)
                    elsif getLabelValue(lookup.cd).to_s != ""
                        lookupHash[lookup.cd] = getLabelValue(lookup.cd)
                    elsif lookup.desc.to_s != ""
                        lookupHash[lookup.cd] = lookup.desc
                    else
                        lookupHash[lookup.cd] = lookup.cd
                    end
                end
                # puts "lookupHash==#{parsedData["offlineFilterCond"]["drivingValue"]}====#{lookupHash}"
                tableResult.each do |record|
                    if ((parsedData["offlineFilterCond"]["drivingValue"].to_s == "" && tableResult.size == 1) || (record.drivingValue == parsedData["offlineFilterCond"]["drivingValue"]))
                        value = {"cd" => record.targetValue, "desc" => lookupHash[record.targetValue]}
                        data['values'].push(value)
                    end
                end
                # puts "data=====#{data}"
            end
            responseHash = {'data' => data, 'success' => true, 'message' => "Successful"}
        else
            data_hash = parsedData['offlineFilterCond']
            selectLookup = getOfflineLookupData(lookupKey, data_hash)

            responseHash['data'] = {'values' => selectLookup.collect do |m|
              selected_vars = {}              
              m.vars.each do |key, value|
                case key.to_s
                when "cd", "desc"
                  selected_vars[key] = value
                when "defaultFl"
                  selected_vars["isDef"] = "1"
                when "additionalField1"
                  selected_vars["addtnlFld1"] = value
                when "additionalField2"
                  selected_vars["addtnlFld2"] = value
                end
              end
              selected_vars
            end}
            responseHash['success'] = true
            responseHash['message'] = "Successful"
        end

        render :string => responseHash.to_json
    end

    def loadMappingData
        parsedData = parseRequestBodyParams
        responseHash = {}
        if parsedData['mappingKey'].to_s == "" 
            responseHash = {'success' => false, 'message' => "Input Data missing"}
        else
            data = {}
            data['values'] = []
            tableResult = FieldTargetValueMap.find(
                :all,
                :conditions => {
                    {:name=>'mappingKey'} => parsedData['mappingKey'].to_s
                }
            )
            if tableResult.size > 0
                lookupsArray = Lookupvalue.find(:all,:conditions=>{'key'=>tableResult[0].targetLookupCd}) if tableResult[0]
                lookupHash = {}
                lookupsArray.each do |lookup|
                    if getLabelValue(lookup.desc).to_s != ""
                        lookupHash[lookup.cd] = getLabelValue(lookup.desc)
                    elsif getLabelValue(lookup.cd).to_s != ""
                        lookupHash[lookup.cd] = getLabelValue(lookup.cd)
                    elsif lookup.desc.to_s != ""
                        lookupHash[lookup.cd] = lookup.desc
                    else
                        lookupHash[lookup.cd] = lookup.cd
                    end
                end
                tableResult.each do |record|
                    if ((parsedData['drivingValue'].to_s == "" && tableResult.size == 1) || (record.drivingValue == parsedData['drivingValue']))
                        value = {"cd" => record.targetValue, "desc" => lookupHash[record.targetValue]}
                        data['values'].push(value)
                    end
                end
            end
            responseHash = {'data' => data, 'success' => true, 'message' => "Successful"}
        end
        render :string => responseHash.to_json
    end
end

begin 
    require 'Lookupvalue/lookupvalue_controller_company'
rescue LoadError => e
    puts 'lookupvalue_controller_company not included'
end