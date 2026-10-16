#include "HtmlToGraph.h"

#include "MethodResultJni.h"

#include "api_generator/MethodResult.h"
#include "api_generator/MethodResultConvertor.h"
#include "api_generator/JSONResultConvertor.h"

#include "rhodes/JNIRhoJS.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "HtmlToGraphJS"

typedef rho::CHtmlToGraphProxy<ArgumentsAdapter<rho::json::CJSONArray> > ObjectProxy;

using namespace rho::apiGenerator;

rho::String js_s_HtmlToGraph_getDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE(__FUNCTION__);
    
    rho::apiGenerator::CMethodResult result(false);
    result.set(ObjectProxy::getDefaultID());
    return CMethodResultConvertor().toJSON(result);
}

rho::String js_s_HtmlToGraph_getDefault(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE(__FUNCTION__);
    
    rho::apiGenerator::CMethodResult result(false);
    result.setJSObjectClassPath("Rho.HtmlToGraph");
    result.set(ObjectProxy::getDefaultID());
    return CMethodResultConvertor().toJSON(result);
}

rho::String js_s_HtmlToGraph_setDefaultID(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE(__FUNCTION__);

    rho::apiGenerator::CMethodResult result(false);
    ObjectProxy::setDefaultID(argv.getItem(0).getString());
    return CMethodResultConvertor().toJSON(result);
} 


