#encoding: UTF-8
require "CommonModules/schema_module"

class ReleaseManagement
    include MobiSys::MobiSysEntitySchema
    # include MobiSys::MobiSysFixedSchema
  
    set :schema_version, '1.0'
    # set :partition, :master
  
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specifc code here
	property :releaseCd, :string;
	property :releaseTypeCd, :string;
	property :description, :string;
	property :environmentTypeCd, :string;
	property :releaseStatusCd, :string;
	property :releaseDt, :date;
	property :applicableAgentGroup, :string;
	property :releaseVersion, :string;
	property :releaseMode, :string;
	property :releasePlatform, :string;

	# derived attributes
    # property :parentKey, :string
	property :userId, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    has_many 'ReleaseManagementDtl'

	def self.onlineClassName
      return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.ReleaseManagementDO"
    end

	def self.entitiesForSync
		releaseMgmt = ReleaseManagement.loadObject(:all)
		return releaseMgmt
	end

	def self.afterSync
		self.releaseStatusCd = "APPROVED"
		self.persist("fromSync")
	end

	def self.getFirstSyncDate(currentAgentReg)
		$userId == nil
        $userPassword == nil
        returnDt = nil
        $userId = currentAgentReg.userId unless $userId 
        $userPassword = currentAgentReg.regPass unless $userPassword
		# puts "Rho::System.platform :- #{Rho::System.platform}"
		dataRelease = ReleaseManagement.loadObject(:all, :conditions => {
				{ :name => 'releaseMode'} => 'DATA'
			}, 
	        :order => 'releaseDt', 
	        :orderdir => 'ASC')
        # puts "dataRelease :- #{dataRelease}"
        applicableGrpList = currentAgentReg.applicableAgentGroup.to_s.split(',')
        dataRelease.reject!{|rel| ((rel.applicableAgentGroup.to_s.split(",") & applicableGrpList) == nil) || rel.releaseStatusCd == "MOVED"}
        # puts "dataRelease after slice :- #{dataRelease}"
        if dataRelease.size > 0
        	# puts "dataRelease after slice :- #{dataRelease[0].releaseDt}"
        	returnDt = Time.parse(dataRelease[0].releaseDt)
        end
        $userId == nil
        $userPassword == nil
        # puts "returnDt :- #{returnDt.inspect}"
        # puts "returnDt :- #{returnDt.class.name}"
        # puts "Time.now.inspect :- #{Time.now.inspect}"
        return returnDt
	end


	def self.getReleases(currentAgentReg)
		dataRelease = ReleaseManagement.loadObject(:all, :conditions => {
				{ :name => 'releaseMode'} => 'DATA'
			}, 
	        :order => 'releaseDt', 
	        :orderdir => 'ASC')
        applicableGrpList = currentAgentReg.applicableAgentGroup.to_s.split(',')
        dataRelease.reject!{|rel| ((rel.applicableAgentGroup.to_s.split(",") & applicableGrpList) == nil) || rel.releaseStatusCd == "MOVED"}
        # puts "dataRelease :- #{dataRelease}"
        return dataRelease
	end

	def getDTReleaseDtl
		returnList = []
		self.ReleaseManagementDtlList.each do |relDtl|
			if relDtl.releaseEntityTypeCd.to_s == "TABLETYPEMAPPING" && relDtl.ReleaseDTScriptList.size > 0
				returnList << relDtl
			elsif relDtl.releaseEntityTypeCd.to_s == "ILLUSTRATIONMODEL" && relDtl.ReleaseDTScriptList.size > 0
				returnList << relDtl
			end
		end
		return returnList
	end

	# def self.getAppUpgradeDate(currentAgentReg)
	# 	$userId == nil
 #        $userPassword == nil
 #        $userId = currentAgentReg.userId unless $userId 
 #        $userPassword = currentAgentReg.regPass unless $userPassword
	# 	puts "Rho::System.platform :- #{Rho::System.platform}"
	# 	appRelease = ReleaseManagement.loadObject(:all, :conditions => {
	# 			{ :name => 'releaseMode'} => 'APP', 
	# 			{:name => 'releasePlatform'} => Rho::System.platform
	# 		}, 
	# 		:op => 'AND',
	#         :order => 'releaseVersion', 
	#         :orderdir => 'DESC')
 #        $userId == nil
 #        $userPassword == nil
	# end

end