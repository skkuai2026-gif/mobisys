#include "Fingerprint.h"


namespace rho {

IMPLEMENT_LOGCLASS(CFingerprintBase, "FingerprintJNI");

//FingerprintFactorySingleton staff
const char* const CFingerprintBase::FACTORY_SINGLETON_CLASS = "com.rho.fingerprint.FingerprintFactorySingleton";
jclass CFingerprintBase::s_clsFactorySingleton = 0;
jmethodID CFingerprintBase::s_midFactorySetInstance;
jmethodID CFingerprintBase::s_midFactoryGetInstance;

//FingerprintFactory staff
const char* const CFingerprintBase::IFACTORY_CLASS = "com.rho.fingerprint.IFingerprintFactory";
jclass CFingerprintBase::s_clsIFactory = 0;
jmethodID CFingerprintBase::s_midGetApiSingleton;
jmethodID CFingerprintBase::s_midGetApiObject;

//FingerprintSingletonBase staff
const char* const CFingerprintBase::SINGLETON_BASE_CLASS = "com.rho.fingerprint.FingerprintSingletonBase";
jclass CFingerprintBase::s_clsSingletonBase = 0;

//FingerprintBase staff
const char* const CFingerprintBase::OBJECT_BASE_CLASS = "com.rho.fingerprint.FingerprintBase";
jclass CFingerprintBase::s_clsObjectBase = 0;


//IRhoApiDefaultId staff
const char* const CFingerprintBase::IDEFAULTID_CLASS = "com.rhomobile.rhodes.api.IRhoApiDefaultId";
jclass CFingerprintBase::s_clsIDefaultId = 0;
jmethodID CFingerprintBase::s_midGetDefaultID;
jmethodID CFingerprintBase::s_midSetDefaultID;


//Method tasks

const char* const CFingerprintBase::GETSIMPLESTRINGPROPERTY_TASK_CLASS = 
        "com.rho.fingerprint.FingerprintBase$getSimpleStringPropertyTask";

jclass CFingerprintBase::s_clsgetSimpleStringPropertyTask = 0;
jmethodID CFingerprintBase::s_midgetSimpleStringPropertyTask;

const char* const CFingerprintBase::SETSIMPLESTRINGPROPERTY_TASK_CLASS = 
        "com.rho.fingerprint.FingerprintBase$setSimpleStringPropertyTask";

jclass CFingerprintBase::s_clssetSimpleStringPropertyTask = 0;
jmethodID CFingerprintBase::s_midsetSimpleStringPropertyTask;

const char* const CFingerprintBase::ENUMERATE_TASK_CLASS = 
        "com.rho.fingerprint.FingerprintSingletonBase$enumerateTask";

jclass CFingerprintBase::s_clsenumerateTask = 0;
jmethodID CFingerprintBase::s_midenumerateTask;

const char* const CFingerprintBase::ENABLEFINGERPRINTSCAN_TASK_CLASS = 
        "com.rho.fingerprint.FingerprintBase$enableFingerprintScanTask";

jclass CFingerprintBase::s_clsenableFingerprintScanTask = 0;
jmethodID CFingerprintBase::s_midenableFingerprintScanTask;

const char* const CFingerprintBase::GETPROPERTY_TASK_CLASS = 
        "com.rho.fingerprint.FingerprintBase$getPropertyTask";

jclass CFingerprintBase::s_clsgetPropertyTask = 0;
jmethodID CFingerprintBase::s_midgetPropertyTask;

const char* const CFingerprintBase::GETPROPERTIES_TASK_CLASS = 
        "com.rho.fingerprint.FingerprintBase$getPropertiesTask";

jclass CFingerprintBase::s_clsgetPropertiesTask = 0;
jmethodID CFingerprintBase::s_midgetPropertiesTask;

const char* const CFingerprintBase::GETALLPROPERTIES_TASK_CLASS = 
        "com.rho.fingerprint.FingerprintBase$getAllPropertiesTask";

jclass CFingerprintBase::s_clsgetAllPropertiesTask = 0;
jmethodID CFingerprintBase::s_midgetAllPropertiesTask;

const char* const CFingerprintBase::SETPROPERTY_TASK_CLASS = 
        "com.rho.fingerprint.FingerprintBase$setPropertyTask";

jclass CFingerprintBase::s_clssetPropertyTask = 0;
jmethodID CFingerprintBase::s_midsetPropertyTask;

const char* const CFingerprintBase::SETPROPERTIES_TASK_CLASS = 
        "com.rho.fingerprint.FingerprintBase$setPropertiesTask";

jclass CFingerprintBase::s_clssetPropertiesTask = 0;
jmethodID CFingerprintBase::s_midsetPropertiesTask;


//----------------------------------------------------------------------------------------------------------------------

JNIEnv* CFingerprintBase::jniInit()
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

JNIEnv* CFingerprintBase::jniInit(JNIEnv* env)
{
    static bool initialized = false;
    env = MethodExecutorJni::jniInit(env);
    if (!env) {
        LOG(FATAL) + "JNI init failed";
        return 0;
    }

    if(!initialized)
    {
        //init FingerprintFactorySingleton JNI
        s_clsFactorySingleton = loadClass(env, FACTORY_SINGLETON_CLASS);
        if (!s_clsFactorySingleton) return 0;

        s_midFactorySetInstance = env->GetStaticMethodID(s_clsFactorySingleton, "setInstance", "(Lcom/rho/fingerprint/IFingerprintFactory;)V");
        if(!s_midFactorySetInstance)
        {
            LOG(FATAL) + "Failed to get method 'setInstance' for java class " + FACTORY_SINGLETON_CLASS;
            return NULL;
        }
        s_midFactoryGetInstance = env->GetStaticMethodID(s_clsFactorySingleton, "getInstance", "()Lcom/rho/fingerprint/IFingerprintFactory;");
        if(!s_midFactoryGetInstance)
        {
            LOG(FATAL) + "Failed to get method 'getInstance' for java class " + FACTORY_SINGLETON_CLASS;
            return NULL;
        }

        //init IFingerprintFactory JNI
        s_clsIFactory = loadClass(env, IFACTORY_CLASS);
        if (!s_clsIFactory) return 0;
        s_midGetApiSingleton = env->GetMethodID(s_clsIFactory, "getApiSingleton", "()Lcom/rho/fingerprint/IFingerprintSingleton;");
        if(!s_midGetApiSingleton)
        {
            LOG(FATAL) + "Failed to get method 'getApiSingleton' for java class " + IFACTORY_CLASS;
            return NULL;
        }
        s_midGetApiObject = env->GetMethodID(s_clsIFactory, "getApiObject", "(Ljava/lang/String;)Lcom/rho/fingerprint/IFingerprint;");
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
                        "(Lcom/rho/fingerprint/IFingerprint;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetSimpleStringPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETSIMPLESTRINGPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clssetSimpleStringPropertyTask = loadClass(env, SETSIMPLESTRINGPROPERTY_TASK_CLASS);
        if (!s_clssetSimpleStringPropertyTask) return 0;
        s_midsetSimpleStringPropertyTask = env->GetMethodID(s_clssetSimpleStringPropertyTask, "<init>",
                        "(Lcom/rho/fingerprint/IFingerprint;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetSimpleStringPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETSIMPLESTRINGPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clsenumerateTask = loadClass(env, ENUMERATE_TASK_CLASS);
        if (!s_clsenumerateTask) return 0;
        s_midenumerateTask = env->GetMethodID(s_clsenumerateTask, "<init>",
                        "(Lcom/rho/fingerprint/IFingerprintSingleton;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midenumerateTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + ENUMERATE_TASK_CLASS;
            return NULL;
        }

        s_clsenableFingerprintScanTask = loadClass(env, ENABLEFINGERPRINTSCAN_TASK_CLASS);
        if (!s_clsenableFingerprintScanTask) return 0;
        s_midenableFingerprintScanTask = env->GetMethodID(s_clsenableFingerprintScanTask, "<init>",
                        "(Lcom/rho/fingerprint/IFingerprint;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midenableFingerprintScanTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + ENABLEFINGERPRINTSCAN_TASK_CLASS;
            return NULL;
        }

        s_clsgetPropertyTask = loadClass(env, GETPROPERTY_TASK_CLASS);
        if (!s_clsgetPropertyTask) return 0;
        s_midgetPropertyTask = env->GetMethodID(s_clsgetPropertyTask, "<init>",
                        "(Lcom/rho/fingerprint/IFingerprint;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clsgetPropertiesTask = loadClass(env, GETPROPERTIES_TASK_CLASS);
        if (!s_clsgetPropertiesTask) return 0;
        s_midgetPropertiesTask = env->GetMethodID(s_clsgetPropertiesTask, "<init>",
                        "(Lcom/rho/fingerprint/IFingerprint;Ljava/util/List;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPROPERTIES_TASK_CLASS;
            return NULL;
        }

        s_clsgetAllPropertiesTask = loadClass(env, GETALLPROPERTIES_TASK_CLASS);
        if (!s_clsgetAllPropertiesTask) return 0;
        s_midgetAllPropertiesTask = env->GetMethodID(s_clsgetAllPropertiesTask, "<init>",
                        "(Lcom/rho/fingerprint/IFingerprint;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetAllPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETALLPROPERTIES_TASK_CLASS;
            return NULL;
        }

        s_clssetPropertyTask = loadClass(env, SETPROPERTY_TASK_CLASS);
        if (!s_clssetPropertyTask) return 0;
        s_midsetPropertyTask = env->GetMethodID(s_clssetPropertyTask, "<init>",
                        "(Lcom/rho/fingerprint/IFingerprint;Ljava/lang/String;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clssetPropertiesTask = loadClass(env, SETPROPERTIES_TASK_CLASS);
        if (!s_clssetPropertiesTask) return 0;
        s_midsetPropertiesTask = env->GetMethodID(s_clssetPropertiesTask, "<init>",
                        "(Lcom/rho/fingerprint/IFingerprint;Ljava/util/Map;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
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
        LOG(TRACE) + "CFingerprint JNI init succeeded";
    }
    return env;
}
//----------------------------------------------------------------------------------------------------------------------

void CFingerprintBase::setJavaFactory(JNIEnv* env, jobject jFactory)
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

rho::String CFingerprintBase::getDefaultID()
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

void CFingerprintBase::setDefaultID(const rho::String& id)
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

jobject CFingerprintBase::getFactory(JNIEnv* env)
{
    jobject res = env->CallStaticObjectMethod(s_clsFactorySingleton, s_midFactoryGetInstance);
    return res;
}
//----------------------------------------------------------------------------------------------------------------------

jobject CFingerprintBase::getSingleton(JNIEnv* env)
{
    jhobject jhFactory = getFactory(env);
    jobject res = env->CallObjectMethod(jhFactory.get(), s_midGetApiSingleton);
    return res;
}
//----------------------------------------------------------------------------------------------------------------------

jobject CFingerprintBase::getObject(JNIEnv* env)
{
    jhstring jhId = rho_cast<jstring>(env, m_id);
    jhobject jhFactory = getFactory(env);
    jobject res = env->CallObjectMethod(jhFactory.get(), s_midGetApiObject, jhId.get());
    return res;
}
//----------------------------------------------------------------------------------------------------------------------


}
