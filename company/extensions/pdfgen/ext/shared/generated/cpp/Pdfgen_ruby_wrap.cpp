
#include "PdfgenBase.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "Pdfgen"

#include "api_generator/RubyResultConvertor.h"

#include "ruby/ext/rho/rhoruby.h"
#include "common/StringConverter.h"
#include "common/AutoPointer.h"

using namespace rho;
using namespace rho::common;
using namespace rho::apiGenerator;

extern "C"
{
void rho_os_impl_performOnUiThread(rho::common::IRhoRunnable* pTask);
VALUE getRuby_Pdfgen_Module();


VALUE rb_Pdfgen_s_default(VALUE klass)
{
    rho::String strDefaultID = rho::CPdfgenFactoryBase::getPdfgenSingletonS()->getDefaultID();

    return rho_ruby_create_object_with_id( klass, strDefaultID.c_str() );
}

VALUE rb_Pdfgen_s_setDefault(VALUE klass, VALUE valObj)
{
    const char* szID = rho_ruby_get_object_id( valObj );
    rho::CPdfgenFactoryBase::getPdfgenSingletonS()->setDefaultID(szID);

    return rho_ruby_get_NIL();
}


static void string_iter(const char* szVal, int valueLen, void* par)
{
    rho::Vector<rho::String>& ar = *((rho::Vector<rho::String>*)(par));
    ar.addElement( rho::String(szVal,valueLen) );
}

static void getStringArrayFromValue(VALUE val, rho::Vector<rho::String>& res)
{
    rho_ruby_enum_strary_json(val, string_iter, &res);
}

static void hash_eachstr(const char* szName, const char* szVal, int valueLen, void* par)
{
    rho::Hashtable<rho::String, rho::String>& hash = *((rho::Hashtable<rho::String, rho::String>*)(par));
    hash.put( szName, rho::String(szVal,valueLen) );
}

static void getStringHashFromValue(VALUE val, rho::Hashtable<rho::String, rho::String>& res)
{
    rho_ruby_enum_strhash_json(val, hash_eachstr, &res);
}
    
static rho::String getStringObjectFromValue(VALUE val)
{
    return rho::String(getStringFromValue(val),getStringLenFromValue(val));
}


static VALUE _api_generator_Pdfgen_getSimpleStringProperty(int argc, VALUE *argv, rho::IPdfgen* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    oRes.setRequestedType(CMethodResult::eString);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(0) );
        return oRes.toRuby();
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor1( pObj, &rho::IPdfgen::getSimpleStringProperty,  oRes );
        rho::CPdfgenFactoryBase::getPdfgenSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->getSimpleStringProperty(  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_Pdfgen_getSimpleStringProperty(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IPdfgen* pObj =  rho::CPdfgenFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_Pdfgen_getSimpleStringProperty(argc, argv, pObj);

    return res;
}



VALUE rb_s_Pdfgen_def_getSimpleStringProperty(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CPdfgenFactoryBase::getPdfgenSingletonS()->getDefaultID();
    rho::IPdfgen* pObj = rho::CPdfgenFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_Pdfgen_getSimpleStringProperty(argc, argv, pObj);
}


static VALUE _api_generator_Pdfgen_setSimpleStringProperty(int argc, VALUE *argv, rho::IPdfgen* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(1) );
        return oRes.toRuby();
    }
    rho::String arg0 = "";
    if ( argc > 0 )
    {
        if ( rho_ruby_is_string(argv[0]) )
        {
            arg0 = getStringObjectFromValue(argv[0]);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "string" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(1) );
        return oRes.toRuby();
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor2( pObj, &rho::IPdfgen::setSimpleStringProperty, arg0,  oRes );
        rho::CPdfgenFactoryBase::getPdfgenSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->setSimpleStringProperty( arg0,  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_Pdfgen_setSimpleStringProperty(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IPdfgen* pObj =  rho::CPdfgenFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_Pdfgen_setSimpleStringProperty(argc, argv, pObj);

    return res;
}



VALUE rb_s_Pdfgen_def_setSimpleStringProperty(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CPdfgenFactoryBase::getPdfgenSingletonS()->getDefaultID();
    rho::IPdfgen* pObj = rho::CPdfgenFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_Pdfgen_setSimpleStringProperty(argc, argv, pObj);
}


VALUE rb_s_Pdfgen_enumerate(int argc, VALUE *argv)
{
    rho::apiGenerator::CMethodResult oRes;


    oRes.setParamName( "result" );
    oRes.setRubyObjectClass( getRuby_Pdfgen_Module() );
    oRes.setRequestedType(CMethodResult::eStringArray);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    if ( argc > nCallbackArg )
    {

        if ( rho_ruby_is_proc(argv[nCallbackArg]) || rho_ruby_is_method(argv[nCallbackArg]) )
        {
            oRes.setRubyCallbackProc( argv[nCallbackArg] );
        }else if ( rho_ruby_is_string(argv[nCallbackArg]) )
        {
            oRes.setRubyCallback( getStringObjectFromValue(argv[nCallbackArg]) );
        }else
        {
            oRes.setArgError("Type error: callback should be String");
            return oRes.toRuby();
        }

        oRes.setCallInUIThread(false);
        if ( argc > nCallbackArg + 1 )
        {
            if ( !rho_ruby_is_NIL(argv[nCallbackArg + 1]) )
            {
                if ( !rho_ruby_is_string(argv[nCallbackArg + 1]) )
                {
                    oRes.setArgError("Type error: callback parameter should be String");
                    return oRes.toRuby();
                }

                oRes.setCallbackParam( getStringObjectFromValue(argv[nCallbackArg + 1]) );
            }
        }
        
        bUseCallback = true;
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor1( rho::CPdfgenFactoryBase::getPdfgenSingletonS(), &rho::IPdfgenSingleton::enumerate,  oRes );
        rho::CPdfgenFactoryBase::getPdfgenSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        rho::CPdfgenFactoryBase::getPdfgenSingletonS()->enumerate(  oRes );
    }
    
    return oRes.toRuby();
}






static VALUE _api_generator_Pdfgen_generateAndroidPDF(int argc, VALUE *argv, rho::IPdfgen* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    oRes.setRequestedType(CMethodResult::eString);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(4) );
        return oRes.toRuby();
    }
    rho::String arg0 = "";
    if ( argc > 0 )
    {
        if ( rho_ruby_is_string(argv[0]) )
        {
            arg0 = getStringObjectFromValue(argv[0]);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "string" );
            return oRes.toRuby();
        }
    }

    nCallbackArg = 2;
    if ( argc == 1 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(4) );
        return oRes.toRuby();
    }
    rho::String arg1 = "";
    if ( argc > 1 )
    {
        if ( rho_ruby_is_string(argv[1]) )
        {
            arg1 = getStringObjectFromValue(argv[1]);
        }
        else if (!rho_ruby_is_NIL(argv[1]))
        {
            oRes.setArgError("Type error: argument " "1" " should be " "string" );
            return oRes.toRuby();
        }
    }

    nCallbackArg = 3;
    if ( argc == 2 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(4) );
        return oRes.toRuby();
    }
    rho::String arg2 = "";
    if ( argc > 2 )
    {
        if ( rho_ruby_is_string(argv[2]) )
        {
            arg2 = getStringObjectFromValue(argv[2]);
        }
        else if (!rho_ruby_is_NIL(argv[2]))
        {
            oRes.setArgError("Type error: argument " "2" " should be " "string" );
            return oRes.toRuby();
        }
    }

    nCallbackArg = 4;
    if ( argc == 3 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(4) );
        return oRes.toRuby();
    }
    rho::String arg3 = "";
    if ( argc > 3 )
    {
        if ( rho_ruby_is_string(argv[3]) )
        {
            arg3 = getStringObjectFromValue(argv[3]);
        }
        else if (!rho_ruby_is_NIL(argv[3]))
        {
            oRes.setArgError("Type error: argument " "3" " should be " "string" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(4) );
        return oRes.toRuby();
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor5( pObj, &rho::IPdfgen::generateAndroidPDF, arg0, arg1, arg2, arg3,  oRes );
        rho::CPdfgenFactoryBase::getPdfgenSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->generateAndroidPDF( arg0, arg1, arg2, arg3,  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_Pdfgen_generateAndroidPDF(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IPdfgen* pObj =  rho::CPdfgenFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_Pdfgen_generateAndroidPDF(argc, argv, pObj);

    return res;
}



VALUE rb_s_Pdfgen_def_generateAndroidPDF(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CPdfgenFactoryBase::getPdfgenSingletonS()->getDefaultID();
    rho::IPdfgen* pObj = rho::CPdfgenFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_Pdfgen_generateAndroidPDF(argc, argv, pObj);
}


static VALUE _api_generator_Pdfgen_generateAndroidPDFCharts(int argc, VALUE *argv, rho::IPdfgen* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    oRes.setRequestedType(CMethodResult::eString);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(3) );
        return oRes.toRuby();
    }
    rho::String arg0 = "";
    if ( argc > 0 )
    {
        if ( rho_ruby_is_string(argv[0]) )
        {
            arg0 = getStringObjectFromValue(argv[0]);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "string" );
            return oRes.toRuby();
        }
    }

    nCallbackArg = 2;
    if ( argc == 1 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(3) );
        return oRes.toRuby();
    }
    rho::String arg1 = "";
    if ( argc > 1 )
    {
        if ( rho_ruby_is_string(argv[1]) )
        {
            arg1 = getStringObjectFromValue(argv[1]);
        }
        else if (!rho_ruby_is_NIL(argv[1]))
        {
            oRes.setArgError("Type error: argument " "1" " should be " "string" );
            return oRes.toRuby();
        }
    }

    nCallbackArg = 3;
    if ( argc == 2 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(3) );
        return oRes.toRuby();
    }
    rho::String arg2 = "";
    if ( argc > 2 )
    {
        if ( rho_ruby_is_string(argv[2]) )
        {
            arg2 = getStringObjectFromValue(argv[2]);
        }
        else if (!rho_ruby_is_NIL(argv[2]))
        {
            oRes.setArgError("Type error: argument " "2" " should be " "string" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(3) );
        return oRes.toRuby();
    }
    pFunctor = rho_makeInstanceClassFunctor4( pObj, &rho::IPdfgen::generateAndroidPDFCharts, arg0, arg1, arg2,  oRes );
    rho_os_impl_performOnUiThread( pFunctor );
    
    return oRes.toRuby();
}



