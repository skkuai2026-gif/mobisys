require "CommonModules/schema_module"

class Search
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master
  
    #add model specifc code here
    
    property :mainQuery, :string
    property :postQuery, :string
    property :searchName, :string
    property :searchFor, :string
    property :deleteLink, :string
    property :maxResults, :integer
    property :resultActions, :string
    property :queryPartition, :string

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
    has_many 'SearchResultField'
    has_many 'SearchCriterion'

    
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.OfflineSearchDO"
    end
    
    def self.getSearchByName(searchName)
        return Search.loadObject(:first, :conditions => {
                                        {
                                          :name => "searchName"
                                        } => searchName
                                    })
        # searchList = getSearchMaster
        # searchList.each do |search|
        #     return search if search.searchName == searchName
        # end
    end

    def self.getSearchByType(searchFor)
        return Search.loadObject(:all, :conditions => {
                                        {
                                          :name => "searchFor"
                                        } => searchFor
                                    })
        # searchList = getSearchMaster
        # searchListReturn = []
        # searchList.each do |search|
        #     searchListReturn << search if search.searchFor == searchFor
        # end
        # return searchListReturn
    end

    def parseLinksforResultActionstoHM
      linkMap = {}
      linkActions = []
      linkText = self.resultActions
      if(linkText.to_s != "" && linkText.include?("|"))
        linkActions = linkText.split("|")
      else
        linkActions << linkText
      end
      if(linkActions.to_s != "" && linkActions.size > 0)
        linkActions.each do |linkAction|
            action = linkAction[0,linkAction.index("::")];
            #  allLinkAction = linkAction.gsub(linkAction.substring(0,linkAction.indexOf("::") + 2), "");
            allLinkAction = linkAction.gsub(linkAction[0,linkAction.index("::") + 2], "")
            links = allLinkAction.split("]");
            internalLinkHM = {}
            links.each do |linkDetails|
              if(linkDetails.include?("link:"))
                link = linkDetails[linkDetails.index("link:") + 5,linkDetails.length()];
                if(linkDetails.include?("link"))  
                  internalLinkHM["link"] = link
                end
              end
              if(linkDetails.include?("icon:"))
                icon = linkDetails[linkDetails.index("icon:") + 5,linkDetails.length()];
                if(linkDetails.include?("icon"))
                  internalLinkHM["icon"] = icon
                end
              end
            end
          linkMap[action] = internalLinkHM
        end
      end
      return linkMap;
    end
end
