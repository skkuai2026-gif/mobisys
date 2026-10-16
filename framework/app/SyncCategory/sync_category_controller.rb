require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'helpers/lang_module'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/syncmodule'
require 'fileutils'

class SyncCategoryController < Rho::RhoController
  include BrowserHelper
  include MobiSys::BrowserHelper

  # POST /SyncCategory/syncPreferences
  def syncPreferences
    renderToolbar(-1)
    #$showSync = false
    @synccategoriesHM = Hash.new
    synccategories = SyncCategory.find(:all)
    synccategories.each do |syncCategory|
      if @synccategoriesHM[syncCategory.categoryCd.to_s] == nil
        @synccategoriesHM[syncCategory.categoryCd.to_s] = []
        @synccategoriesHM[syncCategory.categoryCd.to_s].push syncCategory
      else
        @synccategoriesHM[syncCategory.categoryCd.to_s].push syncCategory
      end
    end
    synList = $rhoconfig[:synConfig]
    @synList = synList.split(',')
    render :action => :preferences, :layout => :newEAPPLayout
  end
  
  # POST /SyncCategory/synchronize
  def synchronize
    syncEntities = Array.new
    if @params['syncCategory']
      @params['syncCategory'].each do |key,value|
        puts "+++++key: #{key}----value--#{value}"
        if value.to_s == 'ON'
          #Fetch the SyncEntitites
          currentSyncEntities = SyncEntity.find(:all,:conditions=>{:entitySubCategory=>key.to_s})
          if currentSyncEntities
            currentSyncEntities.each do |currentSyncEntity|
              syncEntities.push currentSyncEntity
            end
          end  
          puts ">>Found #{syncEntities.to_s} for processing"
        end
      end
    end
    puts Thread.current.inspect + "Found #{syncEntities.size} for processing"
    $syncEntities = syncEntities
    System.start_timer(2000,url_for(:action=>:timerCallback),$syncEntities.to_s)
    render :action=> :syncProgress, :layout => :newEAPPLayout
  end
  
  # GET /SyncCategory/progress
  def progress
    render :action => :syncProgress
  end

  def outputimagesdownload
    syncLog = $syncLogHash['OutputImages']
    outputimagesversion = @params['outputimagesversion']
    filePath = @params['filePath']
    if @params['status'] == 'ok' and @params['http_error'] != "404" and @params['http_error'] != "500"
      System.unzip_file filePath
      File.delete filePath
      outputimagespath = "#{Rho::RhoApplication.get_base_app_path}public/images/outputimages"
      Dir.mkdir outputimagespath unless Dir.exist? outputimagespath
      Dir.foreach(outputimagespath) { |existingFile|
        next if existingFile == "." or existingFile == ".."
        existingFilePath = "#{outputimagespath}/#{existingFile}"
        # File.delete existingFilePath
      }
      sourceDir = "#{Rho::RhoApplication.get_blob_folder}/../outputimages"
      outputimagespath = "#{Rho::RhoApplication.get_base_app_path}public/images"
      FileUtils.cp_r(sourceDir,outputimagespath)
      FileUtils.rm_rf sourceDir
      Application.updateValue("OUTPUTIMAGESVERSION",outputimagesversion)
      $outputImagesSyncCompleted = true
      syncLog.status = "Completed"
    else
      syncLog.status = 'File download failed'
      $masterSyncActivity.setErrored
      Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('MASTERDOWNLOADFAILEDMESSAGE'),
        :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
        :callback=>'/app/SyncCategory/transactionpopupcallback'})
    end
    MobiSys::Sync.refreshUI
    if $outputImagesSyncCompleted and $masterSyncCompleted
      #Update last sync date in the application table - start
      
      MobiSys::Sync.syncApplicationDate

      #Update last sync date in the application table - end
      # set syncFlag to NO at online DeviceusermapDO      
      inputHash = Hash.new
      inputHash["YES"] = nil
      json = ::JSON.generate(inputHash)
      response = doJSONPost('/SyncFlagDB.run', json)
    end
    $masterSyncActivity.persistAll
    if $collateralDownloadHash.empty? && $masterSyncCompleted && $outputImagesSyncCompleted && $entityContextSyncCompleted && $transactionSyncCompleted
      WebView.navigate($rhoconfig[:post_login_path]) 
    else
      WebView.navigate('/app/SyncCategory/syncPreferences')
    end
  end  
  
  def masterdownload
    syncLog = $syncLogHash['Masters']
    dbVersion = @params['dbVersion']
    filePath = @params['filePath']
    if @params['status'] == 'ok' and @params['http_error'] != "404" and @params['http_error'] != "500"
      product = Product.new
      product.save
      product.delete
      backupDBFiles
      selectedLanguage = Application.getValue('DEFAULTLOCALE').value
      result = Rhom::Rhom.database_import('master',filePath)
      Localization::LabelCache.instance.resetLabels(selectedLanguage)
      puts "DB import was successful with result #{result}" if result
      puts "DB import returned no result" unless result
      if result
        restoreFiles
        File::delete filePath if File::exist? filePath
        Application.updateValue("DBVERSION",dbVersion)
        syncLog.status = 'Completed'
        $masterSyncCompleted = true

        if $outputImagesSyncCompleted and $masterSyncCompleted
          #Update last sync date in the application table - start
          
          MobiSys::Sync.syncApplicationDate

          #Update last sync date in the application table - end
          $showSync = false
          $dbUpdateMandatory = false
          # set syncFlag to NO at online DeviceusermapDO      
          inputHash = Hash.new
          inputHash["YES"] = nil
          json = ::JSON.generate(inputHash)
          response = doJSONPost('/SyncFlagDB.run', json)
          #process results  
        end 
      else
        syncLog.status = 'DB import failed'
        $masterSyncActivity.setErrored
        Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('MASTERIMPORTFAILEDMESSAGE'),
          :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
          :callback=> $dbUpdateMandatory ? '/app/SyncCategory/transactionpopupcallback' : '/app/SyncCategory/loginpopupcallback' })
      end
    else
      syncLog.status = 'File download failed'
      $masterSyncActivity.setErrored
      Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('MASTERDOWNLOADFAILEDMESSAGE'),
          :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
          :callback=>$dbUpdateMandatory ? '/app/SyncCategory/transactionpopupcallback' : '/app/SyncCategory/loginpopupcallback'})
    end
    $masterSyncActivity.persistAll
    MobiSys::Sync.refreshUI
    if $collateralDownloadHash.empty? && $masterSyncCompleted && $outputImagesSyncCompleted && $entityContextSyncCompleted && $transactionSyncCompleted
      WebView.navigate($rhoconfig[:post_login_path]) 
    # else
    #   WebView.navigate('/app/SyncCategory/syncPreferences')
    end
    #render :action => :blank
  end

  def masterFileUploadCallback
    puts ">>>upload Completed with params: #{@params}"
    fileName = @params['fileName']
    File.delete fileName
  end  
  
  # GET /SyncCategory/popupcallback
  def popupcallback
    System.exit
  end

  # GET /SyncCategory/popupcallback
  def loginpopupcallback
    WebView.navigate('/app/AgentReg/login')
  end
  
  # GET /SyncCategory/transactionpopupcallback
  def transactionpopupcallback
    WebView.navigate('/app/SyncCategory/syncPreferences')
  end
  
  def timerCallback
    System.stop_timer(url_for(:action=>:timerCallback))
    begin
      $syncLogs = Array.new
      transactionEntityCount = MobiSys::Sync.All($syncEntities)
      MobiSys::ProductBO.freeSpace
      #if(transactionEntityCount > 0)
      #  AgentReg.updateLastSyncDate
      #end
      # WebView.navigate($rhoconfig[:post_login_path]) if $collateralDownloadHash.empty? and $masterSyncCompleted
      if $collateralDownloadHash.empty? && $masterSyncCompleted && $outputImagesSyncCompleted && $entityContextSyncCompleted && $transactionSyncCompleted
        WebView.navigate($rhoconfig[:post_login_path])
      end
    rescue StandardError => boom
      puts boom
    end
  end
  
  def backupDBFiles
    if Dir.exist? Rho::RhoApplication.get_blob_folder
      backupDir = Rho::RhoApplication.get_blob_folder + '/../backup'
      Dir.mkdir backupDir unless Dir.exist? backupDir
      FileUtils.cp_r(Rho::RhoApplication.get_blob_folder + '/.', backupDir)        
    end
  end
  
  def restoreFiles
    Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
    backupDir = Rho::RhoApplication.get_blob_folder + '/../backup/.'
    FileUtils.cp_r(backupDir, Rho::RhoApplication.get_blob_folder)
    FileUtils.rm_rf backupDir
  end

  def self.backupDBFiles
    if Dir.exist? Rho::RhoApplication.get_blob_folder
      backupDir = Rho::RhoApplication.get_blob_folder + '/../backup'
      Dir.mkdir backupDir unless Dir.exist? backupDir
      FileUtils.cp_r(Rho::RhoApplication.get_blob_folder + '/.', backupDir)        
    end
  end
  
  def self.restoreFiles
    Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
    backupDir = Rho::RhoApplication.get_blob_folder + '/../backup/.'
    FileUtils.cp_r(backupDir, Rho::RhoApplication.get_blob_folder)
    FileUtils.rm_rf backupDir
  end

end

begin
  require 'SyncCategory/sync_category_controller_Jazz' if $rhoconfig[:TABFEATUREREQD]
rescue LoadError => e
    puts 'sync_category_controller_Jazz not included'
end

begin 
    require 'SyncCategory/sync_category_controller_company'
rescue LoadError => e
    puts 'sync_category_controller_company not included'
end