VALUE rb_Pdfgen_generateAndroidPDFCharts(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IPdfgen* pObj =  rho::CPdfgenFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_Pdfgen_generateAndroidPDFCharts(argc, argv, pObj);

    return res;
}



VALUE rb_s_Pdfgen_def_generateAndroidPDFCharts(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CPdfgenFactoryBase::getPdfgenSingletonS()->getDefaultID();
    rho::IPdfgen* pObj = rho::CPdfgenFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_Pdfgen_generateAndroidPDFCharts(argc, argv, pObj);
}


static VALUE _api_generator_Pdfgen_generateIOSPDF(int argc, VALUE *argv, rho::IPdfgen* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    oRes.setRequestedType(CMethodResult::eString);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(2) );
        return oRes.toRuby();
    }
    rho::String arg0 = "";
    if ( argc > 0 )
    {
        if ( rho_ruby_is_string(argv[0]) )
        {
            arg0 = getStringObjectFromValue(argv[0]);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "string" );
            return oRes.toRuby();
        }
    }

    nCallbackArg = 2;
    if ( argc == 1 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(2) );
        return oRes.toRuby();
    }
    rho::String arg1 = "";
    if ( argc > 1 )
    {
        if ( rho_ruby_is_string(argv[1]) )
        {
            arg1 = getStringObjectFromValue(argv[1]);
        }
        else if (!rho_ruby_is_NIL(argv[1]))
        {
            oRes.setArgError("Type error: argument " "1" " should be " "string" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(2) );
        return oRes.toRuby();
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor3( pObj, &rho::IPdfgen::generateIOSPDF, arg0, arg1,  oRes );
        rho::CPdfgenFactoryBase::getPdfgenSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->generateIOSPDF( arg0, arg1,  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_Pdfgen_generateIOSPDF(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IPdfgen* pObj =  rho::CPdfgenFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_Pdfgen_generateIOSPDF(argc, argv, pObj);

    return res;
}



VALUE rb_s_Pdfgen_def_generateIOSPDF(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CPdfgenFactoryBase::getPdfgenSingletonS()->getDefaultID();
    rho::IPdfgen* pObj = rho::CPdfgenFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_Pdfgen_generateIOSPDF(argc, argv, pObj);
}


static VALUE _api_generator_Pdfgen_mergeIOSPDF(int argc, VALUE *argv, rho::IPdfgen* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    oRes.setRequestedType(CMethodResult::eString);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(4) );
        return oRes.toRuby();
    }
    rho::String arg0 = "";
    if ( argc > 0 )
    {
        if ( rho_ruby_is_string(argv[0]) )
        {
            arg0 = getStringObjectFromValue(argv[0]);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "string" );
            return oRes.toRuby();
        }
    }

    nCallbackArg = 2;
    if ( argc == 1 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(4) );
        return oRes.toRuby();
    }
    rho::String arg1 = "";
    if ( argc > 1 )
    {
        if ( rho_ruby_is_string(argv[1]) )
        {
            arg1 = getStringObjectFromValue(argv[1]);
        }
        else if (!rho_ruby_is_NIL(argv[1]))
        {
            oRes.setArgError("Type error: argument " "1" " should be " "string" );
            return oRes.toRuby();
        }
    }

    nCallbackArg = 3;
    if ( argc == 2 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(4) );
        return oRes.toRuby();
    }
    rho::String arg2 = "";
    if ( argc > 2 )
    {
        if ( rho_ruby_is_string(argv[2]) )
        {
            arg2 = getStringObjectFromValue(argv[2]);
        }
        else if (!rho_ruby_is_NIL(argv[2]))
        {
            oRes.setArgError("Type error: argument " "2" " should be " "string" );
            return oRes.toRuby();
        }
    }

    nCallbackArg = 4;
    if ( argc == 3 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(4) );
        return oRes.toRuby();
    }
    rho::String arg3 = "";
    if ( argc > 3 )
    {
        if ( rho_ruby_is_string(argv[3]) )
        {
            arg3 = getStringObjectFromValue(argv[3]);
        }
        else if (!rho_ruby_is_NIL(argv[3]))
        {
            oRes.setArgError("Type error: argument " "3" " should be " "string" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(4) );
        return oRes.toRuby();
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor5( pObj, &rho::IPdfgen::mergeIOSPDF, arg0, arg1, arg2, arg3,  oRes );
        rho::CPdfgenFactoryBase::getPdfgenSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->mergeIOSPDF( arg0, arg1, arg2, arg3,  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_Pdfgen_mergeIOSPDF(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IPdfgen* pObj =  rho::CPdfgenFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_Pdfgen_mergeIOSPDF(argc, argv, pObj);

    return res;
}



VALUE rb_s_Pdfgen_def_mergeIOSPDF(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CPdfgenFactoryBase::getPdfgenSingletonS()->getDefaultID();
    rho::IPdfgen* pObj = rho::CPdfgenFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_Pdfgen_mergeIOSPDF(argc, argv, pObj);
}


static VALUE _api_generator_Pdfgen_getProperty(int argc, VALUE *argv, rho::IPdfgen* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    oRes.setRequestedType(CMethodResult::eString);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(1) );
        return oRes.toRuby();
    }
    rho::String arg0 = "";
    if ( argc > 0 )
    {
        if ( rho_ruby_is_string(argv[0]) )
        {
            arg0 = getStringObjectFromValue(argv[0]);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "string" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        if ( rho_ruby_is_proc(argv[nCallbackArg]) || rho_ruby_is_method(argv[nCallbackArg]) )
        {
            oRes.setRubyCallbackProc( argv[nCallbackArg] );
        }else if ( rho_ruby_is_string(argv[nCallbackArg]) )
        {
            oRes.setRubyCallback( getStringObjectFromValue(argv[nCallbackArg]) );
        }else
        {
            oRes.setArgError("Type error: callback should be String");
            return oRes.toRuby();
        }

        oRes.setCallInUIThread(false);
        if ( argc > nCallbackArg + 1 )
        {
            if ( !rho_ruby_is_NIL(argv[nCallbackArg + 1]) )
            {
                if ( !rho_ruby_is_string(argv[nCallbackArg + 1]) )
                {
                    oRes.setArgError("Type error: callback parameter should be String");
                    return oRes.toRuby();
                }

                oRes.setCallbackParam( getStringObjectFromValue(argv[nCallbackArg + 1]) );
            }
        }
        
        bUseCallback = true;
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor2( pObj, &rho::IPdfgen::getProperty, arg0,  oRes );
        rho::CPdfgenFactoryBase::getPdfgenSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->getProperty( arg0,  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_Pdfgen_getProperty(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IPdfgen* pObj =  rho::CPdfgenFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_Pdfgen_getProperty(argc, argv, pObj);

    return res;
}



VALUE rb_s_Pdfgen_def_getProperty(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CPdfgenFactoryBase::getPdfgenSingletonS()->getDefaultID();
    rho::IPdfgen* pObj = rho::CPdfgenFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_Pdfgen_getProperty(argc, argv, pObj);
}


static VALUE _api_generator_Pdfgen_getProperties(int argc, VALUE *argv, rho::IPdfgen* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    oRes.setRequestedType(CMethodResult::eStringHash);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(1) );
        return oRes.toRuby();
    }
    rho::Vector<rho::String> arg0;
    if ( argc > 0 )
    {
        if ( rho_ruby_is_array(argv[0]) )
        {
            rho::String res;
            rho_value_to_typed_array<rho::String>(argv[0], arg0, res);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "array" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        if ( rho_ruby_is_proc(argv[nCallbackArg]) || rho_ruby_is_method(argv[nCallbackArg]) )
        {
            oRes.setRubyCallbackProc( argv[nCallbackArg] );
        }else if ( rho_ruby_is_string(argv[nCallbackArg]) )
        {
            oRes.setRubyCallback( getStringObjectFromValue(argv[nCallbackArg]) );
        }else
        {
            oRes.setArgError("Type error: callback should be String");
            return oRes.toRuby();
        }

        oRes.setCallInUIThread(false);
        if ( argc > nCallbackArg + 1 )
        {
            if ( !rho_ruby_is_NIL(argv[nCallbackArg + 1]) )
            {
                if ( !rho_ruby_is_string(argv[nCallbackArg + 1]) )
                {
                    oRes.setArgError("Type error: callback parameter should be String");
                    return oRes.toRuby();
                }

                oRes.setCallbackParam( getStringObjectFromValue(argv[nCallbackArg + 1]) );
            }
        }
        
        bUseCallback = true;
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor2( pObj, &rho::IPdfgen::getProperties, arg0,  oRes );
        rho::CPdfgenFactoryBase::getPdfgenSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->getProperties( arg0,  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_Pdfgen_getProperties(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IPdfgen* pObj =  rho::CPdfgenFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_Pdfgen_getProperties(argc, argv, pObj);

    return res;
}



VALUE rb_s_Pdfgen_def_getProperties(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CPdfgenFactoryBase::getPdfgenSingletonS()->getDefaultID();
    rho::IPdfgen* pObj = rho::CPdfgenFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_Pdfgen_getProperties(argc, argv, pObj);
}


static VALUE _api_generator_Pdfgen_getAllProperties(int argc, VALUE *argv, rho::IPdfgen* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    oRes.setRequestedType(CMethodResult::eStringHash);
    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    if ( argc > nCallbackArg )
    {

        if ( rho_ruby_is_proc(argv[nCallbackArg]) || rho_ruby_is_method(argv[nCallbackArg]) )
        {
            oRes.setRubyCallbackProc( argv[nCallbackArg] );
        }else if ( rho_ruby_is_string(argv[nCallbackArg]) )
        {
            oRes.setRubyCallback( getStringObjectFromValue(argv[nCallbackArg]) );
        }else
        {
            oRes.setArgError("Type error: callback should be String");
            return oRes.toRuby();
        }

        oRes.setCallInUIThread(false);
        if ( argc > nCallbackArg + 1 )
        {
            if ( !rho_ruby_is_NIL(argv[nCallbackArg + 1]) )
            {
                if ( !rho_ruby_is_string(argv[nCallbackArg + 1]) )
                {
                    oRes.setArgError("Type error: callback parameter should be String");
                    return oRes.toRuby();
                }

                oRes.setCallbackParam( getStringObjectFromValue(argv[nCallbackArg + 1]) );
            }
        }
        
        bUseCallback = true;
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor1( pObj, &rho::IPdfgen::getAllProperties,  oRes );
        rho::CPdfgenFactoryBase::getPdfgenSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->getAllProperties(  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_Pdfgen_getAllProperties(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IPdfgen* pObj =  rho::CPdfgenFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_Pdfgen_getAllProperties(argc, argv, pObj);

    return res;
}



VALUE rb_s_Pdfgen_def_getAllProperties(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CPdfgenFactoryBase::getPdfgenSingletonS()->getDefaultID();
    rho::IPdfgen* pObj = rho::CPdfgenFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_Pdfgen_getAllProperties(argc, argv, pObj);
}


static VALUE _api_generator_Pdfgen_setProperty(int argc, VALUE *argv, rho::IPdfgen* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(2) );
        return oRes.toRuby();
    }
    rho::String arg0 = "";
    if ( argc > 0 )
    {
        if ( rho_ruby_is_string(argv[0]) )
        {
            arg0 = getStringObjectFromValue(argv[0]);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "string" );
            return oRes.toRuby();
        }
    }

    nCallbackArg = 2;
    if ( argc == 1 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(2) );
        return oRes.toRuby();
    }
    rho::String arg1 = "";
    if ( argc > 1 )
    {
        if ( rho_ruby_is_string(argv[1]) )
        {
            arg1 = getStringObjectFromValue(argv[1]);
        }
        else if (!rho_ruby_is_NIL(argv[1]))
        {
            oRes.setArgError("Type error: argument " "1" " should be " "string" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(2) );
        return oRes.toRuby();
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor3( pObj, &rho::IPdfgen::setProperty, arg0, arg1,  oRes );
        rho::CPdfgenFactoryBase::getPdfgenSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->setProperty( arg0, arg1,  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_Pdfgen_setProperty(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IPdfgen* pObj =  rho::CPdfgenFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_Pdfgen_setProperty(argc, argv, pObj);

    return res;
}



VALUE rb_s_Pdfgen_def_setProperty(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CPdfgenFactoryBase::getPdfgenSingletonS()->getDefaultID();
    rho::IPdfgen* pObj = rho::CPdfgenFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_Pdfgen_setProperty(argc, argv, pObj);
}


static VALUE _api_generator_Pdfgen_setProperties(int argc, VALUE *argv, rho::IPdfgen* pObj)
{
    rho::apiGenerator::CMethodResult oRes;

    if(!pObj)
    {
        oRes.setArgError("Invalid object!");
        return oRes.toRuby();
    }


    rho::common::CInstanceClassFunctorBase<rho::apiGenerator::CMethodResult>* pFunctor = 0;
    bool bUseCallback = false;
    int nCallbackArg = 0;
    nCallbackArg = 1;
    if ( argc == 0 )
    {
        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(1) );
        return oRes.toRuby();
    }
    rho::Hashtable<rho::String, rho::String> arg0;
    if ( argc > 0 )
    {
        if ( rho_ruby_is_hash(argv[0]) )
        {
            rho::String res;
            rho_value_to_typed_hash<rho::String, rho::String>(argv[0], arg0, res);
        }
        else if (!rho_ruby_is_NIL(argv[0]))
        {
            oRes.setArgError("Type error: argument " "0" " should be " "hash" );
            return oRes.toRuby();
        }
    }

    if ( argc > nCallbackArg )
    {

        oRes.setArgError("Wrong number of arguments: " + convertToStringA(argc) + " instead of " + convertToStringA(1) );
        return oRes.toRuby();
    }
    if ( bUseCallback )
    {
        pFunctor = rho_makeInstanceClassFunctor2( pObj, &rho::IPdfgen::setProperties, arg0,  oRes );
        rho::CPdfgenFactoryBase::getPdfgenSingletonS()->addCommandToQueue( pFunctor );
    }
    else 
    {

        pObj->setProperties( arg0,  oRes );
    }
    
    return oRes.toRuby();
}



VALUE rb_Pdfgen_setProperties(int argc, VALUE *argv, VALUE obj)
{
    const char* szID = rho_ruby_get_object_id( obj );
    if (!szID)
        rho_ruby_raise_runtime("Object was deleted.");

    VALUE res = 0;
    rho::IPdfgen* pObj =  rho::CPdfgenFactoryBase::getInstance()->getModuleByID(szID);

    res = _api_generator_Pdfgen_setProperties(argc, argv, pObj);

    return res;
}



VALUE rb_s_Pdfgen_def_setProperties(int argc, VALUE *argv)
{
    rho::String strDefaultID = rho::CPdfgenFactoryBase::getPdfgenSingletonS()->getDefaultID();
    rho::IPdfgen* pObj = rho::CPdfgenFactoryBase::getInstance()->getModuleByID(strDefaultID);

    return _api_generator_Pdfgen_setProperties(argc, argv, pObj);
}



}