rho::String js_HtmlToGraph_getSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, strObjID.c_str());

    MethodResultJni result(false);
    if(!result)
    {
        result.setError("JNI error: failed to initialize MethodResult java object");
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        return CMethodResultConvertor().toJSON(result);
    }

    ObjectProxy htmltograph(strObjID);

    int argc = argv.getSize();
    if((argc < 0) || (argc > 0))
    {
        result.setArgError("Wrong number of arguments");
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        return CMethodResultConvertor().toJSON(result);
    }
    
    if(strCallbackID.length() != 0)
    {
        result.setCallBack(strCallbackID, strCallbackParam);
    }

    htmltograph.getSimpleStringProperty(argumentsAdapter(argv), result); 
    rho::String res = CMethodResultConvertor().toJSON(result);
    RAWTRACE(res.c_str());
    RAWTRACE2("%s(id=%s) end ^^^", __FUNCTION__, strObjID.c_str());
    return res;
}
rho::String js_HtmlToGraph_setSimpleStringProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, strObjID.c_str());

    MethodResultJni result(false);
    if(!result)
    {
        result.setError("JNI error: failed to initialize MethodResult java object");
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        return CMethodResultConvertor().toJSON(result);
    }

    ObjectProxy htmltograph(strObjID);

    int argc = argv.getSize();
    if((argc < 1) || (argc > 1))
    {
        result.setArgError("Wrong number of arguments");
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        return CMethodResultConvertor().toJSON(result);
    }
    
    if(strCallbackID.length() != 0)
    {
        result.setCallBack(strCallbackID, strCallbackParam);
    }

    htmltograph.setSimpleStringProperty(argumentsAdapter(argv), result); 
    rho::String res = CMethodResultConvertor().toJSON(result);
    RAWTRACE(res.c_str());
    RAWTRACE2("%s(id=%s) end ^^^", __FUNCTION__, strObjID.c_str());
    return res;
}
rho::String js_s_HtmlToGraph_enumerate(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, strObjID.c_str());

    MethodResultJni result(false);
    if(!result)
    {
        result.setError("JNI error: failed to initialize MethodResult java object");
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        return CMethodResultConvertor().toJSON(result);
    }


    int argc = argv.getSize();
    if((argc < 0) || (argc > 0))
    {
        result.setArgError("Wrong number of arguments");
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        return CMethodResultConvertor().toJSON(result);
    }
    
    if(strCallbackID.length() != 0)
    {
        result.setCallBack(strCallbackID, strCallbackParam);
    }

    result.setObjectClassPath("Rho.HtmlToGraph");
    RAWTRACE("Object class path is set");
    ObjectProxy::enumerate(argumentsAdapter(argv), result); 
    rho::String res = CMethodResultConvertor().toJSON(result);
    RAWTRACE(res.c_str());
    RAWTRACE2("%s(id=%s) end ^^^", __FUNCTION__, strObjID.c_str());
    return res;
}
rho::String js_HtmlToGraph_getPlatformName(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, strObjID.c_str());

    MethodResultJni result(false);
    if(!result)
    {
        result.setError("JNI error: failed to initialize MethodResult java object");
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        return CMethodResultConvertor().toJSON(result);
    }

    ObjectProxy htmltograph(strObjID);

    int argc = argv.getSize();
    if((argc < 0) || (argc > 0))
    {
        result.setArgError("Wrong number of arguments");
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        return CMethodResultConvertor().toJSON(result);
    }
    
    if(strCallbackID.length() != 0)
    {
        result.setCallBack(strCallbackID, strCallbackParam);
    }

    htmltograph.getPlatformName(argumentsAdapter(argv), result); 
    rho::String res = CMethodResultConvertor().toJSON(result);
    RAWTRACE(res.c_str());
    RAWTRACE2("%s(id=%s) end ^^^", __FUNCTION__, strObjID.c_str());
    return res;
}
rho::String js_HtmlToGraph_getGraphIOS(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, strObjID.c_str());

    MethodResultJni result(false);
    if(!result)
    {
        result.setError("JNI error: failed to initialize MethodResult java object");
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        return CMethodResultConvertor().toJSON(result);
    }

    ObjectProxy htmltograph(strObjID);

    int argc = argv.getSize();
    if((argc < 1) || (argc > 1))
    {
        result.setArgError("Wrong number of arguments");
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        return CMethodResultConvertor().toJSON(result);
    }
    
    if(strCallbackID.length() != 0)
    {
        result.setCallBack(strCallbackID, strCallbackParam);
    }

    htmltograph.getGraphIOS(argumentsAdapter(argv), result); 
    rho::String res = CMethodResultConvertor().toJSON(result);
    RAWTRACE(res.c_str());
    RAWTRACE2("%s(id=%s) end ^^^", __FUNCTION__, strObjID.c_str());
    return res;
}
rho::String js_HtmlToGraph_getGraphAndroid(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, strObjID.c_str());

    MethodResultJni result(false);
    if(!result)
    {
        result.setError("JNI error: failed to initialize MethodResult java object");
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        return CMethodResultConvertor().toJSON(result);
    }

    ObjectProxy htmltograph(strObjID);

    int argc = argv.getSize();
    if((argc < 1) || (argc > 1))
    {
        result.setArgError("Wrong number of arguments");
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        return CMethodResultConvertor().toJSON(result);
    }
    
    if(strCallbackID.length() != 0)
    {
        result.setCallBack(strCallbackID, strCallbackParam);
    }

    htmltograph.getGraphAndroid(argumentsAdapter(argv), result); 
    rho::String res = CMethodResultConvertor().toJSON(result);
    RAWTRACE(res.c_str());
    RAWTRACE2("%s(id=%s) end ^^^", __FUNCTION__, strObjID.c_str());
    return res;
}
rho::String js_HtmlToGraph_calcSumm(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, strObjID.c_str());

    MethodResultJni result(false);
    if(!result)
    {
        result.setError("JNI error: failed to initialize MethodResult java object");
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        return CMethodResultConvertor().toJSON(result);
    }

    ObjectProxy htmltograph(strObjID);

    int argc = argv.getSize();
    if((argc < 2) || (argc > 2))
    {
        result.setArgError("Wrong number of arguments");
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        return CMethodResultConvertor().toJSON(result);
    }
    
    if(strCallbackID.length() != 0)
    {
        result.setCallBack(strCallbackID, strCallbackParam);
    }

    htmltograph.calcSumm(argumentsAdapter(argv), result); 
    rho::String res = CMethodResultConvertor().toJSON(result);
    RAWTRACE(res.c_str());
    RAWTRACE2("%s(id=%s) end ^^^", __FUNCTION__, strObjID.c_str());
    return res;
}
rho::String js_HtmlToGraph_joinStrings(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, strObjID.c_str());

    MethodResultJni result(false);
    if(!result)
    {
        result.setError("JNI error: failed to initialize MethodResult java object");
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        return CMethodResultConvertor().toJSON(result);
    }

    ObjectProxy htmltograph(strObjID);

    int argc = argv.getSize();
    if((argc < 2) || (argc > 2))
    {
        result.setArgError("Wrong number of arguments");
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        return CMethodResultConvertor().toJSON(result);
    }
    
    if(strCallbackID.length() != 0)
    {
        result.setCallBack(strCallbackID, strCallbackParam);
    }

    htmltograph.joinStrings(argumentsAdapter(argv), result); 
    rho::String res = CMethodResultConvertor().toJSON(result);
    RAWTRACE(res.c_str());
    RAWTRACE2("%s(id=%s) end ^^^", __FUNCTION__, strObjID.c_str());
    return res;
}
rho::String js_HtmlToGraph_getProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, strObjID.c_str());

    MethodResultJni result(false);
    if(!result)
    {
        result.setError("JNI error: failed to initialize MethodResult java object");
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        return CMethodResultConvertor().toJSON(result);
    }

    ObjectProxy htmltograph(strObjID);

    int argc = argv.getSize();
    if((argc < 1) || (argc > 1))
    {
        result.setArgError("Wrong number of arguments");
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        return CMethodResultConvertor().toJSON(result);
    }
    
    if(strCallbackID.length() != 0)
    {
        result.setCallBack(strCallbackID, strCallbackParam);
    }

    htmltograph.getProperty(argumentsAdapter(argv), result); 
    rho::String res = CMethodResultConvertor().toJSON(result);
    RAWTRACE(res.c_str());
    RAWTRACE2("%s(id=%s) end ^^^", __FUNCTION__, strObjID.c_str());
    return res;
}
rho::String js_HtmlToGraph_getProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, strObjID.c_str());

    MethodResultJni result(false);
    if(!result)
    {
        result.setError("JNI error: failed to initialize MethodResult java object");
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        return CMethodResultConvertor().toJSON(result);
    }

    ObjectProxy htmltograph(strObjID);

    int argc = argv.getSize();
    if((argc < 1) || (argc > 1))
    {
        result.setArgError("Wrong number of arguments");
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        return CMethodResultConvertor().toJSON(result);
    }
    
    if(strCallbackID.length() != 0)
    {
        result.setCallBack(strCallbackID, strCallbackParam);
    }

    htmltograph.getProperties(argumentsAdapter(argv), result); 
    rho::String res = CMethodResultConvertor().toJSON(result);
    RAWTRACE(res.c_str());
    RAWTRACE2("%s(id=%s) end ^^^", __FUNCTION__, strObjID.c_str());
    return res;
}
rho::String js_HtmlToGraph_getAllProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, strObjID.c_str());

    MethodResultJni result(false);
    if(!result)
    {
        result.setError("JNI error: failed to initialize MethodResult java object");
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        return CMethodResultConvertor().toJSON(result);
    }

    ObjectProxy htmltograph(strObjID);

    int argc = argv.getSize();
    if((argc < 0) || (argc > 0))
    {
        result.setArgError("Wrong number of arguments");
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        return CMethodResultConvertor().toJSON(result);
    }
    
    if(strCallbackID.length() != 0)
    {
        result.setCallBack(strCallbackID, strCallbackParam);
    }

    htmltograph.getAllProperties(argumentsAdapter(argv), result); 
    rho::String res = CMethodResultConvertor().toJSON(result);
    RAWTRACE(res.c_str());
    RAWTRACE2("%s(id=%s) end ^^^", __FUNCTION__, strObjID.c_str());
    return res;
}
rho::String js_HtmlToGraph_setProperty(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, strObjID.c_str());

    MethodResultJni result(false);
    if(!result)
    {
        result.setError("JNI error: failed to initialize MethodResult java object");
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        return CMethodResultConvertor().toJSON(result);
    }

    ObjectProxy htmltograph(strObjID);

    int argc = argv.getSize();
    if((argc < 2) || (argc > 2))
    {
        result.setArgError("Wrong number of arguments");
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        return CMethodResultConvertor().toJSON(result);
    }
    
    if(strCallbackID.length() != 0)
    {
        result.setCallBack(strCallbackID, strCallbackParam);
    }

    htmltograph.setProperty(argumentsAdapter(argv), result); 
    rho::String res = CMethodResultConvertor().toJSON(result);
    RAWTRACE(res.c_str());
    RAWTRACE2("%s(id=%s) end ^^^", __FUNCTION__, strObjID.c_str());
    return res;
}
rho::String js_HtmlToGraph_setProperties(const rho::String& strObjID, rho::json::CJSONArray& argv, const rho::String& strCallbackID, const rho::String& strJsVmID, const rho::String& strCallbackParam)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, strObjID.c_str());

    MethodResultJni result(false);
    if(!result)
    {
        result.setError("JNI error: failed to initialize MethodResult java object");
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        return CMethodResultConvertor().toJSON(result);
    }

    ObjectProxy htmltograph(strObjID);

    int argc = argv.getSize();
    if((argc < 1) || (argc > 1))
    {
        result.setArgError("Wrong number of arguments");
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        return CMethodResultConvertor().toJSON(result);
    }
    
    if(strCallbackID.length() != 0)
    {
        result.setCallBack(strCallbackID, strCallbackParam);
    }

    htmltograph.setProperties(argumentsAdapter(argv), result); 
    rho::String res = CMethodResultConvertor().toJSON(result);
    RAWTRACE(res.c_str());
    RAWTRACE2("%s(id=%s) end ^^^", __FUNCTION__, strObjID.c_str());
    return res;
}
