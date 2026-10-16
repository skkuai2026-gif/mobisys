require 'helpers/lang_module'

module Localization
  include Commonlang
 
  LANGUAGE = 'en'
    
  class LabelCache < BaseLang
    def initialize
      init(Localization::LANGUAGE)
    end
  end
end