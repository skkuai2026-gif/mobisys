require 'rho/rhoapplication'
require 'rho/rhoutils'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/mobisyscontacts'
require 'CommonModules/mobisyscalendar'
require 'CommonModules/ContextGenerator_rexml.rb'
require 'CommonModules/settings.rb'
require 'fileutils'
require 'ostruct'

begin
  require 'bigdecimal'
  require 'bigdecimal/util'
rescue LoadError => e
  puts 'bigdecimal not included'
end

class Time
  def self.dump(timeObj)
    timeObj.send(:_dump)
  end
  def self.load(timeObj)
    self.send(:_load, timeObj)
  end
end

class Object
  def get_binding
    return binding()
  end
end

class Array
  # This method should only be used of array of objects for database models
  def hashForApi(childrenRequired=true,allowdAttributes=[])
    tempArray = []
    self.each do |element|
      tempArray.push(element.hashForApi(childrenRequired,allowdAttributes))
    end
    return tempArray
  end
end

class OpenStruct
  def get(key)
    value = self[key.to_sym]
    if value.is_a?(Array) && value.size == 1
      value[0]
    else
      value
    end
  end
end

class AppApplication < Rho::RhoApplication
  include BrowserHelper
  include MobiSys::BrowserHelper

  def initialize
    # Tab items are loaded left->right, @tabs[0] is leftmost tab in the tab-bar
    # Super must be called *after* settings @tabs!
    @tabs = nil
    #To remove default toolbar uncomment next line:
    @@toolbar = nil
    
    # $dbUpdated = false
    super
    if defined?(Rho::DeviceSecurity) && !Rho::DeviceSecurity.isDeviceSecured
      Alert.show_popup( { 
        :message => "Insecure Device, cannot run application", 
        :title => "Insecure Device",
        :buttons => [{:id=>"ok",:title=> getLabelValue("OK")}]
      })
      Rhom::Rhom.database_full_reset(true, true)
      Application.create(MobiSys::DEVICEDISABLED,'YES')
      Application.create('seeded','seeded');
      Rho::Application.quit()
    end

      ############# fresh installation process popup ######################
      fresh_install_required = Application.getValue('FRESH_INSTALL_REQUIRED')
      if fresh_install_required && fresh_install_required.value.to_s == 'YES'
        puts "inside 72222*****"
      end
      app_version = Application.getValue('app_version')
      if app_version
          Application.updateValue("app_version", Rho::RhoConfig.app_version)
      else
          Application.create("app_version", Rho::RhoConfig.app_version)
      end
      ############# fresh installation process popup end ######################
    #@default_menu = { }
    # Uncomment to set sync notification callback to /app/Settings/sync_notify.
    # SyncEngine::set_objectnotify_url("/app/Settings/sync_notify")
    # SyncEngine.set_notification(-1, "/app/Settings/sync_notify", '')
    app_version = Application.getValue('app_version')
    if app_version
        Application.updateValue("app_version", Rho::RhoConfig.app_version)
    else
        Application.create("app_version", Rho::RhoConfig.app_version)
    end
    Mobisys::Settings.setRhoconfigParams
    if System::get_property('platform') == 'ANDROID' && !Rho::System.isRhoSimulator
      $ssl_verify_peer = true
    else
      $ssl_verify_peer = false
    end

    $childClasses = Hash.new
    seeded = Application.getValue('seeded')
    $syncLogs = Array.new
    $collateralDownloadHash = Hash.new
    $masterSyncCompleted = true
    $dbUpdateMandatory = false
    $errors = Hash.new
    unless seeded
      temp = Comparator.new
      temp.save

      tempLabel = LabelValue.new
      tempLabel.key  = "KEY"
      tempLabel.value = "value"
      tempLabel.lang  = "en"
      tempLabel.save
      tempLabel.destroy
  
      tempLookup = Lookupvalue.new
      tempLookup.key = "LANG"
      tempLookup.cd = "en"
      tempLookup.desc = "English"
      tempLookup.save
      tempLookup.destroy
  
      tempQuotation = Quotation.new
      tempQuotation.save
      tempQuotation.destroy
      
      tempQuotationProduct = QuotationProduct.new
      tempQuotationProduct.save
      tempQuotationProduct.destroy
      
      tempProductFamily = ProductFamily.new
      tempProductFamily.save
      tempProductFamily.destroy
      
      tempProduct = Product.new
      tempProduct.save
      tempProduct.destroy
  
      tempProductDefinitionTable = ProductDefinitionTable.new
      tempProductDefinitionTable.save
      tempProductDefinitionTable.destroy
      
      tempSyncEntity = SyncEntity.new
      tempSyncEntity.save
      tempSyncEntity.destroy
      
      tempSyncCategory = SyncCategory.new
      tempSyncCategory.save
      tempSyncCategory.destroy
  
      tempProductFiltering = ProductFiltering.new
      tempProductFiltering.save
      tempProductFiltering.destroy

      tempIllustrationFacet = IllustrationFacet.new
      tempIllustrationFacet.save
      tempIllustrationFacet.destroy

      tempFund = Fund.new
      tempFund.save
      tempFund.destroy

      tempModelFund = ModelFund.new
      tempModelFund.save
      tempModelFund.destroy

      tempQuestionSet = QuestionSet.new
      tempQuestionSet.save
      tempQuestionSet.destroy

      tempQuestionSetMap = QuestionSetMap.new
      tempQuestionSetMap.save
      tempQuestionSetMap.destroy

      tempQuestionSetQuestion = QuestionSetQuestion.new
      tempQuestionSetQuestion.save
      tempQuestionSetQuestion.destroy

      tempDocumentCategory = DocumentCategory.new
      tempDocumentCategory.save
      tempDocumentCategory.destroy

      tempDocumentCategoryMap = DocumentCategoryMap.new
      tempDocumentCategoryMap.save
      tempDocumentCategoryMap.destroy
      
      tempDocument = Document.new
      tempDocument.save
      tempDocument.destroy

      tempSearchResultSettings = SearchResultSettings.new
      tempSearchResultSettings.save
      tempSearchResultSettings.destroy
      
      tempReleaseManagements = ReleaseManagement.new
      tempReleaseManagements.save
      tempReleaseManagements.destroy

      tempReleaseDTScripts = ReleaseDTScript.new
      tempReleaseDTScripts.save
      tempReleaseDTScripts.destroy
      
      tempDO = IndustryNatureofdutyMap.new
      tempDO.save
      tempDO.destroy
      
      tempDO = OfflineTableTypeCondition.new
      tempDO.save
      tempDO.destroy
      if $rhoconfig.has_key?(:seed_from_db) and $rhoconfig[:seed_from_db]=='YES'
        Rho::RHO.load_all_sources()
        dbPath = Rho::RhoApplication.get_model_path('app', 'db')
        seedFile = dbPath + 'fixtures' + File::SEPARATOR + 'syncdbmaster.sqlite.zip'
        result = Rhom::Rhom.database_import('master',seedFile)
        puts "DB import was successful with result #{result}" if result
        puts "DB import returned no result" unless result
        # $dbUpdated = true
      else
        Rho::RHO.load_all_sources()
        #Rho::RhoUtils.load_offline_data(['LabelValue','Level0', 'Level1', 'Level2', 'Level3', 'Level4', 'Comparator', 'Lookupvalue','ProductFamily','Product','ProductDefinitionTable','SyncEntity','ProductFiltering','SyncCategory','Collateral','Fund','ModelFund','QuestionSet','QuestionSetMap','QuestionSetQuestion','DocumentCategory','Document','DocumentCategoryMap','IllustrationFacet','SearchResultSettings','PincodeCityStateCountryMapping'],'db')
        Rho::RhoUtils.load_offline_data(['LabelValue','Lookupvalue','SyncEntity','SyncCategory','Comparator','SearchResultSettings'],'db')
        #####################################
        # For creating db zip file
        #####################################
        if $rhoconfig.has_key?(:create_db_seed) and $rhoconfig[:create_db_seed]=='YES'
          puts ">>>Before export:"
          path_to_zip_file = Rhom::Rhom.database_export('master')
        #####################################
        # For providing access to Ipad/Iphone Address Book and Calendar -START
        #####################################
        unless System::get_property('is_emulator')
          if System::get_property('platform') == 'APPLE'
            #Address Book Access           
            contact = Hash.new()
            contact["first_name"] = "Mobisys"
            contact["last_name"] = "SalesTool"
            begin
              contactEntry = MobiSys::Contacts.create(contact)
            rescue MobiSys::ContactsAccessError => error 
              puts "Contacts Access Not Available"
            end
          
            #Calendar Access
            event = Hash.new
            event["title"] = "Mobisys Sales Tool Updated"
            event["start_date"] = Time.now()
            event["end_date"] = Time.now()
            begin
              calendar = MobiSys::Calendar.create(event)
            rescue MobiSys::CalendarAccessError => error 
              puts "Calendar Access Not Available"
            end
          end
        end
        #####################################
        # For providing access to Ipad/Iphone Address Book and Calendar -END
        #####################################
          puts '>>>Path to zip file: ' + path_to_zip_file
        end  
      end       
      #Rho::RhoUtils.load_offline_data(['LabelValue','Lookupvalue','SyncEntity','SyncCategory','Collateral'],'db')
      Application.create('DBVERSION',$rhoconfig[:initial_db_version])
      Application.create('OUTPUTIMAGESVERSION',$rhoconfig[:initial_outputimages_version])
      Application.create('COLLATERALVERSION',$rhoconfig[:initial_collateral_version])
      Application.create('seeded','seeded')

        #####################################
        # For app version
        #####################################
        #for app_version for create
        app_version = Application.getValue('app_version')
        if app_version == nil
          app_version = Application.new
          app_version.key = 'app_version'
          app_version.value = $rhoconfig[:fresh_app_version]
          app_version.save
        end

        app_version = Application.getValue('app_version')
        if app_version
          Application.updateValue("app_version", Rho::RhoConfig.app_version)
        else
          Application.create("app_version", Rho::RhoConfig.app_version)
        end
        #####################################

      #for headersection
      dimoge = Application.getValue('Dimoge')
      if dimoge == nil
        dimoge = Application.new
        dimoge.key = 'Dimoge'
        dimoge.value = $rhoconfig[:Dimoge]
        dimoge.save
      end

        #####################################
        # For app version
        #####################################
        app_version = Application.getValue('app_version')
        if app_version
          Application.updateValue("app_version", Rho::RhoConfig.app_version)
        else
          Application.create("app_version", Rho::RhoConfig.app_version)
        end
        #####################################

      file_dir_name = Rho::RhoApplication.get_blob_folder
      FileUtils::mkdir_p file_dir_name unless Dir.exists?(file_dir_name)
    else
      # Rho::RHO.load_all_sources()
    end
    

    #####################################
    # For default locale
    #####################################
    defaultLocaleAppObject = Application.getValue('DEFAULTLOCALE')
    unless defaultLocaleAppObject
      #Default locale has not been set. Set it.
      applicableLocales = $rhoconfig[:supported_locales]
      defaultLocale = applicableLocales.split(",")[0]
      Application.create('DEFAULTLOCALE',defaultLocale)
    end
    #####################################
    # For online server
    #####################################
    online_server_url = Application.getValue('online_server_url')
    if online_server_url == nil
      online_server_url = Application.new
      online_server_url.key='online_server_url'
      online_server_url.value = $rhoconfig[:online_server_url]
      online_server_url.save 
    end
    
    #####################################
    # For syn config
    #####################################
    synConfig = Application.getValue('synConfig')
    if synConfig == nil
      synConfig = Application.new
      synConfig.key='synConfig'
      synConfig.value = $rhoconfig[:synConfig]
      synConfig.save 
    end

    #################added by shiv
    #####################################
    # For menu config
    #####################################
    menuConfig = Application.getValue('menuConfig')
    if menuConfig == nil
      menuConfig = Application.new
      menuConfig.key='menuConfig'
      menuConfig.value = $rhoconfig[:menuConfig]
      menuConfig.save 
    end


    #####################################
    # For Uses Rules
    #####################################
    uses_rules = Application.getValue('uses_rules')
    if uses_rules == nil
      uses_rules = Application.new
      uses_rules.key='uses_rules'
      uses_rules.value = $rhoconfig[:uses_rules]
      uses_rules.save 
    end

    agentLastLoginTimestamp = Application.getValue('agentLastLoginTimestamp')
    if agentLastLoginTimestamp == nil
      agentLastLoginTimestamp = Application.new
      agentLastLoginTimestamp.key='agentLastLoginTimestamp'
      agentLastLoginTimestamp.value = $rhoconfig[:agentLastLoginTimestamp]
      agentLastLoginTimestamp.save 
    end

    # Code to migrate user Ids from unencrypted to encrypted ones

    if $rhoconfig[:trigger_migration] && !File.file?(Rho::Application.userFolder.to_s+'migration_flag.txt')     # checking existence of flag file and going inside if NOT exists
      begin
        db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'app');
        sql = "SELECT name FROM sqlite_master WHERE type='table' AND sql LIKE '%userId%' AND name NOT IN ('Application','AgentReg')"
        tables_list_hash = db.execute_sql(sql)

        agentRegHash = {}
        AgentReg.find(:all).each do |eachAgentReg|
          agentRegHash[eachAgentReg.userId.to_sym] = MobiSys::Encryption.encryptContent(eachAgentReg.userId)
          eachAgentReg.userId = agentRegHash[eachAgentReg.userId.to_sym]
          eachAgentReg.save
        end

        sql = ""
        tables_list_hash.each do |each_table_name_hash|
          user_ids_hash_from_table = db.execute_sql("SELECT DISTINCT userId FROM "+each_table_name_hash["name"]+";")
          user_ids_hash_from_table.each do |each_user_id_hash|
            sql << "UPDATE "+each_table_name_hash["name"]+" SET userId='"+agentRegHash[each_user_id_hash["userId"].to_sym]+"' WHERE userId='"+each_user_id_hash["userId"]+"';" if agentRegHash[each_user_id_hash["userId"].to_sym]
          end
        end
        db.execute_batch_sql(sql)
      rescue
        puts "Failure in migration code in application.rb"
      end
      File.new(Rho::Application.userFolder.to_s+'migration_flag.txt','w').close   # creating the flag file
    end
    generateEntityTypeJS

    # Net request data JSON and ZIP files deletion
    devSeqObj = Application.getValue(MobiSys::DEVICESEQ)
    if devSeqObj && devSeqObj.value.to_s != ""
      Dir.glob("#{Rho::Application.userFolder}/*_#{devSeqObj.value}*").each do |file|
        File.delete(file) if File.exists?(file)
      end
    end
    Rho::RhoFile.deleteRecursive(Rho::RhoFile.join(Rho::Application.userFolder, "documentPreview"))
    Mobisys::Settings.updateRhoconfigParams
    getQuestionSetHash if result
    getQuestionSetQuestionHash if result && $inputTypeOfQuestion.empty?

    # Below code is written for adding collateral data once in localDB
    collateralData = Application.getValue('collateralData')
    if $rhoconfig[:SunPHComp].to_s == 'SLOCPI'
      unless collateralData
        begin
          db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
          db.start_transaction

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('ML1P0AImage', NULL, NULL, 'Image for Sun MaxiLink One', 'ML1P0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FLXP0AImage', NULL, NULL, 'Image for Sun MaxiLink Prime', 'FLXP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WEVP0AImage', NULL, NULL, 'Image for Sun Smarter Life Elite Peso 5', 'WEVP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('SLAP0AImage', NULL, NULL, 'Image for Sun LifeAssure', 'SLAP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('ML1P0EImage', NULL, NULL, 'Image for Sun MaxiLink One  Age 71 to 80', 'ML1P0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FLCP0AImage', NULL, NULL, 'Image for Sun MaxiLink 100 ', 'FLCP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WEXP0AImage', NULL, NULL, 'Image for Sun Smarter Life Elite Peso 10', 'WEXP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WERP0AImage', NULL, NULL, 'Image for Sun Smarter Life Elite Peso Regular Pay ', 'WERP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('SSUP0AImage', NULL, NULL, 'Image for Sun StartUp', 'SSUP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FLCP0A_BRO', NULL, 'Brochure', 'FLCP0A_BRO', 'Sun MaxiLink 100 eBrochure.pdf', 'PDF', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FL1P0A_COVER', NULL, NULL, 'SunFlexiLink1_COVER', 'sun-flexilink-1.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FLCP0A_Cover', NULL, NULL, 'SunMaxiLink100_Cover', 'sun-maxilink-100-1200x600px.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FLVP0A_Cover', NULL, NULL, 'SunMaxiLinkBright_Cover', 'sun-maxilink-bright.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FLXP0A_Cover', NULL, NULL, 'SunMaxiLinkPrime_Cover', 'sun-maxilink-prime.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('ML1P0A_Cover', NULL, NULL, 'SunMaxiLinkOne_Cover', 'sun-maxilink-one.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('SSUP0A_Cover', NULL, NULL, 'SunStartUp_Cover', 'sun-startup.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WE_P0A_Cover', NULL, NULL, 'SunSmarterLifeElite_Cover', 'sun-smarter-life-elite.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('SLAP0A_Cover', NULL, NULL, 'SunLifeAssured_Cover', 'sun-life-assure.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('TRAD_Cover', NULL, NULL, 'Traditional_Cover', 'trad.jpeg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('VUL_Cover', NULL, NULL, 'Vul_Cover', 'vul.jpeg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('SSL_Brochure', NULL, NULL, 'SunSamarterLife_Brochure', 'Sun_Smarter_Life_Elite.pdf', 'PDF', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('SSLEP_Video', NULL, NULL, 'SunSmarterLifeElitePeso_Video', 'SL-Lets-Do-This_Sarah_Matteo_6s_16x9.mp4', 'MP4', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('ADBImage', NULL, NULL, 'Image for Accidental Death Benefit', 'accidentaldeath.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('CIBImage', NULL, NULL, 'Image for Critical Illness Benefit', 'criticalillness.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('HIBImage', NULL, NULL, 'Image for Hospital Income Benefit', 'hospitalincome.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WPDImage', NULL, NULL, 'Image for Waiver of Premium on Death of Initial Owner', 'waiverofpremium.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('TDBImage', NULL, NULL, 'Image for Total Disability Benefit', 'totaldisability.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WPDDImage', NULL, NULL, 'Image for Waiver of Premium upon Death or Disability of Initial Owner', 'wpddandwpd.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('LBRImage', NULL, NULL, 'Image for Living Benefit Rider', 'Livingbenefit.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('5YRCTImage', NULL, NULL, 'Image for Safer Life Rider - 5YRCT', '5YRCT.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.commit
        rescue Exception => e
          db.rollback
          puts 'Error while manipulating table Collateral #{e}'
        end

        begin
          db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
          db.start_transaction

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('NEWWEXP0AColl', 'NEW Collateral for SUN Smarter Life Elite Peso 10', NULL, NULL, NULL, NULL, NULL, 'WEXP0AImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '2', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('HIBColl', 'Collateral for Hospital Income Benefit', NULL, NULL, NULL, NULL, NULL, 'HIBImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WPDColl', 'Collateral for Waiver of Premium on Death of Initial Owner', NULL, NULL, NULL, NULL, NULL, 'WPDImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('TDBColl', 'Collateral for Total Disability Benefit', NULL, NULL, NULL, NULL, NULL, 'TDBImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WPDDColl', 'Collateral for Waiver of Premium upon Death or Disability of Initial Owner', NULL, NULL, NULL, NULL, NULL, 'WPDDImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('LBRColl', 'Collateral for Living Benefit Rider', NULL, NULL, NULL, NULL, NULL, 'LBRImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('5YRCTColl', 'Collateral for Safer Life Rider - 5YRCT', NULL, NULL, NULL, NULL, NULL, 'LBRImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('ML1P0AColl', 'Collateral for SUN Maxilink One', NULL, NULL, NULL, NULL, NULL, 'ML1P0A_Cover', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '5', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('ML1P0EColl', 'Collateral for SUN MaxiLink One Age 71 to 80', NULL, NULL, NULL, NULL, NULL, 'ML1P0A_Cover', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '6', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('SSUP0AColl', 'Collateral for SUN StartUp', NULL, NULL, NULL, NULL, NULL, 'SSUP0A_Cover', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '7', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('SLAP0AColl', 'Collateral for SUN LifeAssure', NULL, NULL, NULL, NULL, NULL, 'SLAP0A_Cover', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '3', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('TRAD_ProdFam', 'Collateral_For_Trad_ProdFam', NULL, NULL, NULL, NULL, NULL, 'TRAD_Cover', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('VUL_ProdFam', 'Collateral_For_Vul_ProdFam', NULL, NULL, NULL, NULL, NULL, 'VUL_Cover', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FL1P0AColl', 'Collateral for sun flexi link 1', NULL, NULL, NULL, NULL, NULL, 'FL1P0A_COVER', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '3', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FLCP0AColl', 'Collateral for SUN Maxilink 100', NULL, NULL, NULL, NULL, NULL, 'FLCP0A_Cover', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '11', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FLVP0AColl', 'Collateral for Sun Maxi Link Bright', NULL, NULL, NULL, NULL, NULL, 'FLVP0A_Cover', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '3', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FLXP0AColl', 'Collateral for SUN Maxilink Prime', NULL, NULL, NULL, NULL, NULL, 'FLXP0A_Cover', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '4', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WEXP0AColl', 'Collateral for SUN Smarter Life Elite Peso 10', NULL, NULL, NULL, NULL, NULL, 'WE_P0A_Cover', NULL, 'MEDIA', 'SSLEP_Video', NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '11', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WEVP0AColl', 'Collateral for SUN Smarter Life Elite Peso 5', NULL, NULL, NULL, NULL, NULL, 'WE_P0A_Cover', NULL, 'MEDIA', 'SSLEP_Video', NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '6', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WERP0AColl', 'Collateral for SUN Smarter Life Elite Peso Regular Pay', NULL, NULL, NULL, NULL, NULL, 'WE_P0A_Cover', NULL, 'MEDIA', 'SSLEP_Video', NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '5', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('ADBColl', 'Collateral for Accidental Death Benefit', NULL, NULL, NULL, NULL, NULL, 'ADBImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('CIBColl', 'Collateral for Critical Illness Benefit', NULL, NULL, NULL, NULL, NULL, 'CIBImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.commit
        rescue Exception => e
          db.rollback
          puts 'Error while manipulating table Collateral #{e}'
        end

        if collateralData == nil
          collateralData = Application.new
          collateralData.key='collateralData'
          collateralData.value = 'YES'
          collateralData.save 
        end
      end
    elsif $rhoconfig[:SunPHComp].to_s == 'SLGFI'
      unless collateralData
        begin
          db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
          db.start_transaction

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('RFXP0AImage', NULL, NULL, 'Image for Sun Grepa Power Builder 10', 'RFXP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('RFCP0AImage', NULL, NULL, 'Image for Sun Grepa Power Builder 100', 'RFCP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FCVP0AImage', NULL, NULL, 'Image for Sun Grepa ProSecure 5', 'FCVP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FCXP0AImage', NULL, NULL, 'Image for Sun Grepa ProSecure 10', '
          FCXP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('GPSP0AImage', NULL, NULL, 'Image for Sun Grepa ProSecure Regular Pay', 'GPSP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('IBVP0AImage', NULL, NULL, 'Image for Sun Grepa ProSecure Plus 5', 'IBVP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('IBXP0AImage', NULL, NULL, 'Image for Sun Grepa ProSecure Plus 10', 'IBXP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('GPPP0AImage', NULL, NULL, 'Image for Sun Grepa ProSecure Plus Regular Pay', 'GPPP0A.png', 'PNG', 'EXTERNAL', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('VUL_Cover', NULL, NULL, 'Vul_Cover', 'VUL.png', 'PNG', 'INLINE', '2', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('VUL_Cover', NULL, NULL, 'Vul_Cover', 'VUL.png', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '2', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('TRAD_Cover', NULL, NULL, 'Trad_Cover', 'VUL.png', 'PNG', 'INLINE', '2', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('TRAD_Cover', NULL, NULL, 'Trad_Cover', 'TRAD.png', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '2', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PSP_Cover', NULL, NULL, 'ProSecurePlus_Cover', 'ProSecure Plus.png', 'PNG', 'INLINE', '2', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PSP_Cover', NULL, NULL, 'ProSecurePlus_Cover', 'ProSecure Plus.png', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '2', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PS_Cover', NULL, NULL, 'ProSecure_Cover', 'ProSecure.png', 'PNG', 'INLINE', '2', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PS_Cover', NULL, NULL, 'ProSecure_Cover', 'ProSecure.png', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '2', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PB5AND10_Cover_New', NULL, NULL, 'PowerBuilder5and10_CoverNew', 'Power-Builder-5-and-10.png', 'PNG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PB100_Cover', NULL, NULL, 'PowerBuilder100_Cover', 'Power Builder 100.png', 'PNG', 'INLINE', '3', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PB100_Cover', NULL, NULL, 'PowerBuilder100_Cover', NULL, 'JPG', 'INLINE', '2', 'PENDING', NULL, NULL, NULL, NULL, NULL, '2', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PB100_Cover', NULL, NULL, 'PowerBuilder100_Cover', 'Power Builder 100.png', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '3', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PB100_Cover_New', NULL, NULL, 'PowerBuilder100_CoverNew', 'Power-Builder-100.png', 'PNG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PSP_Cover_New', NULL, NULL, 'ProSecurePlus_CoveNew', 'ProSecure-Plus.png', 'PNG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PB1_Cover', NULL, NULL, 'PowerBuilder1_Cover', 'Power_Builder_1.png', 'PNG', 'INLINE', '3', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PB1_Cover', NULL, NULL, 'PowerBuilder1_Cover', 'Power_Builder_1.png', 'PNG', 'INLINE', '3', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PB1_Cover', NULL, NULL, 'PowerBuilder1_Cover', 'Power Builder 1.png', 'PNG', 'INLINE', '2', 'PENDING', NULL, NULL, NULL, NULL, NULL, '2', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PB1_Cover', NULL, NULL, 'PowerBuilder1_Cover', 'Power Builder 1.png', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '3', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PB5AND10_Cover', NULL, NULL, 'PowerBuilder5and10_Cover', 'PowerBuilder5and10.png', 'PNG', 'INLINE', '3', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PB5AND10_Cover', NULL, NULL, 'PowerBuilder5and10_Cover', 'Power Builder 5 and 10.png', 'PNG', 'INLINE', '2', 'PENDING', NULL, NULL, NULL, NULL, NULL, '2', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PB5AND10_Cover', NULL, NULL, 'PowerBuilder5and10_Cover', 'Power Builder 5 and 10.png', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '3', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('PB1_Cover_New', NULL, NULL, 'PowerBuilder1_CoverNew', 'Power-Builder-1.png', 'PNG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('ADBImage', NULL, NULL, 'Image for Accidental Death Benefit', 'AccidentalDeathBenefitRider.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('CIBImage', NULL, NULL, 'Image for Critical Illness Benefit', 'CriticalIllnessBenefitRider.jpeg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('Grepa5YRCTImage', NULL, NULL, 'Image for ProTerm Rider - 5YRCT', 'ProTermRider5YRCT.jpeg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('HIBImage', NULL, NULL, 'Image for Hospital Income Benefit', 'HospitalIncomeBenefitRider.jpeg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('LBRImage', NULL, NULL, 'Image for Living Benefit Rider', 'LivingBenefitRider.jpeg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('TDBImage', NULL, NULL, 'Image for Total Disability Benefit', 'TotalDisabilityBenefitRider.jpeg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WPDDImage', NULL, NULL, 'Image for Waiver of Premium upon Death or Disability of Initial Owner', 'WaiverofPremiumuponDeathorDisabilityRider.jpeg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WPDImage', NULL, NULL, 'Image for Waiver of Premium on Death of Initial Owner', 'WaiverofPremiumonDeathRider.jpeg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('RA1P0BImage', NULL, NULL, 'Image for Sun Grepa First Aid Plus - 50% ROP', 'SLGFirstAidPLUS.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('GW2P0AImage', NULL, NULL, 'Image for Sun Grepa Wealth Prime 7', 'SLGWealthPrime.jpg', 'JPG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('GW3P0AImage2', NULL, NULL, 'Image for Maximizer', 'SunGrepaWealthMAximizer.png', 'PNG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")

          db.commit
        rescue Exception => e
          db.rollback
          puts 'Error while manipulating table Collateral #{e}'
        end

        begin
          db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
          db.start_transaction

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('GW2P0AColl', 'Collateral for Sun Grepa Wealth Prime 7', NULL, NULL, NULL, NULL, NULL, 'GW2P0AImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FCVP0AColl', 'Collateral for Sun Grepa ProSecure 5', NULL, NULL, NULL, NULL, NULL, 'PS_Cover', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '4', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('RL1P0A_Coll', 'Collateral_For_Sun_Grepa_PB1', NULL, NULL, NULL, NULL, NULL, 'PB1_Cover_New', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '4', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('RL1P0E_Coll', 'Collateral_For_Sun_Grepa_PB1_Age71to80', NULL, NULL, NULL, NULL, NULL, 'PB1_Cover_New', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '4', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('REVP0A_Coll', 'Collateral_for_Sun_Grepa_PB5', NULL, NULL, NULL, NULL, NULL, 'PB5AND10_Cover_New', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '4', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('RFXP0AColl', 'Collateral for Sun Grepa Power Builder 10', NULL, NULL, NULL, NULL, NULL, 'PB5AND10_Cover_New', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '6', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('RFCP0AColl', 'Collateral for Sun Grepa Power Builder 100', NULL, NULL, NULL, NULL, NULL, 'PB100_Cover_New', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '5', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('GPPP0AColl', 'Collateral for Sun Grepa ProSecure Plus Regular Pay', NULL, NULL, NULL, NULL, NULL, 'PSP_Cover_New', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '5', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('IBVP0AColl', 'Collateral for Sun Grepa ProSecure Plus 5', NULL, NULL, NULL, NULL, NULL, 'PSP_Cover_New', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '6', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('IBXP0AColl', 'Collateral for Sun Grepa ProSecure Plus 10', NULL, NULL, NULL, NULL, NULL, 'PSP_Cover_New', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '5', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('TRAD_Coll', 'Collateral_For_Trad_ProdFam', NULL, NULL, NULL, NULL, NULL, 'TRAD_Cover', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('VUL_Coll', 'Collateral_For_Vul_ProdFam', NULL, NULL, NULL, NULL, NULL, 'VUL_Cover', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('FCXP0AColl', 'Collateral for Sun Grepa ProSecure 10', NULL, NULL, NULL, NULL, NULL, 'PS_Cover', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '4', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('GPSP0AColl', 'Collateral for Sun Grepa ProSecure Regular Pay', NULL, NULL, NULL, NULL, NULL, 'PS_Cover', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '4', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('HIBColl', 'Collateral for Hospital Income Benefit', NULL, NULL, NULL, NULL, NULL, 'HIBImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('LBRColl', 'Collateral for Living Benefit Rider', NULL, NULL, NULL, NULL, NULL, 'LBRImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('Grepa5YRCTColl', 'Collateral for ProTerm Rider - 5YRCT', NULL, NULL, NULL, NULL, NULL, 'Grepa5YRCTImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('TDBColl', 'Collateral for Total Disability Benefit', NULL, NULL, NULL, NULL, NULL, 'TDBImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WPDColl', 'Collateral for Waiver of Premium on Death of Initial Owner', NULL, NULL, NULL, NULL, NULL, 'WPDImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('WPDDColl', 'Collateral for Waiver of Premium upon Death or Disability of Initial Owner', NULL, NULL, NULL, NULL, NULL, 'WPDDImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('ADBColl', 'Collateral for Accidental Death Benefit', NULL, NULL, NULL, NULL, NULL, 'ADBImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '3', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('CIBColl', 'Collateral for Critical Illness Benefit', NULL, NULL, NULL, NULL, NULL, 'CIBImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '5', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('RA1P0BColl', 'Collateral for Sun Grepa First Aid Plus - 50% ROP', NULL, NULL, NULL, NULL, NULL, 'RA1P0BImage', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.execute_sql("INSERT INTO CollateralRenderLevel ('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('GW3P0AColl', 'Collateral for Sun Grepa Wealth Maximizer', NULL, NULL, NULL, NULL, NULL, 'GW3P0AImage2', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")

          db.commit

        rescue Exception => e
          db.rollback
          puts 'Error while manipulating table CollateralRenderLevel #{e}'
        end

        if collateralData == nil
          collateralData = Application.new
          collateralData.key='collateralData'
          collateralData.value = 'YES'
          collateralData.save 
        end
      end
    end
    if !Rho::System.isRhoSimulator and Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='1'
      Rho::Ruby.callNativeCallback("RubyServerInitialized", nil)
    end
  end
  
    def on_migrate_source(old_version, new_src)
      puts ">>>old_version: #{old_version} new_src version: #{new_src['schema_version']} schema_name: #{new_src['name']}"
      #############  fresh installation process start For app version  ######################
      Mobisys::Settings.setRhoconfigParams
      Mobisys::Settings.updateRhoconfigParams

      fresh_app_version = $rhoconfig[:fresh_app_version]
      fresh_install = $rhoconfig[:fresh_install]
      app_version = Application.getValue('app_version')
      p ">>>>++++fresh_app_version: #{fresh_app_version} fresh_install:#{fresh_install} app_version:#{app_version}"
      installed_version = Rho::RhoConfig.app_version
      app_version_value = app_version.value.to_s if app_version
      showFreshInstallPopup = false
      if (fresh_install.to_s == "YES" && installed_version.to_f == fresh_app_version.to_f) || (fresh_install.to_s == "YES" && installed_version.to_f > fresh_app_version.to_f && app_version_value.to_f < fresh_app_version.to_f)
          showFreshInstallPopup = true
      
      end
      fresh_install_required = Application.getValue('FRESH_INSTALL_REQUIRED')
      freshInstall = Application.getValue('FRESH_INSTALL_REQUIRED').value if fresh_install_required
      Application.create('FRESH_INSTALL_REQUIRED','NO') if freshInstall.to_s == "" 


      if showFreshInstallPopup
        Application.updateValue('FRESH_INSTALL_REQUIRED', 'YES')
      end
      #############  fresh installation process start For app version end  ######################


      if new_src['name'] == "Application"
        dbPath = Rho::RhoApplication.get_model_path('app', 'db')
        seedFile = dbPath + 'fixtures' + File::SEPARATOR + 'syncdbmaster.sqlite.zip'
        result = Rhom::Rhom.database_import('master',seedFile)
        puts "DB import was successful with result #{result}" if result
        puts "DB import returned no result" unless result
        if result
          Application.updateValue("DBVERSION",$rhoconfig[:initial_db_version]) 
          file_dir_name = Rho::RhoApplication.get_blob_folder
          FileUtils::mkdir_p file_dir_name unless Dir.exists?(file_dir_name)
        end
      end

      if new_src['name'] == "InwardDetails" && old_version.to_f < 1.3 #old was 1.0
        db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
        db.start_transaction
        begin
          db.execute_sql("ALTER TABLE InwardDetails ADD COLUMN authCode FLOAT DEFAULT NULL")
          db.execute_sql("ALTER TABLE InwardDetails ADD COLUMN midCd varchar DEFAULT NULL")
          db.commit
        rescue Exception => e
          db.rollback
          puts "Error while manipulating table InwardDetails #{e}"
        end
      end

      if new_src['name'] == "Inward" && old_version.to_f < 1.1 #old was 1.0
        db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
        db.start_transaction
        begin
          db.execute_sql("ALTER TABLE Inward ADD COLUMN inwardNum varchar DEFAULT NULL")
          db.commit
        rescue Exception => e
          db.rollback
          puts "Error while manipulating table Inward #{e}"
        end
        begin
          db.execute_sql("ALTER TABLE Inward ADD COLUMN workflowInwardNum varchar DEFAULT NULL")
          db.commit
        rescue Exception => e
          db.rollback
          puts "Error while manipulating table Inward #{e}"
        end
      end
      
      if new_src['name'] == "QuestionContainer" && old_version.to_f < 1.1 #old was 1.0
        db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
        db.start_transaction
        begin
          db.execute_sql("ALTER TABLE ServiceQuestionResponse ADD COLUMN visitedTabs varchar DEFAULT NULL")
          db.commit
        rescue Exception => e
          db.rollback
          puts "Error while manipulating table ServiceQuestionResponse #{e}"
        end
        begin
          db.execute_sql("update servicequestionresponse set visitedTabs = 'tab_agentDeclaration' where entityguid in (select guid from policy where statusCd in ('PENDING', 'COMPLETED', 'ACCEPTED')) and questionnaireTypeCd = 'AGENT' and (visitedTabs IS NULL or visitedTabs = '')")

          db.execute_sql("update servicequestionresponse set visitedTabs = 'tab_questionnaire' where entityguid in (select guid from policy where statusCd in ('PENDING', 'COMPLETED', 'ACCEPTED')) and questionnaireTypeCd = 'INSUREDPARTY' and (visitedTabs IS NULL or visitedTabs = '')")

          db.execute_sql("update servicequestionresponse set visitedTabs = 'tab_questionnaire' where entityguid in (select guid from policy where statusCd in ('PENDING', 'COMPLETED', 'ACCEPTED')) and questionnaireTypeCd = 'PROPOSERPARTY' and (visitedTabs IS NULL or visitedTabs = '')")
          db.commit
        rescue Exception => e
          db.rollback
          puts "Error while manipulating data for table ServiceQuestionResponse #{e}"
        end
      end

      if new_src['name'] == "PolicyAdditionalFields" && old_version.to_f < 1.2 #old was 1.0
        db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
        db.start_transaction
        begin
          db.execute_sql("ALTER TABLE PolicyAdditionalFields ADD COLUMN removed varchar DEFAULT NULL")
          db.commit
        rescue Exception => e
          db.rollback
          puts "Error while manipulating table PolicyAdditionalFields #{e}"
        end
      end

      if new_src['name'] == "Collateral" && old_version.to_f < 1.1 #old was 1.0
        db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
        db.start_transaction
        begin
          db.execute_sql("INSERT INTO Collateral('collateralCd', 'levelCd', 'header', 'description', 'fileName', 'fileType', 'embedType', 'colVersion', 'colStatus', 'fileEncrypted', 'encryptionIv', 'path', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('GW3P0AImage2', NULL, NULL, 'Image for Maximizer', 'SunGrepaWealthMAximizer.png', 'PNG', 'INLINE', '1', 'PENDING', NULL, NULL, NULL, NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM Collateral), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM Collateral));")
          db.execute_sql("INSERT INTO CollateralRenderLevel('levelCd', 'levelDesc', 'parentLevelCd', 'childLayoutTypeCd', 'sortOrder', 'header1', 'header2', 'icon', 'contentEmbedTypeCd', 'contentPart1TypeCd', 'contentPart1', 'contentPart2TypeCd', 'contentPart2', 'footer1', 'footer2', 'countPerRow', 'previousMenuFl', 'userId', 'parentKey', 'versionID', 'id', 'guid', 'systemCreatedDt', 'systemUpdatedDt', 'object') VALUES ('GW3P0AColl', 'Collateral for Sun Grepa Wealth Maximizer', NULL, NULL, NULL, NULL, NULL, 'GW3P0AImage2', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO', NULL, NULL, '1', NULL, (SELECT IFNULL(MAX(CAST(guid AS INTEGER)), 0) + 1 FROM CollateralRenderLevel), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT IFNULL(MAX(CAST(object AS INTEGER)), 0) + 1 FROM CollateralRenderLevel));")
          db.commit
        rescue Exception => e
          db.rollback
          puts "Error while manipulating table Collateral and CollateralRenderLevel #{e}"
        end
      end
      if new_src['name'] == "Quotation" && old_version.to_f < 1.1 #old was 1.0
        db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
        db.start_transaction
        begin
          db.execute_sql("update QuotationProduct set partyRoleCd = 'PRIMARY' where parentkey in (select q.object from quotation q where q.proposerLASame in ('YES', 'COPYFROMINSURED')) and partyRoleCd in ('PROPCUMINS');")
          db.execute_sql("update Quotation set unselectedRiders = (select QuotationParty.guid || substr(Quotation.unselectedRiders, instr(Quotation.unselectedRiders, ':')) from QuotationParty where QuotationParty.parentkey = Quotation.object and QuotationParty.roleCd = 'PRIMARY') where Quotation.proposerLASame in ('YES','COPYFROMINSURED') and Quotation.unselectedRiders is not null and Quotation.unselectedRiders <> '' and substr(Quotation.unselectedRiders, 1, instr(Quotation.unselectedRiders, ':') - 1) <> (select QuotationParty.guid from QuotationParty where QuotationParty.parentkey = Quotation.object and QuotationParty.roleCd = 'PRIMARY');")
          db.commit
        rescue Exception => e
          db.rollback
          puts "Error while manipulating table PolicyAdditionalFields #{e}"
        end
      end
      if new_src['name'] == "Policy" && old_version.to_f < 1.2 #old was 1.0
        db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
        db.start_transaction
        begin
          db.execute_sql("update PolicyProduct set partyRoleCd = 'PRIMARY' where parentkey in (select p.object from policy p where p.quoteProposerSameAsInsured in ('YES', 'COPYFROMINSURED')) and partyRoleCd in ('PROPCUMINS');")
          db.execute_sql("update PolicyProductInsured set insuredSequenceTypeCd = 'PRIMARY', roleCd = 'PRIMARY' where roleCd = 'PROPCUMINS' and parentkey in (select pp.object from PolicyProduct pp where pp.parentkey in (select p.object from Policy p where p.quoteProposerSameAsInsured in ('YES','COPYFROMINSURED')));")
          
          db.commit
        rescue Exception => e
          db.rollback
          puts "Error while manipulating table PolicyAdditionalFields #{e}"
        end
      end
      

      # getQuestionSetHash if result && $questionSetData == nil
      # getQuestionSetQuestionHash if result && $inputTypeOfQuestion.empty?
      return true
    end
  
  def on_activate_app
    if System.get_property('platform') == 'WINDOWS_DESKTOP'
      # setting windows compatibility
      appsBundleFolder = Rho::Application.appsBundleFolder.split(File::SEPARATOR)
      appsBundleFolder.delete('apps')
      appsBundleFolder.delete('rho')
      exeName = "#{appsBundleFolder[1]}.exe"
      pathToExe = appsBundleFolder.join(File::SEPARATOR)+File::SEPARATOR+exeName
      cmdStr = ''
      cmdStr << 'REG ADD "HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /V '
      cmdStr << pathToExe
      cmdStr << ' /T REG_SZ /D WIN7RTM /F'
      system(cmdStr)
    end
    #start geolocation
    # GeoLocation.set_notification("/app/Policy/geo_callback", "", $rhoconfig[:geolocation_callback_interval].to_i) if $rhoconfig.has_key?(:image_location_enabled) and $rhoconfig[:image_location_enabled]=='YES'

    if defined?(Rho::Push) && !Rho::System.isRhoSimulator && System.get_property('platform') != 'WINDOWS_DESKTOP'
      dev_id = Rho::Push.getDeviceId()
      puts "$$$$$ Application.onActivate() PUSH device id is = ["+dev_id.to_s+"]"
      # setup callback for push notifications
      Rho::Push.startNotifications("/app/AgentReg/push_callback")
      # start timer for wait when push device id will generate by system (actually for first run only when user should accept system UI request and grant rhights to application)
      # there are no push device ID until User grant rights to application via UI request from system
      Rho::Timer.start(500, '/app/AgentReg/wait_for_device_id', "rho_callback=1")
    end
  end
end

begin 
  require 'application_company'
rescue LoadError => e
  puts 'application_company not included'
end