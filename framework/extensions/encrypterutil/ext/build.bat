
if "%RHO_PLATFORM%" == "android" (

cd encrypterutil\platform\android
rake --trace

)

if "%RHO_PLATFORM%" == "iphone" (

cd encrypterutil\platform\phone
rake --trace

)

if "%RHO_PLATFORM%" == "wm" (

cd encrypterutil\platform\wm
rake --trace

)

if "%RHO_PLATFORM%" == "win32" (

cd encrypterutil\platform\wm
rake --trace

)

if "%RHO_PLATFORM%" == "bb" (

cd encrypterutil\platform\bb
rake --trace

)

