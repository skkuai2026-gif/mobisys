module MobiSys
  module Signature
    def self.take(url, imgFormat = "bmp", penColor = 0xff0000, penWidth= 5, border = true, bgColor = 0xffffff)
      Rho::SignatureCapture.take( url, 
                                    { :imageFormat => imgFormat, 
                                      :penColor => penColor, 
                                      :penWidth=> penWidth, 
                                      :border => border, 
                                      :bgColor => bgColor}
                                 )
    end
  end
end
