#include "Bmp.h"


namespace rho {

IMPLEMENT_LOGCLASS(CBmpBase, "BmpJNI");

//BmpFactorySingleton staff
const char* const CBmpBase::FACTORY_SINGLETON_CLASS = "com.rho.bmp.BmpFactorySingleton";
jclass CBmpBase::s_clsFactorySingleton = 0;
jmethodID CBmpBase::s_midFactorySetInstance;
jmethodID CBmpBase::s_midFactoryGetInstance;

//BmpFactory staff
const char* const CBmpBase::IFACTORY_CLASS = "com.rho.bmp.IBmpFactory";
jclass CBmpBase::s_clsIFactory = 0;
jmethodID CBmpBase::s_midGetApiSingleton;
jmethodID CBmpBase::s_midGetApiObject;

//BmpSingletonBase staff
const char* const CBmpBase::SINGLETON_BASE_CLASS = "com.rho.bmp.BmpSingletonBase";
jclass CBmpBase::s_clsSingletonBase = 0;

//BmpBase staff
const char* const CBmpBase::OBJECT_BASE_CLASS = "com.rho.bmp.BmpBase";
jclass CBmpBase::s_clsObjectBase = 0;


//IRhoApiDefaultId staff
const char* const CBmpBase::IDEFAULTID_CLASS = "com.rhomobile.rhodes.api.IRhoApiDefaultId";
jclass CBmpBase::s_clsIDefaultId = 0;
jmethodID CBmpBase::s_midGetDefaultID;
jmethodID CBmpBase::s_midSetDefaultID;


//Method tasks

const char* const CBmpBase::GETSIMPLESTRINGPROPERTY_TASK_CLASS = 
        "com.rho.bmp.BmpBase$getSimpleStringPropertyTask";

jclass CBmpBase::s_clsgetSimpleStringPropertyTask = 0;
jmethodID CBmpBase::s_midgetSimpleStringPropertyTask;

const char* const CBmpBase::SETSIMPLESTRINGPROPERTY_TASK_CLASS = 
        "com.rho.bmp.BmpBase$setSimpleStringPropertyTask";

jclass CBmpBase::s_clssetSimpleStringPropertyTask = 0;
jmethodID CBmpBase::s_midsetSimpleStringPropertyTask;

const char* const CBmpBase::ENUMERATE_TASK_CLASS = 
        "com.rho.bmp.BmpSingletonBase$enumerateTask";

jclass CBmpBase::s_clsenumerateTask = 0;
jmethodID CBmpBase::s_midenumerateTask;

const char* const CBmpBase::SENSORDATAFETCH_TASK_CLASS = 
        "com.rho.bmp.BmpBase$sensorDataFetchTask";

jclass CBmpBase::s_clssensorDataFetchTask = 0;
jmethodID CBmpBase::s_midsensorDataFetchTask;

const char* const CBmpBase::GETPROPERTY_TASK_CLASS = 
        "com.rho.bmp.BmpBase$getPropertyTask";

jclass CBmpBase::s_clsgetPropertyTask = 0;
jmethodID CBmpBase::s_midgetPropertyTask;

const char* const CBmpBase::GETPROPERTIES_TASK_CLASS = 
        "com.rho.bmp.BmpBase$getPropertiesTask";

jclass CBmpBase::s_clsgetPropertiesTask = 0;
jmethodID CBmpBase::s_midgetPropertiesTask;

const char* const CBmpBase::GETALLPROPERTIES_TASK_CLASS = 
        "com.rho.bmp.BmpBase$getAllPropertiesTask";

jclass CBmpBase::s_clsgetAllPropertiesTask = 0;
jmethodID CBmpBase::s_midgetAllPropertiesTask;

const char* const CBmpBase::SETPROPERTY_TASK_CLASS = 
        "com.rho.bmp.BmpBase$setPropertyTask";

jclass CBmpBase::s_clssetPropertyTask = 0;
jmethodID CBmpBase::s_midsetPropertyTask;

const char* const CBmpBase::SETPROPERTIES_TASK_CLASS = 
        "com.rho.bmp.BmpBase$setPropertiesTask";

jclass CBmpBase::s_clssetPropertiesTask = 0;
jmethodID CBmpBase::s_midsetPropertiesTask;


//----------------------------------------------------------------------------------------------------------------------

JNIEnv* CBmpBase::jniInit()
{
    JNIEnv *env = jnienv();
    if(!env)
    {
        LOG(FATAL) + "JNI init failed: JNIEnv is null";
        return 0;
    }
    return jniInit(env);
}
//----------------------------------------------------------------------------------------------------------------------

JNIEnv* CBmpBase::jniInit(JNIEnv* env)
{
    static bool initialized = false;
    env = MethodExecutorJni::jniInit(env);
    if (!env) {
        LOG(FATAL) + "JNI init failed";
        return 0;
    }

    if(!initialized)
    {
        //init BmpFactorySingleton JNI
        s_clsFactorySingleton = loadClass(env, FACTORY_SINGLETON_CLASS);
        if (!s_clsFactorySingleton) return 0;

        s_midFactorySetInstance = env->GetStaticMethodID(s_clsFactorySingleton, "setInstance", "(Lcom/rho/bmp/IBmpFactory;)V");
        if(!s_midFactorySetInstance)
        {
            LOG(FATAL) + "Failed to get method 'setInstance' for java class " + FACTORY_SINGLETON_CLASS;
            return NULL;
        }
        s_midFactoryGetInstance = env->GetStaticMethodID(s_clsFactorySingleton, "getInstance", "()Lcom/rho/bmp/IBmpFactory;");
        if(!s_midFactoryGetInstance)
        {
            LOG(FATAL) + "Failed to get method 'getInstance' for java class " + FACTORY_SINGLETON_CLASS;
            return NULL;
        }

        //init IBmpFactory JNI
        s_clsIFactory = loadClass(env, IFACTORY_CLASS);
        if (!s_clsIFactory) return 0;
        s_midGetApiSingleton = env->GetMethodID(s_clsIFactory, "getApiSingleton", "()Lcom/rho/bmp/IBmpSingleton;");
        if(!s_midGetApiSingleton)
        {
            LOG(FATAL) + "Failed to get method 'getApiSingleton' for java class " + IFACTORY_CLASS;
            return NULL;
        }
        s_midGetApiObject = env->GetMethodID(s_clsIFactory, "getApiObject", "(Ljava/lang/String;)Lcom/rho/bmp/IBmp;");
        if(!s_midGetApiObject)
        {
            LOG(FATAL) + "Failed to get method 'getApiObject' for java class " + IFACTORY_CLASS;
            return NULL;
        }

        s_clsSingletonBase = loadClass(env, SINGLETON_BASE_CLASS);
        if (!s_clsSingletonBase) return 0;
        s_clsObjectBase = loadClass(env, OBJECT_BASE_CLASS);
        if (!s_clsObjectBase) return 0;



        s_clsgetSimpleStringPropertyTask = loadClass(env, GETSIMPLESTRINGPROPERTY_TASK_CLASS);
        if (!s_clsgetSimpleStringPropertyTask) return 0;
        s_midgetSimpleStringPropertyTask = env->GetMethodID(s_clsgetSimpleStringPropertyTask, "<init>",
                        "(Lcom/rho/bmp/IBmp;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetSimpleStringPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETSIMPLESTRINGPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clssetSimpleStringPropertyTask = loadClass(env, SETSIMPLESTRINGPROPERTY_TASK_CLASS);
        if (!s_clssetSimpleStringPropertyTask) return 0;
        s_midsetSimpleStringPropertyTask = env->GetMethodID(s_clssetSimpleStringPropertyTask, "<init>",
                        "(Lcom/rho/bmp/IBmp;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetSimpleStringPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETSIMPLESTRINGPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clsenumerateTask = loadClass(env, ENUMERATE_TASK_CLASS);
        if (!s_clsenumerateTask) return 0;
        s_midenumerateTask = env->GetMethodID(s_clsenumerateTask, "<init>",
                        "(Lcom/rho/bmp/IBmpSingleton;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midenumerateTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + ENUMERATE_TASK_CLASS;
            return NULL;
        }

        s_clssensorDataFetchTask = loadClass(env, SENSORDATAFETCH_TASK_CLASS);
        if (!s_clssensorDataFetchTask) return 0;
        s_midsensorDataFetchTask = env->GetMethodID(s_clssensorDataFetchTask, "<init>",
                        "(Lcom/rho/bmp/IBmp;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsensorDataFetchTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SENSORDATAFETCH_TASK_CLASS;
            return NULL;
        }

        s_clsgetPropertyTask = loadClass(env, GETPROPERTY_TASK_CLASS);
        if (!s_clsgetPropertyTask) return 0;
        s_midgetPropertyTask = env->GetMethodID(s_clsgetPropertyTask, "<init>",
                        "(Lcom/rho/bmp/IBmp;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clsgetPropertiesTask = loadClass(env, GETPROPERTIES_TASK_CLASS);
        if (!s_clsgetPropertiesTask) return 0;
        s_midgetPropertiesTask = env->GetMethodID(s_clsgetPropertiesTask, "<init>",
                        "(Lcom/rho/bmp/IBmp;Ljava/util/List;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPROPERTIES_TASK_CLASS;
            return NULL;
        }

        s_clsgetAllPropertiesTask = loadClass(env, GETALLPROPERTIES_TASK_CLASS);
        if (!s_clsgetAllPropertiesTask) return 0;
        s_midgetAllPropertiesTask = env->GetMethodID(s_clsgetAllPropertiesTask, "<init>",
                        "(Lcom/rho/bmp/IBmp;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetAllPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETALLPROPERTIES_TASK_CLASS;
            return NULL;
        }

        s_clssetPropertyTask = loadClass(env, SETPROPERTY_TASK_CLASS);
        if (!s_clssetPropertyTask) return 0;
        s_midsetPropertyTask = env->GetMethodID(s_clssetPropertyTask, "<init>",
                        "(Lcom/rho/bmp/IBmp;Ljava/lang/String;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clssetPropertiesTask = loadClass(env, SETPROPERTIES_TASK_CLASS);
        if (!s_clssetPropertiesTask) return 0;
        s_midsetPropertiesTask = env->GetMethodID(s_clssetPropertiesTask, "<init>",
                        "(Lcom/rho/bmp/IBmp;Ljava/util/Map;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETPROPERTIES_TASK_CLASS;
            return NULL;
        }


        s_clsIDefaultId = loadClass(env, IDEFAULTID_CLASS);
        if (!s_clsIDefaultId) return 0;
        s_midGetDefaultID = env->GetMethodID(s_clsIDefaultId, "getDefaultID", "()Ljava/lang/String;");
        if(!s_midGetDefaultID)
        {
            LOG(FATAL) + "Failed to get method 'getDefaultID' for java class " + IDEFAULTID_CLASS;
            return NULL;
        }
        s_midSetDefaultID = env->GetMethodID(s_clsIDefaultId, "setDefaultID", "(Ljava/lang/String;)V");
        if(!s_midSetDefaultID)
        {
            LOG(FATAL) + "Failed to get method 'setDefaultID' for java class " + IDEFAULTID_CLASS;
            return NULL;
        }


        initialized = true;
        LOG(TRACE) + "CBmp JNI init succeeded";
    }
    return env;
}
//----------------------------------------------------------------------------------------------------------------------

void CBmpBase::setJavaFactory(JNIEnv* env, jobject jFactory)
{
    LOG(TRACE) + "setJavaFactory";

    env = jniInit(env);
    if (!env) {
        LOG(FATAL) + "JNI initialization failed";
        return;
    }

    env->CallStaticVoidMethod(s_clsFactorySingleton, s_midFactorySetInstance, jFactory);

    LOG(TRACE) + "setJavaFactory succeeded";
}
//----------------------------------------------------------------------------------------------------------------------

rho::String CBmpBase::getDefaultID()
{
    LOG(TRACE) + "getDefaultID";

    JNIEnv *env = jniInit();
    if (!env) {
        LOG(FATAL) + "JNI initialization failed";
        return rho::String();
    }

    jhobject jhSingleton = getSingleton(env);
    jhstring res = static_cast<jstring>(env->CallObjectMethod(jhSingleton.get(), s_midGetDefaultID));
    return rho_cast<rho::String>(env, res);
}
//----------------------------------------------------------------------------------------------------------------------

void CBmpBase::setDefaultID(const rho::String& id)
{
    LOG(TRACE) + "setDefaultID: " + id;

    JNIEnv *env = jniInit();
    if (!env) {
        LOG(FATAL) + "JNI initialization failed";
        return;
    }

    jhobject instance = getSingleton(env);
    jhstring jhId = rho_cast<jstring>(env, id);
    env->CallVoidMethod(instance.get(), s_midSetDefaultID, jhId.get());
}
//----------------------------------------------------------------------------------------------------------------------

jobject CBmpBase::getFactory(JNIEnv* env)
{
    jobject res = env->CallStaticObjectMethod(s_clsFactorySingleton, s_midFactoryGetInstance);
    return res;
}
//----------------------------------------------------------------------------------------------------------------------

jobject CBmpBase::getSingleton(JNIEnv* env)
{
    jhobject jhFactory = getFactory(env);
    jobject res = env->CallObjectMethod(jhFactory.get(), s_midGetApiSingleton);
    return res;
}
//----------------------------------------------------------------------------------------------------------------------

jobject CBmpBase::getObject(JNIEnv* env)
{
    jhstring jhId = rho_cast<jstring>(env, m_id);
    jhobject jhFactory = getFactory(env);
    jobject res = env->CallObjectMethod(jhFactory.get(), s_midGetApiObject, jhId.get());
    return res;
}
//----------------------------------------------------------------------------------------------------------------------


}
