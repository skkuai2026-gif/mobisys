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

# we need to use dot separator for hash in policymodel expression
# e.g. PolicyDocumentDO.GISSDAF.SLDE1.selected (sunphv8)
class Hash
  class << self
    attr_accessor :use_dot_syntax
    attr_accessor :hash_dot_use_default
  end

  attr_accessor :use_dot_syntax
  attr_accessor :hash_dot_use_default

  def to_dot(use_default: false)
    dotify_hash(self, use_default: use_default)

    self
  end

  def method_missing(method, *args)
    return super(method, *args) unless to_dot?

    method, chain = method.to_s.split(".", 2).map(&:to_sym)

    return send(method).send(chain, *args) if chain

    prop = create_prop(method)

    if setter?(method)
      self[prop] = args.first
    elsif key?(prop) || use_default?
      self[prop]
    else
      super(method, args)
    end
  end

  def respond_to?(method, include_all = false) # rubocop:disable Style/OptionalBooleanParameter
    return super(method, include_all) unless to_dot?

    prop = create_prop(method)
    return true if key?(prop)

    super(method, include_all)
  end

  private

  def dotify_obj(obj, use_default: false)
    case obj
    when Array
      obj.each do |el|
        dotify_obj(el, use_default: use_default)
      end
    when Hash
      dotify_hash(obj, use_default: use_default)
      # else no-op
    end
  end

  def dotify_hash(hash, use_default: false)
    hash.use_dot_syntax = true
    hash.hash_dot_use_default = use_default

    hash.each_value do |val|
      if val.is_a? Hash
        val.to_dot
      else
        dotify_obj(val, use_default: use_default)
      end
    end
  end

  def to_dot?
    use_dot_syntax || self.class.use_dot_syntax
  end

  def use_default?
    hash_dot_use_default || self.class.hash_dot_use_default
  end

  def setter?(method)
    method.last == "="
  end

  def create_prop(method)
    prop = basic_prop_from_method(method)

    key?(prop.to_s) ? prop.to_s : prop
  end

  def basic_prop_from_method(method)
    setter?(method) ? method.chop : method
  end
end

class Symbol
  def chop
    to_s.chop.to_sym
  end

  def last
    slice(-1, 1)
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
    #@default_menu = { }
    # Uncomment to set sync notification callback to /app/Settings/sync_notify.
    # SyncEngine::set_objectnotify_url("/app/Settings/sync_notify")
    # SyncEngine.set_notification(-1, "/app/Settings/sync_notify", '')
    
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
            # begin
            #   calendar = MobiSys::Calendar.create(event)
            # rescue MobiSys::CalendarAccessError => error 
            #   puts "Calendar Access Not Available"
            # end
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

      #for headersection
      # dimoge = Application.getValue('Dimoge')
      # if dimoge == nil
      #   dimoge = Application.new
      #   dimoge.key = 'Dimoge'
      #   dimoge.value = $rhoconfig[:Dimoge]
      #   dimoge.save
      # end

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

    if !Rho::System.isRhoSimulator and Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='1'
      Rho::Ruby.callNativeCallback("RubyServerInitialized", nil)
    end

    Mobisys::Settings.updateRhoconfigParams
    
  end
  
  def on_migrate_source(old_version, new_src)
    puts ">>>old_version: #{old_version} new_src version: #{new_src['schema_version']} schema_name: #{new_src['name']}"
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