require 'helpers/lang_module'

module Localization
  include Commonlang
 
  LANGUAGE = 'ch'
    
  class LabelCache < BaseLang
    def initialize
      init(Localization::LANGUAGE)
    end
  end
end