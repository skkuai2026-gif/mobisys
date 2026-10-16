#include "HtmlToGraph.h"


namespace rho {

IMPLEMENT_LOGCLASS(CHtmlToGraphBase, "HtmlToGraphJNI");

//HtmlToGraphFactorySingleton staff
const char* const CHtmlToGraphBase::FACTORY_SINGLETON_CLASS = "com.rho.htmltograph.HtmlToGraphFactorySingleton";
jclass CHtmlToGraphBase::s_clsFactorySingleton = 0;
jmethodID CHtmlToGraphBase::s_midFactorySetInstance;
jmethodID CHtmlToGraphBase::s_midFactoryGetInstance;

//HtmlToGraphFactory staff
const char* const CHtmlToGraphBase::IFACTORY_CLASS = "com.rho.htmltograph.IHtmlToGraphFactory";
jclass CHtmlToGraphBase::s_clsIFactory = 0;
jmethodID CHtmlToGraphBase::s_midGetApiSingleton;
jmethodID CHtmlToGraphBase::s_midGetApiObject;

//HtmlToGraphSingletonBase staff
const char* const CHtmlToGraphBase::SINGLETON_BASE_CLASS = "com.rho.htmltograph.HtmlToGraphSingletonBase";
jclass CHtmlToGraphBase::s_clsSingletonBase = 0;

//HtmlToGraphBase staff
const char* const CHtmlToGraphBase::OBJECT_BASE_CLASS = "com.rho.htmltograph.HtmlToGraphBase";
jclass CHtmlToGraphBase::s_clsObjectBase = 0;


//IRhoApiDefaultId staff
const char* const CHtmlToGraphBase::IDEFAULTID_CLASS = "com.rhomobile.rhodes.api.IRhoApiDefaultId";
jclass CHtmlToGraphBase::s_clsIDefaultId = 0;
jmethodID CHtmlToGraphBase::s_midGetDefaultID;
jmethodID CHtmlToGraphBase::s_midSetDefaultID;


//Method tasks

const char* const CHtmlToGraphBase::GETSIMPLESTRINGPROPERTY_TASK_CLASS = 
        "com.rho.htmltograph.HtmlToGraphBase$getSimpleStringPropertyTask";

jclass CHtmlToGraphBase::s_clsgetSimpleStringPropertyTask = 0;
jmethodID CHtmlToGraphBase::s_midgetSimpleStringPropertyTask;

const char* const CHtmlToGraphBase::SETSIMPLESTRINGPROPERTY_TASK_CLASS = 
        "com.rho.htmltograph.HtmlToGraphBase$setSimpleStringPropertyTask";

jclass CHtmlToGraphBase::s_clssetSimpleStringPropertyTask = 0;
jmethodID CHtmlToGraphBase::s_midsetSimpleStringPropertyTask;

const char* const CHtmlToGraphBase::ENUMERATE_TASK_CLASS = 
        "com.rho.htmltograph.HtmlToGraphSingletonBase$enumerateTask";

jclass CHtmlToGraphBase::s_clsenumerateTask = 0;
jmethodID CHtmlToGraphBase::s_midenumerateTask;

const char* const CHtmlToGraphBase::GETPLATFORMNAME_TASK_CLASS = 
        "com.rho.htmltograph.HtmlToGraphBase$getPlatformNameTask";

jclass CHtmlToGraphBase::s_clsgetPlatformNameTask = 0;
jmethodID CHtmlToGraphBase::s_midgetPlatformNameTask;

const char* const CHtmlToGraphBase::GETGRAPHIOS_TASK_CLASS = 
        "com.rho.htmltograph.HtmlToGraphBase$getGraphIOSTask";

jclass CHtmlToGraphBase::s_clsgetGraphIOSTask = 0;
jmethodID CHtmlToGraphBase::s_midgetGraphIOSTask;

const char* const CHtmlToGraphBase::GETGRAPHANDROID_TASK_CLASS = 
        "com.rho.htmltograph.HtmlToGraphBase$getGraphAndroidTask";

jclass CHtmlToGraphBase::s_clsgetGraphAndroidTask = 0;
jmethodID CHtmlToGraphBase::s_midgetGraphAndroidTask;

const char* const CHtmlToGraphBase::CALCSUMM_TASK_CLASS = 
        "com.rho.htmltograph.HtmlToGraphBase$calcSummTask";

jclass CHtmlToGraphBase::s_clscalcSummTask = 0;
jmethodID CHtmlToGraphBase::s_midcalcSummTask;

const char* const CHtmlToGraphBase::JOINSTRINGS_TASK_CLASS = 
        "com.rho.htmltograph.HtmlToGraphBase$joinStringsTask";

jclass CHtmlToGraphBase::s_clsjoinStringsTask = 0;
jmethodID CHtmlToGraphBase::s_midjoinStringsTask;

const char* const CHtmlToGraphBase::GETPROPERTY_TASK_CLASS = 
        "com.rho.htmltograph.HtmlToGraphBase$getPropertyTask";

jclass CHtmlToGraphBase::s_clsgetPropertyTask = 0;
jmethodID CHtmlToGraphBase::s_midgetPropertyTask;

const char* const CHtmlToGraphBase::GETPROPERTIES_TASK_CLASS = 
        "com.rho.htmltograph.HtmlToGraphBase$getPropertiesTask";

jclass CHtmlToGraphBase::s_clsgetPropertiesTask = 0;
jmethodID CHtmlToGraphBase::s_midgetPropertiesTask;

const char* const CHtmlToGraphBase::GETALLPROPERTIES_TASK_CLASS = 
        "com.rho.htmltograph.HtmlToGraphBase$getAllPropertiesTask";

jclass CHtmlToGraphBase::s_clsgetAllPropertiesTask = 0;
jmethodID CHtmlToGraphBase::s_midgetAllPropertiesTask;

const char* const CHtmlToGraphBase::SETPROPERTY_TASK_CLASS = 
        "com.rho.htmltograph.HtmlToGraphBase$setPropertyTask";

jclass CHtmlToGraphBase::s_clssetPropertyTask = 0;
jmethodID CHtmlToGraphBase::s_midsetPropertyTask;

const char* const CHtmlToGraphBase::SETPROPERTIES_TASK_CLASS = 
        "com.rho.htmltograph.HtmlToGraphBase$setPropertiesTask";

jclass CHtmlToGraphBase::s_clssetPropertiesTask = 0;
jmethodID CHtmlToGraphBase::s_midsetPropertiesTask;


//----------------------------------------------------------------------------------------------------------------------

JNIEnv* CHtmlToGraphBase::jniInit()
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

JNIEnv* CHtmlToGraphBase::jniInit(JNIEnv* env)
{
    static bool initialized = false;
    env = MethodExecutorJni::jniInit(env);
    if (!env) {
        LOG(FATAL) + "JNI init failed";
        return 0;
    }

    if(!initialized)
    {
        //init HtmlToGraphFactorySingleton JNI
        s_clsFactorySingleton = loadClass(env, FACTORY_SINGLETON_CLASS);
        if (!s_clsFactorySingleton) return 0;

        s_midFactorySetInstance = env->GetStaticMethodID(s_clsFactorySingleton, "setInstance", "(Lcom/rho/htmltograph/IHtmlToGraphFactory;)V");
        if(!s_midFactorySetInstance)
        {
            LOG(FATAL) + "Failed to get method 'setInstance' for java class " + FACTORY_SINGLETON_CLASS;
            return NULL;
        }
        s_midFactoryGetInstance = env->GetStaticMethodID(s_clsFactorySingleton, "getInstance", "()Lcom/rho/htmltograph/IHtmlToGraphFactory;");
        if(!s_midFactoryGetInstance)
        {
            LOG(FATAL) + "Failed to get method 'getInstance' for java class " + FACTORY_SINGLETON_CLASS;
            return NULL;
        }

        //init IHtmlToGraphFactory JNI
        s_clsIFactory = loadClass(env, IFACTORY_CLASS);
        if (!s_clsIFactory) return 0;
        s_midGetApiSingleton = env->GetMethodID(s_clsIFactory, "getApiSingleton", "()Lcom/rho/htmltograph/IHtmlToGraphSingleton;");
        if(!s_midGetApiSingleton)
        {
            LOG(FATAL) + "Failed to get method 'getApiSingleton' for java class " + IFACTORY_CLASS;
            return NULL;
        }
        s_midGetApiObject = env->GetMethodID(s_clsIFactory, "getApiObject", "(Ljava/lang/String;)Lcom/rho/htmltograph/IHtmlToGraph;");
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
                        "(Lcom/rho/htmltograph/IHtmlToGraph;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetSimpleStringPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETSIMPLESTRINGPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clssetSimpleStringPropertyTask = loadClass(env, SETSIMPLESTRINGPROPERTY_TASK_CLASS);
        if (!s_clssetSimpleStringPropertyTask) return 0;
        s_midsetSimpleStringPropertyTask = env->GetMethodID(s_clssetSimpleStringPropertyTask, "<init>",
                        "(Lcom/rho/htmltograph/IHtmlToGraph;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetSimpleStringPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETSIMPLESTRINGPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clsenumerateTask = loadClass(env, ENUMERATE_TASK_CLASS);
        if (!s_clsenumerateTask) return 0;
        s_midenumerateTask = env->GetMethodID(s_clsenumerateTask, "<init>",
                        "(Lcom/rho/htmltograph/IHtmlToGraphSingleton;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midenumerateTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + ENUMERATE_TASK_CLASS;
            return NULL;
        }

        s_clsgetPlatformNameTask = loadClass(env, GETPLATFORMNAME_TASK_CLASS);
        if (!s_clsgetPlatformNameTask) return 0;
        s_midgetPlatformNameTask = env->GetMethodID(s_clsgetPlatformNameTask, "<init>",
                        "(Lcom/rho/htmltograph/IHtmlToGraph;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPlatformNameTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPLATFORMNAME_TASK_CLASS;
            return NULL;
        }

        s_clsgetGraphIOSTask = loadClass(env, GETGRAPHIOS_TASK_CLASS);
        if (!s_clsgetGraphIOSTask) return 0;
        s_midgetGraphIOSTask = env->GetMethodID(s_clsgetGraphIOSTask, "<init>",
                        "(Lcom/rho/htmltograph/IHtmlToGraph;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetGraphIOSTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETGRAPHIOS_TASK_CLASS;
            return NULL;
        }

        s_clsgetGraphAndroidTask = loadClass(env, GETGRAPHANDROID_TASK_CLASS);
        if (!s_clsgetGraphAndroidTask) return 0;
        s_midgetGraphAndroidTask = env->GetMethodID(s_clsgetGraphAndroidTask, "<init>",
                        "(Lcom/rho/htmltograph/IHtmlToGraph;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetGraphAndroidTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETGRAPHANDROID_TASK_CLASS;
            return NULL;
        }

        s_clscalcSummTask = loadClass(env, CALCSUMM_TASK_CLASS);
        if (!s_clscalcSummTask) return 0;
        s_midcalcSummTask = env->GetMethodID(s_clscalcSummTask, "<init>",
                        "(Lcom/rho/htmltograph/IHtmlToGraph;IILcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midcalcSummTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + CALCSUMM_TASK_CLASS;
            return NULL;
        }

        s_clsjoinStringsTask = loadClass(env, JOINSTRINGS_TASK_CLASS);
        if (!s_clsjoinStringsTask) return 0;
        s_midjoinStringsTask = env->GetMethodID(s_clsjoinStringsTask, "<init>",
                        "(Lcom/rho/htmltograph/IHtmlToGraph;Ljava/lang/String;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midjoinStringsTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + JOINSTRINGS_TASK_CLASS;
            return NULL;
        }

        s_clsgetPropertyTask = loadClass(env, GETPROPERTY_TASK_CLASS);
        if (!s_clsgetPropertyTask) return 0;
        s_midgetPropertyTask = env->GetMethodID(s_clsgetPropertyTask, "<init>",
                        "(Lcom/rho/htmltograph/IHtmlToGraph;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clsgetPropertiesTask = loadClass(env, GETPROPERTIES_TASK_CLASS);
        if (!s_clsgetPropertiesTask) return 0;
        s_midgetPropertiesTask = env->GetMethodID(s_clsgetPropertiesTask, "<init>",
                        "(Lcom/rho/htmltograph/IHtmlToGraph;Ljava/util/List;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPROPERTIES_TASK_CLASS;
            return NULL;
        }

        s_clsgetAllPropertiesTask = loadClass(env, GETALLPROPERTIES_TASK_CLASS);
        if (!s_clsgetAllPropertiesTask) return 0;
        s_midgetAllPropertiesTask = env->GetMethodID(s_clsgetAllPropertiesTask, "<init>",
                        "(Lcom/rho/htmltograph/IHtmlToGraph;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetAllPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETALLPROPERTIES_TASK_CLASS;
            return NULL;
        }

        s_clssetPropertyTask = loadClass(env, SETPROPERTY_TASK_CLASS);
        if (!s_clssetPropertyTask) return 0;
        s_midsetPropertyTask = env->GetMethodID(s_clssetPropertyTask, "<init>",
                        "(Lcom/rho/htmltograph/IHtmlToGraph;Ljava/lang/String;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clssetPropertiesTask = loadClass(env, SETPROPERTIES_TASK_CLASS);
        if (!s_clssetPropertiesTask) return 0;
        s_midsetPropertiesTask = env->GetMethodID(s_clssetPropertiesTask, "<init>",
                        "(Lcom/rho/htmltograph/IHtmlToGraph;Ljava/util/Map;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
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
        LOG(TRACE) + "CHtmlToGraph JNI init succeeded";
    }
    return env;
}
//----------------------------------------------------------------------------------------------------------------------

void CHtmlToGraphBase::setJavaFactory(JNIEnv* env, jobject jFactory)
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

rho::String CHtmlToGraphBase::getDefaultID()
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

void CHtmlToGraphBase::setDefaultID(const rho::String& id)
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

jobject CHtmlToGraphBase::getFactory(JNIEnv* env)
{
    jobject res = env->CallStaticObjectMethod(s_clsFactorySingleton, s_midFactoryGetInstance);
    return res;
}
//----------------------------------------------------------------------------------------------------------------------

jobject CHtmlToGraphBase::getSingleton(JNIEnv* env)
{
    jhobject jhFactory = getFactory(env);
    jobject res = env->CallObjectMethod(jhFactory.get(), s_midGetApiSingleton);
    return res;
}
//----------------------------------------------------------------------------------------------------------------------

jobject CHtmlToGraphBase::getObject(JNIEnv* env)
{
    jhstring jhId = rho_cast<jstring>(env, m_id);
    jhobject jhFactory = getFactory(env);
    jobject res = env->CallObjectMethod(jhFactory.get(), s_midGetApiObject, jhId.get());
    return res;
}
//----------------------------------------------------------------------------------------------------------------------


}
