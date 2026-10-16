#include "Bmp.h"

#include "MethodResultJni.h"

#include "ext/rho/rhoruby.h"
#include "rhodes/JNIRhoRuby.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "BmpRUBY"


typedef rho::CBmpProxy<ArgumentsAdapter<std::vector<VALUE> > > ObjectProxy;

using namespace rho::apiGenerator;
extern "C"
{

VALUE getRuby_Bmp_Module();


VALUE rb_Bmp_s_default(VALUE klass)
{
    RAWTRACE("rb_Bmp_s_default");
    return rho_ruby_create_object_with_id(klass, rho::CBmpBase::getDefaultID().c_str());
}

VALUE rb_Bmp_s_setDefault(VALUE klass, VALUE valObj)
{
    RAWTRACE("rb_Bmp_s_set_default");

    const char* szID = rho_ruby_get_object_id(valObj);
    rho::CBmpBase::setDefaultID(szID);

    return rho_ruby_get_NIL();
} 


static VALUE Bmp_getSimpleStringProperty(int argc, VALUE *argv, const rho::String& id)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, id.c_str());
    MethodResultJni result(true);
    if(!result)
    {
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        result.setError("JNI error: failed to initialize MethodResult java object");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    RAWTRACE("MethodResultJni instance is created");

    ObjectProxy bmp(id);

    if((argc < 0) || (argc > 0))
    {
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        result.setArgError("Wrong number of arguments");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    unsigned realParamCount = (argc < 0) ? argc : 0;
    std::vector<VALUE> arguments(argv, argv + realParamCount);
    
    RAWTRACE1("Count of passed arguments: %d", arguments.size());
    
    if(argc > 0)
    {
        if (rho_ruby_is_proc(argv[0]) || rho_ruby_is_method(argv[0]))
        {
            result.setRubyProcCallBack(argv[0]);
            RAWTRACE("Ruby proc callback is set");
        } else
        {
            if(argc > 1)
                result.setCallBack(argv[0], argv[1]);
            else
                result.setCallBack(argv[0]);
            
            RAWTRACE("Callback URL is set");
        }
        if(!result.hasCallback())
        {
            RAWLOG_ERROR("Error setting callback ^^^");
            return CMethodResultConvertor().toRuby(result, false);
        }
    }

    bmp.getSimpleStringProperty(argumentsAdapter(arguments), result); 
    RAWTRACE("Native metod has invoked, converting result");
    VALUE res = CMethodResultConvertor().toRuby(result, false);
    RAWTRACE(__FUNCTION__);
    return res;
}
VALUE rb_Bmp_getSimpleStringProperty(int argc, VALUE *argv, VALUE obj)
{
    rho::String id = rho_ruby_get_object_id(obj);
    return Bmp_getSimpleStringProperty(argc, argv, id);
}

VALUE rb_s_Bmp_def_getSimpleStringProperty(int argc, VALUE *argv)
{
    rho::String id = ObjectProxy::getDefaultID();
    return Bmp_getSimpleStringProperty(argc, argv, id);
}
static VALUE Bmp_setSimpleStringProperty(int argc, VALUE *argv, const rho::String& id)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, id.c_str());
    MethodResultJni result(true);
    if(!result)
    {
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        result.setError("JNI error: failed to initialize MethodResult java object");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    RAWTRACE("MethodResultJni instance is created");

    ObjectProxy bmp(id);

    if((argc < 1) || (argc > 1))
    {
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        result.setArgError("Wrong number of arguments");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    unsigned realParamCount = (argc < 1) ? argc : 1;
    std::vector<VALUE> arguments(argv, argv + realParamCount);
    
    RAWTRACE1("Count of passed arguments: %d", arguments.size());
    
    if(argc > 1)
    {
        if (rho_ruby_is_proc(argv[1]) || rho_ruby_is_method(argv[1]))
        {
            result.setRubyProcCallBack(argv[1]);
            RAWTRACE("Ruby proc callback is set");
        } else
        {
            if(argc > 2)
                result.setCallBack(argv[1], argv[2]);
            else
                result.setCallBack(argv[1]);
            
            RAWTRACE("Callback URL is set");
        }
        if(!result.hasCallback())
        {
            RAWLOG_ERROR("Error setting callback ^^^");
            return CMethodResultConvertor().toRuby(result, false);
        }
    }

    bmp.setSimpleStringProperty(argumentsAdapter(arguments), result); 
    RAWTRACE("Native metod has invoked, converting result");
    VALUE res = CMethodResultConvertor().toRuby(result, false);
    RAWTRACE(__FUNCTION__);
    return res;
}
VALUE rb_Bmp_setSimpleStringProperty(int argc, VALUE *argv, VALUE obj)
{
    rho::String id = rho_ruby_get_object_id(obj);
    return Bmp_setSimpleStringProperty(argc, argv, id);
}

VALUE rb_s_Bmp_def_setSimpleStringProperty(int argc, VALUE *argv)
{
    rho::String id = ObjectProxy::getDefaultID();
    return Bmp_setSimpleStringProperty(argc, argv, id);
}
VALUE rb_s_Bmp_enumerate(int argc, VALUE *argv)
{
    RAWTRACE2("%s - argc: %d", __FUNCTION__, argc);
    MethodResultJni result(true);
    if(!result)
    {
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        result.setError("JNI error: failed to initialize MethodResult java object");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    RAWTRACE("MethodResultJni instance is created");


    if((argc < 0) || (argc > 2))
    {
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        result.setArgError("Wrong number of arguments");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    unsigned realParamCount = (argc < 0) ? argc : 0;
    std::vector<VALUE> arguments(argv, argv + realParamCount);
    
    RAWTRACE1("Count of passed arguments: %d", arguments.size());
    
    if(argc > 0)
    {
        if (rho_ruby_is_proc(argv[0]) || rho_ruby_is_method(argv[0]))
        {
            result.setRubyProcCallBack(argv[0]);
            RAWTRACE("Ruby proc callback is set");
        } else
        {
            if(argc > 1)
                result.setCallBack(argv[0], argv[1]);
            else
                result.setCallBack(argv[0]);
            
            RAWTRACE("Callback URL is set");
        }
        if(!result.hasCallback())
        {
            RAWLOG_ERROR("Error setting callback ^^^");
            return CMethodResultConvertor().toRuby(result, false);
        }
    }

    result.setObjectClassPath("Rho::Bmp");
    RAWTRACE("Object class path is set");

    ObjectProxy::enumerate(argumentsAdapter(arguments), result); 
    RAWTRACE("Native metod has invoked, converting result");
    VALUE res = CMethodResultConvertor().toRuby(result, false);
    RAWTRACE(__FUNCTION__);
    return res;
}

static VALUE Bmp_sensorDataFetch(int argc, VALUE *argv, const rho::String& id)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, id.c_str());
    MethodResultJni result(true);
    if(!result)
    {
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        result.setError("JNI error: failed to initialize MethodResult java object");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    RAWTRACE("MethodResultJni instance is created");

    ObjectProxy bmp(id);

    if((argc < 0) || (argc > 0))
    {
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        result.setArgError("Wrong number of arguments");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    unsigned realParamCount = (argc < 0) ? argc : 0;
    std::vector<VALUE> arguments(argv, argv + realParamCount);
    
    RAWTRACE1("Count of passed arguments: %d", arguments.size());
    
    if(argc > 0)
    {
        if (rho_ruby_is_proc(argv[0]) || rho_ruby_is_method(argv[0]))
        {
            result.setRubyProcCallBack(argv[0]);
            RAWTRACE("Ruby proc callback is set");
        } else
        {
            if(argc > 1)
                result.setCallBack(argv[0], argv[1]);
            else
                result.setCallBack(argv[0]);
            
            RAWTRACE("Callback URL is set");
        }
        if(!result.hasCallback())
        {
            RAWLOG_ERROR("Error setting callback ^^^");
            return CMethodResultConvertor().toRuby(result, false);
        }
    }

    bmp.sensorDataFetch(argumentsAdapter(arguments), result); 
    RAWTRACE("Native metod has invoked, converting result");
    VALUE res = CMethodResultConvertor().toRuby(result, false);
    RAWTRACE(__FUNCTION__);
    return res;
}
VALUE rb_Bmp_sensorDataFetch(int argc, VALUE *argv, VALUE obj)
{
    rho::String id = rho_ruby_get_object_id(obj);
    return Bmp_sensorDataFetch(argc, argv, id);
}

VALUE rb_s_Bmp_def_sensorDataFetch(int argc, VALUE *argv)
{
    rho::String id = ObjectProxy::getDefaultID();
    return Bmp_sensorDataFetch(argc, argv, id);
}
static VALUE Bmp_getProperty(int argc, VALUE *argv, const rho::String& id)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, id.c_str());
    MethodResultJni result(true);
    if(!result)
    {
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        result.setError("JNI error: failed to initialize MethodResult java object");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    RAWTRACE("MethodResultJni instance is created");

    ObjectProxy bmp(id);

    if((argc < 1) || (argc > 3))
    {
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        result.setArgError("Wrong number of arguments");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    unsigned realParamCount = (argc < 1) ? argc : 1;
    std::vector<VALUE> arguments(argv, argv + realParamCount);
    
    RAWTRACE1("Count of passed arguments: %d", arguments.size());
    
    if(argc > 1)
    {
        if (rho_ruby_is_proc(argv[1]) || rho_ruby_is_method(argv[1]))
        {
            result.setRubyProcCallBack(argv[1]);
            RAWTRACE("Ruby proc callback is set");
        } else
        {
            if(argc > 2)
                result.setCallBack(argv[1], argv[2]);
            else
                result.setCallBack(argv[1]);
            
            RAWTRACE("Callback URL is set");
        }
        if(!result.hasCallback())
        {
            RAWLOG_ERROR("Error setting callback ^^^");
            return CMethodResultConvertor().toRuby(result, false);
        }
    }

    bmp.getProperty(argumentsAdapter(arguments), result); 
    RAWTRACE("Native metod has invoked, converting result");
    VALUE res = CMethodResultConvertor().toRuby(result, false);
    RAWTRACE(__FUNCTION__);
    return res;
}
VALUE rb_Bmp_getProperty(int argc, VALUE *argv, VALUE obj)
{
    rho::String id = rho_ruby_get_object_id(obj);
    return Bmp_getProperty(argc, argv, id);
}

VALUE rb_s_Bmp_def_getProperty(int argc, VALUE *argv)
{
    rho::String id = ObjectProxy::getDefaultID();
    return Bmp_getProperty(argc, argv, id);
}
static VALUE Bmp_getProperties(int argc, VALUE *argv, const rho::String& id)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, id.c_str());
    MethodResultJni result(true);
    if(!result)
    {
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        result.setError("JNI error: failed to initialize MethodResult java object");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    RAWTRACE("MethodResultJni instance is created");

    ObjectProxy bmp(id);

    if((argc < 1) || (argc > 3))
    {
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        result.setArgError("Wrong number of arguments");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    unsigned realParamCount = (argc < 1) ? argc : 1;
    std::vector<VALUE> arguments(argv, argv + realParamCount);
    
    RAWTRACE1("Count of passed arguments: %d", arguments.size());
    
    if(argc > 1)
    {
        if (rho_ruby_is_proc(argv[1]) || rho_ruby_is_method(argv[1]))
        {
            result.setRubyProcCallBack(argv[1]);
            RAWTRACE("Ruby proc callback is set");
        } else
        {
            if(argc > 2)
                result.setCallBack(argv[1], argv[2]);
            else
                result.setCallBack(argv[1]);
            
            RAWTRACE("Callback URL is set");
        }
        if(!result.hasCallback())
        {
            RAWLOG_ERROR("Error setting callback ^^^");
            return CMethodResultConvertor().toRuby(result, false);
        }
    }

    bmp.getProperties(argumentsAdapter(arguments), result); 
    RAWTRACE("Native metod has invoked, converting result");
    VALUE res = CMethodResultConvertor().toRuby(result, false);
    RAWTRACE(__FUNCTION__);
    return res;
}
VALUE rb_Bmp_getProperties(int argc, VALUE *argv, VALUE obj)
{
    rho::String id = rho_ruby_get_object_id(obj);
    return Bmp_getProperties(argc, argv, id);
}

VALUE rb_s_Bmp_def_getProperties(int argc, VALUE *argv)
{
    rho::String id = ObjectProxy::getDefaultID();
    return Bmp_getProperties(argc, argv, id);
}
static VALUE Bmp_getAllProperties(int argc, VALUE *argv, const rho::String& id)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, id.c_str());
    MethodResultJni result(true);
    if(!result)
    {
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        result.setError("JNI error: failed to initialize MethodResult java object");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    RAWTRACE("MethodResultJni instance is created");

    ObjectProxy bmp(id);

    if((argc < 0) || (argc > 2))
    {
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        result.setArgError("Wrong number of arguments");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    unsigned realParamCount = (argc < 0) ? argc : 0;
    std::vector<VALUE> arguments(argv, argv + realParamCount);
    
    RAWTRACE1("Count of passed arguments: %d", arguments.size());
    
    if(argc > 0)
    {
        if (rho_ruby_is_proc(argv[0]) || rho_ruby_is_method(argv[0]))
        {
            result.setRubyProcCallBack(argv[0]);
            RAWTRACE("Ruby proc callback is set");
        } else
        {
            if(argc > 1)
                result.setCallBack(argv[0], argv[1]);
            else
                result.setCallBack(argv[0]);
            
            RAWTRACE("Callback URL is set");
        }
        if(!result.hasCallback())
        {
            RAWLOG_ERROR("Error setting callback ^^^");
            return CMethodResultConvertor().toRuby(result, false);
        }
    }

    bmp.getAllProperties(argumentsAdapter(arguments), result); 
    RAWTRACE("Native metod has invoked, converting result");
    VALUE res = CMethodResultConvertor().toRuby(result, false);
    RAWTRACE(__FUNCTION__);
    return res;
}
VALUE rb_Bmp_getAllProperties(int argc, VALUE *argv, VALUE obj)
{
    rho::String id = rho_ruby_get_object_id(obj);
    return Bmp_getAllProperties(argc, argv, id);
}

VALUE rb_s_Bmp_def_getAllProperties(int argc, VALUE *argv)
{
    rho::String id = ObjectProxy::getDefaultID();
    return Bmp_getAllProperties(argc, argv, id);
}
static VALUE Bmp_setProperty(int argc, VALUE *argv, const rho::String& id)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, id.c_str());
    MethodResultJni result(true);
    if(!result)
    {
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        result.setError("JNI error: failed to initialize MethodResult java object");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    RAWTRACE("MethodResultJni instance is created");

    ObjectProxy bmp(id);

    if((argc < 2) || (argc > 2))
    {
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        result.setArgError("Wrong number of arguments");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    unsigned realParamCount = (argc < 2) ? argc : 2;
    std::vector<VALUE> arguments(argv, argv + realParamCount);
    
    RAWTRACE1("Count of passed arguments: %d", arguments.size());
    
    if(argc > 2)
    {
        if (rho_ruby_is_proc(argv[2]) || rho_ruby_is_method(argv[2]))
        {
            result.setRubyProcCallBack(argv[2]);
            RAWTRACE("Ruby proc callback is set");
        } else
        {
            if(argc > 3)
                result.setCallBack(argv[2], argv[3]);
            else
                result.setCallBack(argv[2]);
            
            RAWTRACE("Callback URL is set");
        }
        if(!result.hasCallback())
        {
            RAWLOG_ERROR("Error setting callback ^^^");
            return CMethodResultConvertor().toRuby(result, false);
        }
    }

    bmp.setProperty(argumentsAdapter(arguments), result); 
    RAWTRACE("Native metod has invoked, converting result");
    VALUE res = CMethodResultConvertor().toRuby(result, false);
    RAWTRACE(__FUNCTION__);
    return res;
}
VALUE rb_Bmp_setProperty(int argc, VALUE *argv, VALUE obj)
{
    rho::String id = rho_ruby_get_object_id(obj);
    return Bmp_setProperty(argc, argv, id);
}

VALUE rb_s_Bmp_def_setProperty(int argc, VALUE *argv)
{
    rho::String id = ObjectProxy::getDefaultID();
    return Bmp_setProperty(argc, argv, id);
}
static VALUE Bmp_setProperties(int argc, VALUE *argv, const rho::String& id)
{
    RAWTRACE2("%s(id=%s)", __FUNCTION__, id.c_str());
    MethodResultJni result(true);
    if(!result)
    {
        RAWLOG_ERROR("JNI error: failed to initialize MethodResult java object ^^^");
        result.setError("JNI error: failed to initialize MethodResult java object");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    RAWTRACE("MethodResultJni instance is created");

    ObjectProxy bmp(id);

    if((argc < 1) || (argc > 1))
    {
        RAWLOG_ERROR1("Wrong number of arguments: %d ^^^", argc);
        result.setArgError("Wrong number of arguments");
        return CMethodResultConvertor().toRuby(result, false);
    }
    
    unsigned realParamCount = (argc < 1) ? argc : 1;
    std::vector<VALUE> arguments(argv, argv + realParamCount);
    
    RAWTRACE1("Count of passed arguments: %d", arguments.size());
    
    if(argc > 1)
    {
        if (rho_ruby_is_proc(argv[1]) || rho_ruby_is_method(argv[1]))
        {
            result.setRubyProcCallBack(argv[1]);
            RAWTRACE("Ruby proc callback is set");
        } else
        {
            if(argc > 2)
                result.setCallBack(argv[1], argv[2]);
            else
                result.setCallBack(argv[1]);
            
            RAWTRACE("Callback URL is set");
        }
        if(!result.hasCallback())
        {
            RAWLOG_ERROR("Error setting callback ^^^");
            return CMethodResultConvertor().toRuby(result, false);
        }
    }

    bmp.setProperties(argumentsAdapter(arguments), result); 
    RAWTRACE("Native metod has invoked, converting result");
    VALUE res = CMethodResultConvertor().toRuby(result, false);
    RAWTRACE(__FUNCTION__);
    return res;
}
VALUE rb_Bmp_setProperties(int argc, VALUE *argv, VALUE obj)
{
    rho::String id = rho_ruby_get_object_id(obj);
    return Bmp_setProperties(argc, argv, id);
}

VALUE rb_s_Bmp_def_setProperties(int argc, VALUE *argv)
{
    rho::String id = ObjectProxy::getDefaultID();
    return Bmp_setProperties(argc, argv, id);
}
}
