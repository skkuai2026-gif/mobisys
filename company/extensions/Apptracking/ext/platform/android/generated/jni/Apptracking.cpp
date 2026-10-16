#include "Apptracking.h"


namespace rho {

IMPLEMENT_LOGCLASS(CApptrackingBase, "ApptrackingJNI");

//ApptrackingFactorySingleton staff
const char* const CApptrackingBase::FACTORY_SINGLETON_CLASS = "com.rho.apptracking.ApptrackingFactorySingleton";
jclass CApptrackingBase::s_clsFactorySingleton = 0;
jmethodID CApptrackingBase::s_midFactorySetInstance;
jmethodID CApptrackingBase::s_midFactoryGetInstance;

//ApptrackingFactory staff
const char* const CApptrackingBase::IFACTORY_CLASS = "com.rho.apptracking.IApptrackingFactory";
jclass CApptrackingBase::s_clsIFactory = 0;
jmethodID CApptrackingBase::s_midGetApiSingleton;
jmethodID CApptrackingBase::s_midGetApiObject;

//ApptrackingSingletonBase staff
const char* const CApptrackingBase::SINGLETON_BASE_CLASS = "com.rho.apptracking.ApptrackingSingletonBase";
jclass CApptrackingBase::s_clsSingletonBase = 0;

//ApptrackingBase staff
const char* const CApptrackingBase::OBJECT_BASE_CLASS = "com.rho.apptracking.ApptrackingBase";
jclass CApptrackingBase::s_clsObjectBase = 0;


//IRhoApiDefaultId staff
const char* const CApptrackingBase::IDEFAULTID_CLASS = "com.rhomobile.rhodes.api.IRhoApiDefaultId";
jclass CApptrackingBase::s_clsIDefaultId = 0;
jmethodID CApptrackingBase::s_midGetDefaultID;
jmethodID CApptrackingBase::s_midSetDefaultID;


//Method tasks

const char* const CApptrackingBase::GETSIMPLESTRINGPROPERTY_TASK_CLASS = 
        "com.rho.apptracking.ApptrackingBase$getSimpleStringPropertyTask";

jclass CApptrackingBase::s_clsgetSimpleStringPropertyTask = 0;
jmethodID CApptrackingBase::s_midgetSimpleStringPropertyTask;

const char* const CApptrackingBase::SETSIMPLESTRINGPROPERTY_TASK_CLASS = 
        "com.rho.apptracking.ApptrackingBase$setSimpleStringPropertyTask";

jclass CApptrackingBase::s_clssetSimpleStringPropertyTask = 0;
jmethodID CApptrackingBase::s_midsetSimpleStringPropertyTask;

const char* const CApptrackingBase::ENUMERATE_TASK_CLASS = 
        "com.rho.apptracking.ApptrackingSingletonBase$enumerateTask";

jclass CApptrackingBase::s_clsenumerateTask = 0;
jmethodID CApptrackingBase::s_midenumerateTask;

const char* const CApptrackingBase::REQUESTAPPTRACKINGPERMISSION_TASK_CLASS = 
        "com.rho.apptracking.ApptrackingBase$requestAppTrackingPermissionTask";

jclass CApptrackingBase::s_clsrequestAppTrackingPermissionTask = 0;
jmethodID CApptrackingBase::s_midrequestAppTrackingPermissionTask;

const char* const CApptrackingBase::GETPROPERTY_TASK_CLASS = 
        "com.rho.apptracking.ApptrackingBase$getPropertyTask";

jclass CApptrackingBase::s_clsgetPropertyTask = 0;
jmethodID CApptrackingBase::s_midgetPropertyTask;

const char* const CApptrackingBase::GETPROPERTIES_TASK_CLASS = 
        "com.rho.apptracking.ApptrackingBase$getPropertiesTask";

jclass CApptrackingBase::s_clsgetPropertiesTask = 0;
jmethodID CApptrackingBase::s_midgetPropertiesTask;

const char* const CApptrackingBase::GETALLPROPERTIES_TASK_CLASS = 
        "com.rho.apptracking.ApptrackingBase$getAllPropertiesTask";

jclass CApptrackingBase::s_clsgetAllPropertiesTask = 0;
jmethodID CApptrackingBase::s_midgetAllPropertiesTask;

const char* const CApptrackingBase::SETPROPERTY_TASK_CLASS = 
        "com.rho.apptracking.ApptrackingBase$setPropertyTask";

jclass CApptrackingBase::s_clssetPropertyTask = 0;
jmethodID CApptrackingBase::s_midsetPropertyTask;

const char* const CApptrackingBase::SETPROPERTIES_TASK_CLASS = 
        "com.rho.apptracking.ApptrackingBase$setPropertiesTask";

jclass CApptrackingBase::s_clssetPropertiesTask = 0;
jmethodID CApptrackingBase::s_midsetPropertiesTask;


//----------------------------------------------------------------------------------------------------------------------

JNIEnv* CApptrackingBase::jniInit()
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

JNIEnv* CApptrackingBase::jniInit(JNIEnv* env)
{
    static bool initialized = false;
    env = MethodExecutorJni::jniInit(env);
    if (!env) {
        LOG(FATAL) + "JNI init failed";
        return 0;
    }

    if(!initialized)
    {
        //init ApptrackingFactorySingleton JNI
        s_clsFactorySingleton = loadClass(env, FACTORY_SINGLETON_CLASS);
        if (!s_clsFactorySingleton) return 0;

        s_midFactorySetInstance = env->GetStaticMethodID(s_clsFactorySingleton, "setInstance", "(Lcom/rho/apptracking/IApptrackingFactory;)V");
        if(!s_midFactorySetInstance)
        {
            LOG(FATAL) + "Failed to get method 'setInstance' for java class " + FACTORY_SINGLETON_CLASS;
            return NULL;
        }
        s_midFactoryGetInstance = env->GetStaticMethodID(s_clsFactorySingleton, "getInstance", "()Lcom/rho/apptracking/IApptrackingFactory;");
        if(!s_midFactoryGetInstance)
        {
            LOG(FATAL) + "Failed to get method 'getInstance' for java class " + FACTORY_SINGLETON_CLASS;
            return NULL;
        }

        //init IApptrackingFactory JNI
        s_clsIFactory = loadClass(env, IFACTORY_CLASS);
        if (!s_clsIFactory) return 0;
        s_midGetApiSingleton = env->GetMethodID(s_clsIFactory, "getApiSingleton", "()Lcom/rho/apptracking/IApptrackingSingleton;");
        if(!s_midGetApiSingleton)
        {
            LOG(FATAL) + "Failed to get method 'getApiSingleton' for java class " + IFACTORY_CLASS;
            return NULL;
        }
        s_midGetApiObject = env->GetMethodID(s_clsIFactory, "getApiObject", "(Ljava/lang/String;)Lcom/rho/apptracking/IApptracking;");
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
                        "(Lcom/rho/apptracking/IApptracking;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetSimpleStringPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETSIMPLESTRINGPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clssetSimpleStringPropertyTask = loadClass(env, SETSIMPLESTRINGPROPERTY_TASK_CLASS);
        if (!s_clssetSimpleStringPropertyTask) return 0;
        s_midsetSimpleStringPropertyTask = env->GetMethodID(s_clssetSimpleStringPropertyTask, "<init>",
                        "(Lcom/rho/apptracking/IApptracking;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetSimpleStringPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETSIMPLESTRINGPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clsenumerateTask = loadClass(env, ENUMERATE_TASK_CLASS);
        if (!s_clsenumerateTask) return 0;
        s_midenumerateTask = env->GetMethodID(s_clsenumerateTask, "<init>",
                        "(Lcom/rho/apptracking/IApptrackingSingleton;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midenumerateTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + ENUMERATE_TASK_CLASS;
            return NULL;
        }

        s_clsrequestAppTrackingPermissionTask = loadClass(env, REQUESTAPPTRACKINGPERMISSION_TASK_CLASS);
        if (!s_clsrequestAppTrackingPermissionTask) return 0;
        s_midrequestAppTrackingPermissionTask = env->GetMethodID(s_clsrequestAppTrackingPermissionTask, "<init>",
                        "(Lcom/rho/apptracking/IApptracking;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midrequestAppTrackingPermissionTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + REQUESTAPPTRACKINGPERMISSION_TASK_CLASS;
            return NULL;
        }

        s_clsgetPropertyTask = loadClass(env, GETPROPERTY_TASK_CLASS);
        if (!s_clsgetPropertyTask) return 0;
        s_midgetPropertyTask = env->GetMethodID(s_clsgetPropertyTask, "<init>",
                        "(Lcom/rho/apptracking/IApptracking;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clsgetPropertiesTask = loadClass(env, GETPROPERTIES_TASK_CLASS);
        if (!s_clsgetPropertiesTask) return 0;
        s_midgetPropertiesTask = env->GetMethodID(s_clsgetPropertiesTask, "<init>",
                        "(Lcom/rho/apptracking/IApptracking;Ljava/util/List;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPROPERTIES_TASK_CLASS;
            return NULL;
        }

        s_clsgetAllPropertiesTask = loadClass(env, GETALLPROPERTIES_TASK_CLASS);
        if (!s_clsgetAllPropertiesTask) return 0;
        s_midgetAllPropertiesTask = env->GetMethodID(s_clsgetAllPropertiesTask, "<init>",
                        "(Lcom/rho/apptracking/IApptracking;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetAllPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETALLPROPERTIES_TASK_CLASS;
            return NULL;
        }

        s_clssetPropertyTask = loadClass(env, SETPROPERTY_TASK_CLASS);
        if (!s_clssetPropertyTask) return 0;
        s_midsetPropertyTask = env->GetMethodID(s_clssetPropertyTask, "<init>",
                        "(Lcom/rho/apptracking/IApptracking;Ljava/lang/String;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clssetPropertiesTask = loadClass(env, SETPROPERTIES_TASK_CLASS);
        if (!s_clssetPropertiesTask) return 0;
        s_midsetPropertiesTask = env->GetMethodID(s_clssetPropertiesTask, "<init>",
                        "(Lcom/rho/apptracking/IApptracking;Ljava/util/Map;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
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
        LOG(TRACE) + "CApptracking JNI init succeeded";
    }
    return env;
}
//----------------------------------------------------------------------------------------------------------------------

void CApptrackingBase::setJavaFactory(JNIEnv* env, jobject jFactory)
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

rho::String CApptrackingBase::getDefaultID()
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

void CApptrackingBase::setDefaultID(const rho::String& id)
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

jobject CApptrackingBase::getFactory(JNIEnv* env)
{
    jobject res = env->CallStaticObjectMethod(s_clsFactorySingleton, s_midFactoryGetInstance);
    return res;
}
//----------------------------------------------------------------------------------------------------------------------

jobject CApptrackingBase::getSingleton(JNIEnv* env)
{
    jhobject jhFactory = getFactory(env);
    jobject res = env->CallObjectMethod(jhFactory.get(), s_midGetApiSingleton);
    return res;
}
//----------------------------------------------------------------------------------------------------------------------

jobject CApptrackingBase::getObject(JNIEnv* env)
{
    jhstring jhId = rho_cast<jstring>(env, m_id);
    jhobject jhFactory = getFactory(env);
    jobject res = env->CallObjectMethod(jhFactory.get(), s_midGetApiObject, jhId.get());
    return res;
}
//----------------------------------------------------------------------------------------------------------------------


}
