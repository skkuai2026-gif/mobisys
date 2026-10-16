require 'BaseRest/base_rest_controller'
require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'LabelValue/label_value'
require 'json'

class LabelValueController < BaseRestController
    include BrowserHelper
    include MobiSys::BrowserHelper

    def initialize
    end

    def index
        lang = Application.getValue('DEFAULTLOCALE').value
        lang = @params['lang'] if @params.has_key? ('lang')
        labelValues = LabelValue.find(
            :all,
            :conditions => {
                {
                    :name => "lang",
                    :op => "IN"
                } =>lang.downcase
            },
            :select => ['key', 'value']
        )
        labelvalueHash = {}
        labelValues.each do |label|
            labelvalueHash[label.key] = label.value
        end
        responseHash = {}
        responseHash['data'] = {}
        responseHash['data']['labels'] = labelvalueHash
        responseHash['success'] = true
        responseHash['message'] = "Successful"
        render :string => responseHash.to_json
    end

    def getAllLanguages
        languages = getLanguages
        sortByOrderLanguages,remainingLanguages = languages.partition{|lang| lang.sortOrder.to_s != ""}
        sortByOrderLanguages.sort_by!{|lang| lang.sortOrder.to_i} if sortByOrderLanguages.size > 0
        remainingLanguages.sort!{|a, b| a.desc.to_s <=> b.desc.to_s} if remainingLanguages.size > 0
       
        languages = sortByOrderLanguages.concat remainingLanguages
        languagesArr = []
        languageDef = nil
        languages.each do |lang|
            languageHash =  {}
            languageHash["cd"] = lang.cd
            languageHash["desc"] = lang.desc
            languagesArr << languageHash
            languageDef = lang.cd.to_s if lang.defaultFl.to_s == "YES"
        end

        responseHash = {}
        responseHash['data'] = {}
        responseHash['data']['language'] = languagesArr
        responseHash['data']["languageDef"] = languageDef
        responseHash['success'] = true
        responseHash['message'] = "Successful"

        render :string => responseHash.to_json
    end

    def changeLanguage
        languages = getLanguages
        parsedData = parseRequestBodyParams
        validLang = false
        responseHash = {}
        if parsedData["FormData"].has_key? ('language')
            languages.each do |lang|
                validLang = true if lang.cd == parsedData["FormData"]["language"]
            end
            if validLang
                selectedLanguage = parsedData["FormData"]["language"].downcase
                Application.updateValue('DEFAULTLOCALE',selectedLanguage)
                Localization::LabelCache.instance.resetLabels(selectedLanguage)
                responseHash['success'] = true
                responseHash['message'] = "Successful"
            else
                responseHash['success'] = false
                responseHash['message'] = "Invalid language code"
            end
            render :string => responseHash.to_json
        end
    end

    def getLanguages
        languages = Lookupvalue.find(
            :all,
            :conditions => {
                {:name => "key"} => "LANGUAGE",
                {
                    :name => "cd",
                    :op => "IN"
                } => $rhoconfig[:supported_locales].upcase.split(",")
            },
            :op => "AND",
            :select => ['cd','desc','defaultFl','sortOrder'],
            :order => ['sortOrder']
        )
        return languages
    end

    def getLookupData
        parsedData = parseRequestBodyParams
        responseHash = {}
        if parsedData['lookupKeyList'].to_s == ""
            responseHash = {'success' => false, 'message' => "Input Data missing"}
        else
            lookupKeyList = parsedData['lookupKeyList']
            listLookupDetails = {}
            lookupKeyList.each do |lookupKey|
                selectLookup = getOfflineLookupData(lookupKey, nil)
                listLookupDetails[lookupKey] = selectLookup.collect do |m|
                  hmLookupDataAttribs = {}              
                  m.vars.each do |key, value|
                    case key.to_s
                    when "cd", "desc"
                      hmLookupDataAttribs[key] = value
                    when "defaultFl" && value.to_s == "YES"
                      hmLookupDataAttribs["isDef"] = "YES"
                    end
                  end
                  hmLookupDataAttribs
                end
            end
            responseHash['data'] = listLookupDetails
            responseHash['success'] = true
            responseHash['message'] = "Successful"
        end
        render :string => responseHash.to_json
    end

end