require 'BaseRest/base_rest_controller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'

class MenuController < BaseRestController

    include BrowserHelper
    include MobiSys::BrowserHelper

    def initialize
    end

    def index
        responseHash = {}
        currentAgentReg = AgentReg.getCurrentAgentReg
        applicable_menus_array = Rho::JSON.parse(currentAgentReg.applicableMenusJson)
        applicable_menus_array.each do |app_menu|
            app_menu['description'] = getLabelValue(app_menu['description'])
        end

        # Create a hash to store menu items by their menuSeq
        menu_hash = {}
        applicable_menus_array.each do |item|
          menu_hash[item["menuSeq"]] = item
        end

        # Insert child items into their respective parent's childList
        applicable_menus_array.each do |item|
          parent_seq = item["parentMenuSeq"]
          if parent_seq
            parent_item = menu_hash[parent_seq]
            if parent_item
              parent_item["childList"] ||= []  # Only add the childList key if it has children
              parent_item["childList"] << item
            end
          end
        end

        # Filter out items that have been added to a parent to get only top-level items
        revised_menus_array = applicable_menus_array.select { |item| item["parentMenuSeq"].nil? }
        
        responseHash['data'] = revised_menus_array
        responseHash['success'] = true
        responseHash['message'] = "Successful"

        render :string => responseHash.to_json
    end

    def agentInfo
        dataHash = {}
        @programVersion = Rho::RhoConfig.app_version
        if Application.getValue('mobiSysDeviceId') != nil
            @deviceId = Application.getValue('mobiSysDeviceId').value
        end
        @programReleaseDate = Rho::RhoConfig.last_release_date
        primaryDataLastSyncDate = Application.getValue('PRIMARYDATALASTSYNCDATE')
        if primaryDataLastSyncDate != nil
            @lastPrimaryDataSync = Time.load(primaryDataLastSyncDate.value).to_i
        else
            @lastPrimaryDataSync = nil
        end
        currentAgentReg = AgentReg.getCurrentAgentReg
        if currentAgentReg != nil

            forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory = MobiSys::Sync.processForceLoginSyncConditions("sync")

            useUpto = transactionSyncDt
            useUpto = masterDBUpgradeDt if masterSyncDefault == "ON" && masterDBUpgradeDt < transactionSyncDt
            @useUpto = useUpto.to_i
            excludedAttributes = ['parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'removed', 'activeDays', 'regPass', 'applicableProducts', 'deviceUserSeq', 'userDataDeleteDays', 'userLeadDataDeleteDays', 'offlineAccessFlag', 'collateralLevelCd', 'applicableMenus', 'enableFingerprintAuth', 'userAlias', 'lastLogin']
            modelSource = Rho::RhoConfig.sources[currentAgentReg.class.name.to_s]
            currentAgentRegAttrHash = modelSource["schema"]["property"]
            currentAgentRegAttrHash.each do |key, value|
                if !excludedAttributes.include?(key.to_s)
                    columnValue = eval("currentAgentReg.#{key}")
                    if (columnValue.to_s != "") && (columnValue.to_s != nil)
                        if value[0].to_sym == :time
                            dataHash[key.to_s] = columnValue.to_i
                        else
                            dataHash[key.to_s] = columnValue.to_s
                        end
                    end
                end
            end
        end

        if Application.getValue('DBVERSION') != nil
            @offlineMasterDBVersion = Application.getValue('DBVERSION').value
        end
        lastCollateralSyncDate = Application.getValue('LASTCOLLATERALSYNCDATE')
        if lastCollateralSyncDate
            @lastCollateralSyncDate = Time.load(lastCollateralSyncDate.value).to_i
        else
            @lastCollateralSyncDate = nil
        end
        @message = "Successful"
        responseHash = {}
        dataHash["programVersion"] = @programVersion if @programVersion.to_s != ""
        dataHash["deviceId"] = @deviceId if @deviceId.to_s != ""
        dataHash["programReleaseDate"] = @programReleaseDate if @programReleaseDate.to_s != ""
        dataHash["lastPrimaryDataSync"] = @lastPrimaryDataSync if @lastPrimaryDataSync.to_s != ""
        dataHash["useUpto"] = @useUpto if @useUpto.to_s != ""
        dataHash["offlineMasterDBVersion"] = @offlineMasterDBVersion if @offlineMasterDBVersion.to_s != ""
        dataHash["lastCollateralSyncDate"] = @lastCollateralSyncDate if @lastCollateralSyncDate.to_s != ""
        responseHash["data"] = dataHash
        responseHash["success"] = @success
        responseHash["message"] = @message
        render :string => responseHash.to_json
    end

    def securitySetting
        responseHash = {}
        begin
            parsedData = parseRequestBodyParams
            if parsedData.has_key?("enableFingerprintAuth")
                enableFingerprintAuth = parsedData["enableFingerprintAuth"].to_s
                currentAgentReg = AgentReg.forUserId($userId, true)
                currentAgentReg.enableFingerprintAuth = enableFingerprintAuth
                currentAgentReg.save
                responseHash["message"] = "Successful"
            end            
        rescue StandardError => e
            responseHash["message"] = "Error #{e}"
        end
        render :string => responseHash.to_json
    end

end

begin 
    require 'Menu/menu_controller_company'
rescue LoadError => e
    puts 'menu_controller_company not included'
end

