# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
require 'CommonModules/entityschema'
class Collateral
	include MobiSys::MobiSysEntitySchema

	set :schema_version, '1.0'
	# Uncomment the following line to enable sync with Collateral.
	# enable :sync

	#C2L add model specifc code here

	property :collateralCd, :string
	property :levelCd, :string
	property :header, :string
	property :description, :string
	property :fileName, :string
	property :fileType, :string
	property :embedType, :string
	property :colVersion, :integer
	property :colStatus, :string
	property :fileEncrypted ,:string
	property :encryptionIv, :string
	property :path, :string

	# derived attributes
	property :userId, :string
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time
  
	def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.collateral.Collateral"
	end

	def self.entitiesForSync
		#entitiesForSync = Collateral.loadObject(:all, :conditions => {{:name => "colStatus",:op => "NOT" } => "PRESEEDED" })
		return []
	end
  
	def afterSync
		#puts "Collateral synced with collateralCd #{self.collateralCd}"
		lastSyncDate = Time.at(0)
		lastSyncDateAppObject = Application.getValue("Collateral_" + $userId + '_lastSyncDate')
        if lastSyncDateAppObject
            lastSyncDate = Time.load(lastSyncDateAppObject.value)
        end
     	if self.colStatus.to_s == "" || self.systemUpdatedDt == nil || (Time.parse(self.systemUpdatedDt) > Time.parse(lastSyncDate.to_s))
			self.colStatus = 'PENDING'
			$collateralDownloadHash[self.fileName] = $collateralDownloadHash[self.fileName].to_s + "," + self.collateralCd.to_s
		else
			windows_platform = System.get_property('platform') == 'WINDOWS_DESKTOP'
			is_rho_simulator = Rho::System.isRhoSimulator
			unless $rhoconfig[:useCollateralRenderLevel]
		        if windows_platform
		            destFilePath = File.join(Rho::Application.publicFolder, "collateral")
		            Dir.mkdir(destFilePath) unless Dir.exist?(destFilePath)
		            destFilePath = File.join(destFilePath, self.fileName)
		            if self.embedType.to_s == "EXTERNAL"
		                self.fileName = destFilePath
		            else
		                self.fileName = destFilePath[destFilePath.index("public")-1..-1]
		            end
		        else
		            if is_rho_simulator
		        		Dir.mkdir(Rho::RhoApplication.get_blob_folder) unless Dir.exist?(Rho::RhoApplication.get_blob_folder)
		            	filePath = File.join(Rho::RhoApplication.get_blob_folder, self.fileName)
		                if self.embedType.to_s == "EXTERNAL"
		                    self.fileName = filePath
		                else
		                    self.fileName = filePath[filePath.index("rhosimulator")-1..-1]
		                end
		            else
		        		Dir.mkdir(Rho::RhoApplication.userFolder) unless Dir.exist?(Rho::RhoApplication.userFolder)
		            	filePath = File.join(Rho::RhoApplication.userFolder, self.fileName)
		                self.fileName = filePath
		            end
		        end
	        end
			self.colStatus = 'COMPLETED'
		end
	end

	def beforeSync
		self.fileName = self.fileName.to_s.split("#{File::SEPARATOR}").last
	end

end