#include "BGService.h"


namespace rho {

IMPLEMENT_LOGCLASS(CBGServiceBase, "BGServiceJNI");

//BGServiceFactorySingleton staff
const char* const CBGServiceBase::FACTORY_SINGLETON_CLASS = "com.rho.bgservice.BGServiceFactorySingleton";
jclass CBGServiceBase::s_clsFactorySingleton = 0;
jmethodID CBGServiceBase::s_midFactorySetInstance;
jmethodID CBGServiceBase::s_midFactoryGetInstance;

//BGServiceFactory staff
const char* const CBGServiceBase::IFACTORY_CLASS = "com.rho.bgservice.IBGServiceFactory";
jclass CBGServiceBase::s_clsIFactory = 0;
jmethodID CBGServiceBase::s_midGetApiSingleton;
jmethodID CBGServiceBase::s_midGetApiObject;

//BGServiceSingletonBase staff
const char* const CBGServiceBase::SINGLETON_BASE_CLASS = "com.rho.bgservice.BGServiceSingletonBase";
jclass CBGServiceBase::s_clsSingletonBase = 0;

//BGServiceBase staff
const char* const CBGServiceBase::OBJECT_BASE_CLASS = "com.rho.bgservice.BGServiceBase";
jclass CBGServiceBase::s_clsObjectBase = 0;


//IRhoApiDefaultId staff
const char* const CBGServiceBase::IDEFAULTID_CLASS = "com.rhomobile.rhodes.api.IRhoApiDefaultId";
jclass CBGServiceBase::s_clsIDefaultId = 0;
jmethodID CBGServiceBase::s_midGetDefaultID;
jmethodID CBGServiceBase::s_midSetDefaultID;


//Method tasks

const char* const CBGServiceBase::GETSIMPLESTRINGPROPERTY_TASK_CLASS = 
        "com.rho.bgservice.BGServiceBase$getSimpleStringPropertyTask";

jclass CBGServiceBase::s_clsgetSimpleStringPropertyTask = 0;
jmethodID CBGServiceBase::s_midgetSimpleStringPropertyTask;

const char* const CBGServiceBase::SETSIMPLESTRINGPROPERTY_TASK_CLASS = 
        "com.rho.bgservice.BGServiceBase$setSimpleStringPropertyTask";

jclass CBGServiceBase::s_clssetSimpleStringPropertyTask = 0;
jmethodID CBGServiceBase::s_midsetSimpleStringPropertyTask;

const char* const CBGServiceBase::ENUMERATE_TASK_CLASS = 
        "com.rho.bgservice.BGServiceSingletonBase$enumerateTask";

jclass CBGServiceBase::s_clsenumerateTask = 0;
jmethodID CBGServiceBase::s_midenumerateTask;

const char* const CBGServiceBase::STARTBACKGROUNDSERVICE_TASK_CLASS = 
        "com.rho.bgservice.BGServiceBase$startBackgroundServiceTask";

jclass CBGServiceBase::s_clsstartBackgroundServiceTask = 0;
jmethodID CBGServiceBase::s_midstartBackgroundServiceTask;

const char* const CBGServiceBase::STOPBACKGROUNDSERVICE_TASK_CLASS = 
        "com.rho.bgservice.BGServiceBase$stopBackgroundServiceTask";

jclass CBGServiceBase::s_clsstopBackgroundServiceTask = 0;
jmethodID CBGServiceBase::s_midstopBackgroundServiceTask;

const char* const CBGServiceBase::CHECKBACKGROUNDSERVICESTATUS_TASK_CLASS = 
        "com.rho.bgservice.BGServiceBase$checkBackgroundServiceStatusTask";

jclass CBGServiceBase::s_clscheckBackgroundServiceStatusTask = 0;
jmethodID CBGServiceBase::s_midcheckBackgroundServiceStatusTask;

const char* const CBGServiceBase::GETPROPERTY_TASK_CLASS = 
        "com.rho.bgservice.BGServiceBase$getPropertyTask";

jclass CBGServiceBase::s_clsgetPropertyTask = 0;
jmethodID CBGServiceBase::s_midgetPropertyTask;

const char* const CBGServiceBase::GETPROPERTIES_TASK_CLASS = 
        "com.rho.bgservice.BGServiceBase$getPropertiesTask";

jclass CBGServiceBase::s_clsgetPropertiesTask = 0;
jmethodID CBGServiceBase::s_midgetPropertiesTask;

const char* const CBGServiceBase::GETALLPROPERTIES_TASK_CLASS = 
        "com.rho.bgservice.BGServiceBase$getAllPropertiesTask";

jclass CBGServiceBase::s_clsgetAllPropertiesTask = 0;
jmethodID CBGServiceBase::s_midgetAllPropertiesTask;

const char* const CBGServiceBase::SETPROPERTY_TASK_CLASS = 
        "com.rho.bgservice.BGServiceBase$setPropertyTask";

jclass CBGServiceBase::s_clssetPropertyTask = 0;
jmethodID CBGServiceBase::s_midsetPropertyTask;

const char* const CBGServiceBase::SETPROPERTIES_TASK_CLASS = 
        "com.rho.bgservice.BGServiceBase$setPropertiesTask";

jclass CBGServiceBase::s_clssetPropertiesTask = 0;
jmethodID CBGServiceBase::s_midsetPropertiesTask;


//----------------------------------------------------------------------------------------------------------------------

JNIEnv* CBGServiceBase::jniInit()
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

JNIEnv* CBGServiceBase::jniInit(JNIEnv* env)
{
    static bool initialized = false;
    env = MethodExecutorJni::jniInit(env);
    if (!env) {
        LOG(FATAL) + "JNI init failed";
        return 0;
    }

    if(!initialized)
    {
        //init BGServiceFactorySingleton JNI
        s_clsFactorySingleton = loadClass(env, FACTORY_SINGLETON_CLASS);
        if (!s_clsFactorySingleton) return 0;

        s_midFactorySetInstance = env->GetStaticMethodID(s_clsFactorySingleton, "setInstance", "(Lcom/rho/bgservice/IBGServiceFactory;)V");
        if(!s_midFactorySetInstance)
        {
            LOG(FATAL) + "Failed to get method 'setInstance' for java class " + FACTORY_SINGLETON_CLASS;
            return NULL;
        }
        s_midFactoryGetInstance = env->GetStaticMethodID(s_clsFactorySingleton, "getInstance", "()Lcom/rho/bgservice/IBGServiceFactory;");
        if(!s_midFactoryGetInstance)
        {
            LOG(FATAL) + "Failed to get method 'getInstance' for java class " + FACTORY_SINGLETON_CLASS;
            return NULL;
        }

        //init IBGServiceFactory JNI
        s_clsIFactory = loadClass(env, IFACTORY_CLASS);
        if (!s_clsIFactory) return 0;
        s_midGetApiSingleton = env->GetMethodID(s_clsIFactory, "getApiSingleton", "()Lcom/rho/bgservice/IBGServiceSingleton;");
        if(!s_midGetApiSingleton)
        {
            LOG(FATAL) + "Failed to get method 'getApiSingleton' for java class " + IFACTORY_CLASS;
            return NULL;
        }
        s_midGetApiObject = env->GetMethodID(s_clsIFactory, "getApiObject", "(Ljava/lang/String;)Lcom/rho/bgservice/IBGService;");
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
                        "(Lcom/rho/bgservice/IBGService;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetSimpleStringPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETSIMPLESTRINGPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clssetSimpleStringPropertyTask = loadClass(env, SETSIMPLESTRINGPROPERTY_TASK_CLASS);
        if (!s_clssetSimpleStringPropertyTask) return 0;
        s_midsetSimpleStringPropertyTask = env->GetMethodID(s_clssetSimpleStringPropertyTask, "<init>",
                        "(Lcom/rho/bgservice/IBGService;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetSimpleStringPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETSIMPLESTRINGPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clsenumerateTask = loadClass(env, ENUMERATE_TASK_CLASS);
        if (!s_clsenumerateTask) return 0;
        s_midenumerateTask = env->GetMethodID(s_clsenumerateTask, "<init>",
                        "(Lcom/rho/bgservice/IBGServiceSingleton;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midenumerateTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + ENUMERATE_TASK_CLASS;
            return NULL;
        }

        s_clsstartBackgroundServiceTask = loadClass(env, STARTBACKGROUNDSERVICE_TASK_CLASS);
        if (!s_clsstartBackgroundServiceTask) return 0;
        s_midstartBackgroundServiceTask = env->GetMethodID(s_clsstartBackgroundServiceTask, "<init>",
                        "(Lcom/rho/bgservice/IBGService;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midstartBackgroundServiceTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + STARTBACKGROUNDSERVICE_TASK_CLASS;
            return NULL;
        }

        s_clsstopBackgroundServiceTask = loadClass(env, STOPBACKGROUNDSERVICE_TASK_CLASS);
        if (!s_clsstopBackgroundServiceTask) return 0;
        s_midstopBackgroundServiceTask = env->GetMethodID(s_clsstopBackgroundServiceTask, "<init>",
                        "(Lcom/rho/bgservice/IBGService;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midstopBackgroundServiceTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + STOPBACKGROUNDSERVICE_TASK_CLASS;
            return NULL;
        }

        s_clscheckBackgroundServiceStatusTask = loadClass(env, CHECKBACKGROUNDSERVICESTATUS_TASK_CLASS);
        if (!s_clscheckBackgroundServiceStatusTask) return 0;
        s_midcheckBackgroundServiceStatusTask = env->GetMethodID(s_clscheckBackgroundServiceStatusTask, "<init>",
                        "(Lcom/rho/bgservice/IBGService;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midcheckBackgroundServiceStatusTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + CHECKBACKGROUNDSERVICESTATUS_TASK_CLASS;
            return NULL;
        }

        s_clsgetPropertyTask = loadClass(env, GETPROPERTY_TASK_CLASS);
        if (!s_clsgetPropertyTask) return 0;
        s_midgetPropertyTask = env->GetMethodID(s_clsgetPropertyTask, "<init>",
                        "(Lcom/rho/bgservice/IBGService;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clsgetPropertiesTask = loadClass(env, GETPROPERTIES_TASK_CLASS);
        if (!s_clsgetPropertiesTask) return 0;
        s_midgetPropertiesTask = env->GetMethodID(s_clsgetPropertiesTask, "<init>",
                        "(Lcom/rho/bgservice/IBGService;Ljava/util/List;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPROPERTIES_TASK_CLASS;
            return NULL;
        }

        s_clsgetAllPropertiesTask = loadClass(env, GETALLPROPERTIES_TASK_CLASS);
        if (!s_clsgetAllPropertiesTask) return 0;
        s_midgetAllPropertiesTask = env->GetMethodID(s_clsgetAllPropertiesTask, "<init>",
                        "(Lcom/rho/bgservice/IBGService;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetAllPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETALLPROPERTIES_TASK_CLASS;
            return NULL;
        }

        s_clssetPropertyTask = loadClass(env, SETPROPERTY_TASK_CLASS);
        if (!s_clssetPropertyTask) return 0;
        s_midsetPropertyTask = env->GetMethodID(s_clssetPropertyTask, "<init>",
                        "(Lcom/rho/bgservice/IBGService;Ljava/lang/String;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clssetPropertiesTask = loadClass(env, SETPROPERTIES_TASK_CLASS);
        if (!s_clssetPropertiesTask) return 0;
        s_midsetPropertiesTask = env->GetMethodID(s_clssetPropertiesTask, "<init>",
                        "(Lcom/rho/bgservice/IBGService;Ljava/util/Map;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
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
        LOG(TRACE) + "CBGService JNI init succeeded";
    }
    return env;
}
//----------------------------------------------------------------------------------------------------------------------

void CBGServiceBase::setJavaFactory(JNIEnv* env, jobject jFactory)
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

rho::String CBGServiceBase::getDefaultID()
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

void CBGServiceBase::setDefaultID(const rho::String& id)
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

jobject CBGServiceBase::getFactory(JNIEnv* env)
{
    jobject res = env->CallStaticObjectMethod(s_clsFactorySingleton, s_midFactoryGetInstance);
    return res;
}
//----------------------------------------------------------------------------------------------------------------------

jobject CBGServiceBase::getSingleton(JNIEnv* env)
{
    jhobject jhFactory = getFactory(env);
    jobject res = env->CallObjectMethod(jhFactory.get(), s_midGetApiSingleton);
    return res;
}
//----------------------------------------------------------------------------------------------------------------------

jobject CBGServiceBase::getObject(JNIEnv* env)
{
    jhstring jhId = rho_cast<jstring>(env, m_id);
    jhobject jhFactory = getFactory(env);
    jobject res = env->CallObjectMethod(jhFactory.get(), s_midGetApiObject, jhId.get());
    return res;
}
//----------------------------------------------------------------------------------------------------------------------


}
