#include "common/app_build_capabilities.h"


extern "C" void Init_JSAPI_Fingerprint();
#ifndef RHO_NO_RUBY_API
extern "C" void Init_RubyAPI_Fingerprint();
extern "C" int  rho_ruby_is_started();
#endif

extern "C" void Init_Fingerprint_API()
{
#ifndef RHO_NO_RUBY_API
    if (rho_ruby_is_started())
    {
    	Init_RubyAPI_Fingerprint();
    }
#endif

#ifndef RHO_NO_JS_API
    Init_JSAPI_Fingerprint();
#endif
}
