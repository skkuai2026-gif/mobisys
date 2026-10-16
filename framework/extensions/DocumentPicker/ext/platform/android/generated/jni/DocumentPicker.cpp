#include "DocumentPicker.h"


namespace rho {

IMPLEMENT_LOGCLASS(CDocumentPickerBase, "DocumentPickerJNI");

//DocumentPickerFactorySingleton staff
const char* const CDocumentPickerBase::FACTORY_SINGLETON_CLASS = "com.rho.documentpicker.DocumentPickerFactorySingleton";
jclass CDocumentPickerBase::s_clsFactorySingleton = 0;
jmethodID CDocumentPickerBase::s_midFactorySetInstance;
jmethodID CDocumentPickerBase::s_midFactoryGetInstance;

//DocumentPickerFactory staff
const char* const CDocumentPickerBase::IFACTORY_CLASS = "com.rho.documentpicker.IDocumentPickerFactory";
jclass CDocumentPickerBase::s_clsIFactory = 0;
jmethodID CDocumentPickerBase::s_midGetApiSingleton;
jmethodID CDocumentPickerBase::s_midGetApiObject;

//DocumentPickerSingletonBase staff
const char* const CDocumentPickerBase::SINGLETON_BASE_CLASS = "com.rho.documentpicker.DocumentPickerSingletonBase";
jclass CDocumentPickerBase::s_clsSingletonBase = 0;

//DocumentPickerBase staff
const char* const CDocumentPickerBase::OBJECT_BASE_CLASS = "com.rho.documentpicker.DocumentPickerBase";
jclass CDocumentPickerBase::s_clsObjectBase = 0;


//IRhoApiDefaultId staff
const char* const CDocumentPickerBase::IDEFAULTID_CLASS = "com.rhomobile.rhodes.api.IRhoApiDefaultId";
jclass CDocumentPickerBase::s_clsIDefaultId = 0;
jmethodID CDocumentPickerBase::s_midGetDefaultID;
jmethodID CDocumentPickerBase::s_midSetDefaultID;


//Method tasks

const char* const CDocumentPickerBase::GETSIMPLESTRINGPROPERTY_TASK_CLASS = 
        "com.rho.documentpicker.DocumentPickerBase$getSimpleStringPropertyTask";

jclass CDocumentPickerBase::s_clsgetSimpleStringPropertyTask = 0;
jmethodID CDocumentPickerBase::s_midgetSimpleStringPropertyTask;

const char* const CDocumentPickerBase::SETSIMPLESTRINGPROPERTY_TASK_CLASS = 
        "com.rho.documentpicker.DocumentPickerBase$setSimpleStringPropertyTask";

jclass CDocumentPickerBase::s_clssetSimpleStringPropertyTask = 0;
jmethodID CDocumentPickerBase::s_midsetSimpleStringPropertyTask;

const char* const CDocumentPickerBase::ENUMERATE_TASK_CLASS = 
        "com.rho.documentpicker.DocumentPickerSingletonBase$enumerateTask";

jclass CDocumentPickerBase::s_clsenumerateTask = 0;
jmethodID CDocumentPickerBase::s_midenumerateTask;

const char* const CDocumentPickerBase::PICKDOCUMENT_TASK_CLASS = 
        "com.rho.documentpicker.DocumentPickerBase$pickDocumentTask";

jclass CDocumentPickerBase::s_clspickDocumentTask = 0;
jmethodID CDocumentPickerBase::s_midpickDocumentTask;

const char* const CDocumentPickerBase::GETPROPERTY_TASK_CLASS = 
        "com.rho.documentpicker.DocumentPickerBase$getPropertyTask";

jclass CDocumentPickerBase::s_clsgetPropertyTask = 0;
jmethodID CDocumentPickerBase::s_midgetPropertyTask;

const char* const CDocumentPickerBase::GETPROPERTIES_TASK_CLASS = 
        "com.rho.documentpicker.DocumentPickerBase$getPropertiesTask";

jclass CDocumentPickerBase::s_clsgetPropertiesTask = 0;
jmethodID CDocumentPickerBase::s_midgetPropertiesTask;

const char* const CDocumentPickerBase::GETALLPROPERTIES_TASK_CLASS = 
        "com.rho.documentpicker.DocumentPickerBase$getAllPropertiesTask";

jclass CDocumentPickerBase::s_clsgetAllPropertiesTask = 0;
jmethodID CDocumentPickerBase::s_midgetAllPropertiesTask;

const char* const CDocumentPickerBase::SETPROPERTY_TASK_CLASS = 
        "com.rho.documentpicker.DocumentPickerBase$setPropertyTask";

jclass CDocumentPickerBase::s_clssetPropertyTask = 0;
jmethodID CDocumentPickerBase::s_midsetPropertyTask;

const char* const CDocumentPickerBase::SETPROPERTIES_TASK_CLASS = 
        "com.rho.documentpicker.DocumentPickerBase$setPropertiesTask";

jclass CDocumentPickerBase::s_clssetPropertiesTask = 0;
jmethodID CDocumentPickerBase::s_midsetPropertiesTask;


//----------------------------------------------------------------------------------------------------------------------

JNIEnv* CDocumentPickerBase::jniInit()
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

JNIEnv* CDocumentPickerBase::jniInit(JNIEnv* env)
{
    static bool initialized = false;
    env = MethodExecutorJni::jniInit(env);
    if (!env) {
        LOG(FATAL) + "JNI init failed";
        return 0;
    }

    if(!initialized)
    {
        //init DocumentPickerFactorySingleton JNI
        s_clsFactorySingleton = loadClass(env, FACTORY_SINGLETON_CLASS);
        if (!s_clsFactorySingleton) return 0;

        s_midFactorySetInstance = env->GetStaticMethodID(s_clsFactorySingleton, "setInstance", "(Lcom/rho/documentpicker/IDocumentPickerFactory;)V");
        if(!s_midFactorySetInstance)
        {
            LOG(FATAL) + "Failed to get method 'setInstance' for java class " + FACTORY_SINGLETON_CLASS;
            return NULL;
        }
        s_midFactoryGetInstance = env->GetStaticMethodID(s_clsFactorySingleton, "getInstance", "()Lcom/rho/documentpicker/IDocumentPickerFactory;");
        if(!s_midFactoryGetInstance)
        {
            LOG(FATAL) + "Failed to get method 'getInstance' for java class " + FACTORY_SINGLETON_CLASS;
            return NULL;
        }

        //init IDocumentPickerFactory JNI
        s_clsIFactory = loadClass(env, IFACTORY_CLASS);
        if (!s_clsIFactory) return 0;
        s_midGetApiSingleton = env->GetMethodID(s_clsIFactory, "getApiSingleton", "()Lcom/rho/documentpicker/IDocumentPickerSingleton;");
        if(!s_midGetApiSingleton)
        {
            LOG(FATAL) + "Failed to get method 'getApiSingleton' for java class " + IFACTORY_CLASS;
            return NULL;
        }
        s_midGetApiObject = env->GetMethodID(s_clsIFactory, "getApiObject", "(Ljava/lang/String;)Lcom/rho/documentpicker/IDocumentPicker;");
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
                        "(Lcom/rho/documentpicker/IDocumentPicker;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetSimpleStringPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETSIMPLESTRINGPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clssetSimpleStringPropertyTask = loadClass(env, SETSIMPLESTRINGPROPERTY_TASK_CLASS);
        if (!s_clssetSimpleStringPropertyTask) return 0;
        s_midsetSimpleStringPropertyTask = env->GetMethodID(s_clssetSimpleStringPropertyTask, "<init>",
                        "(Lcom/rho/documentpicker/IDocumentPicker;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetSimpleStringPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETSIMPLESTRINGPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clsenumerateTask = loadClass(env, ENUMERATE_TASK_CLASS);
        if (!s_clsenumerateTask) return 0;
        s_midenumerateTask = env->GetMethodID(s_clsenumerateTask, "<init>",
                        "(Lcom/rho/documentpicker/IDocumentPickerSingleton;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midenumerateTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + ENUMERATE_TASK_CLASS;
            return NULL;
        }

        s_clspickDocumentTask = loadClass(env, PICKDOCUMENT_TASK_CLASS);
        if (!s_clspickDocumentTask) return 0;
        s_midpickDocumentTask = env->GetMethodID(s_clspickDocumentTask, "<init>",
                        "(Lcom/rho/documentpicker/IDocumentPicker;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midpickDocumentTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + PICKDOCUMENT_TASK_CLASS;
            return NULL;
        }

        s_clsgetPropertyTask = loadClass(env, GETPROPERTY_TASK_CLASS);
        if (!s_clsgetPropertyTask) return 0;
        s_midgetPropertyTask = env->GetMethodID(s_clsgetPropertyTask, "<init>",
                        "(Lcom/rho/documentpicker/IDocumentPicker;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clsgetPropertiesTask = loadClass(env, GETPROPERTIES_TASK_CLASS);
        if (!s_clsgetPropertiesTask) return 0;
        s_midgetPropertiesTask = env->GetMethodID(s_clsgetPropertiesTask, "<init>",
                        "(Lcom/rho/documentpicker/IDocumentPicker;Ljava/util/List;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPROPERTIES_TASK_CLASS;
            return NULL;
        }

        s_clsgetAllPropertiesTask = loadClass(env, GETALLPROPERTIES_TASK_CLASS);
        if (!s_clsgetAllPropertiesTask) return 0;
        s_midgetAllPropertiesTask = env->GetMethodID(s_clsgetAllPropertiesTask, "<init>",
                        "(Lcom/rho/documentpicker/IDocumentPicker;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetAllPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETALLPROPERTIES_TASK_CLASS;
            return NULL;
        }

        s_clssetPropertyTask = loadClass(env, SETPROPERTY_TASK_CLASS);
        if (!s_clssetPropertyTask) return 0;
        s_midsetPropertyTask = env->GetMethodID(s_clssetPropertyTask, "<init>",
                        "(Lcom/rho/documentpicker/IDocumentPicker;Ljava/lang/String;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clssetPropertiesTask = loadClass(env, SETPROPERTIES_TASK_CLASS);
        if (!s_clssetPropertiesTask) return 0;
        s_midsetPropertiesTask = env->GetMethodID(s_clssetPropertiesTask, "<init>",
                        "(Lcom/rho/documentpicker/IDocumentPicker;Ljava/util/Map;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
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
        LOG(TRACE) + "CDocumentPicker JNI init succeeded";
    }
    return env;
}
//----------------------------------------------------------------------------------------------------------------------

void CDocumentPickerBase::setJavaFactory(JNIEnv* env, jobject jFactory)
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

rho::String CDocumentPickerBase::getDefaultID()
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

void CDocumentPickerBase::setDefaultID(const rho::String& id)
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

jobject CDocumentPickerBase::getFactory(JNIEnv* env)
{
    jobject res = env->CallStaticObjectMethod(s_clsFactorySingleton, s_midFactoryGetInstance);
    return res;
}
//----------------------------------------------------------------------------------------------------------------------

jobject CDocumentPickerBase::getSingleton(JNIEnv* env)
{
    jhobject jhFactory = getFactory(env);
    jobject res = env->CallObjectMethod(jhFactory.get(), s_midGetApiSingleton);
    return res;
}
//----------------------------------------------------------------------------------------------------------------------

jobject CDocumentPickerBase::getObject(JNIEnv* env)
{
    jhstring jhId = rho_cast<jstring>(env, m_id);
    jhobject jhFactory = getFactory(env);
    jobject res = env->CallObjectMethod(jhFactory.get(), s_midGetApiObject, jhId.get());
    return res;
}
//----------------------------------------------------------------------------------------------------------------------


}
