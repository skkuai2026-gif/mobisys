#include "common/app_build_capabilities.h"


extern "C" void Init_JSAPI_Bmp();
#ifndef RHO_NO_RUBY_API
extern "C" void Init_RubyAPI_Bmp();
extern "C" int  rho_ruby_is_started();
#endif

extern "C" void Init_Bmp_API()
{
#ifndef RHO_NO_RUBY_API
    if (rho_ruby_is_started())
    {
    	Init_RubyAPI_Bmp();
    }
#endif

#ifndef RHO_NO_JS_API
    Init_JSAPI_Bmp();
#endif
}
