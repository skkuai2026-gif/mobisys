#include "Pdfgen.h"


namespace rho {

IMPLEMENT_LOGCLASS(CPdfgenBase, "PdfgenJNI");

//PdfgenFactorySingleton staff
const char* const CPdfgenBase::FACTORY_SINGLETON_CLASS = "com.rho.pdfgen.PdfgenFactorySingleton";
jclass CPdfgenBase::s_clsFactorySingleton = 0;
jmethodID CPdfgenBase::s_midFactorySetInstance;
jmethodID CPdfgenBase::s_midFactoryGetInstance;

//PdfgenFactory staff
const char* const CPdfgenBase::IFACTORY_CLASS = "com.rho.pdfgen.IPdfgenFactory";
jclass CPdfgenBase::s_clsIFactory = 0;
jmethodID CPdfgenBase::s_midGetApiSingleton;
jmethodID CPdfgenBase::s_midGetApiObject;

//PdfgenSingletonBase staff
const char* const CPdfgenBase::SINGLETON_BASE_CLASS = "com.rho.pdfgen.PdfgenSingletonBase";
jclass CPdfgenBase::s_clsSingletonBase = 0;

//PdfgenBase staff
const char* const CPdfgenBase::OBJECT_BASE_CLASS = "com.rho.pdfgen.PdfgenBase";
jclass CPdfgenBase::s_clsObjectBase = 0;


//IRhoApiDefaultId staff
const char* const CPdfgenBase::IDEFAULTID_CLASS = "com.rhomobile.rhodes.api.IRhoApiDefaultId";
jclass CPdfgenBase::s_clsIDefaultId = 0;
jmethodID CPdfgenBase::s_midGetDefaultID;
jmethodID CPdfgenBase::s_midSetDefaultID;


//Method tasks

const char* const CPdfgenBase::GETSIMPLESTRINGPROPERTY_TASK_CLASS = 
        "com.rho.pdfgen.PdfgenBase$getSimpleStringPropertyTask";

jclass CPdfgenBase::s_clsgetSimpleStringPropertyTask = 0;
jmethodID CPdfgenBase::s_midgetSimpleStringPropertyTask;

const char* const CPdfgenBase::SETSIMPLESTRINGPROPERTY_TASK_CLASS = 
        "com.rho.pdfgen.PdfgenBase$setSimpleStringPropertyTask";

jclass CPdfgenBase::s_clssetSimpleStringPropertyTask = 0;
jmethodID CPdfgenBase::s_midsetSimpleStringPropertyTask;

const char* const CPdfgenBase::ENUMERATE_TASK_CLASS = 
        "com.rho.pdfgen.PdfgenSingletonBase$enumerateTask";

jclass CPdfgenBase::s_clsenumerateTask = 0;
jmethodID CPdfgenBase::s_midenumerateTask;

const char* const CPdfgenBase::GENERATEANDROIDPDF_TASK_CLASS = 
        "com.rho.pdfgen.PdfgenBase$generateAndroidPDFTask";

jclass CPdfgenBase::s_clsgenerateAndroidPDFTask = 0;
jmethodID CPdfgenBase::s_midgenerateAndroidPDFTask;

const char* const CPdfgenBase::GENERATEANDROIDPDFCHARTS_TASK_CLASS = 
        "com.rho.pdfgen.PdfgenBase$generateAndroidPDFChartsTask";

jclass CPdfgenBase::s_clsgenerateAndroidPDFChartsTask = 0;
jmethodID CPdfgenBase::s_midgenerateAndroidPDFChartsTask;

const char* const CPdfgenBase::GENERATEIOSPDF_TASK_CLASS = 
        "com.rho.pdfgen.PdfgenBase$generateIOSPDFTask";

jclass CPdfgenBase::s_clsgenerateIOSPDFTask = 0;
jmethodID CPdfgenBase::s_midgenerateIOSPDFTask;

const char* const CPdfgenBase::MERGEIOSPDF_TASK_CLASS = 
        "com.rho.pdfgen.PdfgenBase$mergeIOSPDFTask";

jclass CPdfgenBase::s_clsmergeIOSPDFTask = 0;
jmethodID CPdfgenBase::s_midmergeIOSPDFTask;

const char* const CPdfgenBase::GETPROPERTY_TASK_CLASS = 
        "com.rho.pdfgen.PdfgenBase$getPropertyTask";

jclass CPdfgenBase::s_clsgetPropertyTask = 0;
jmethodID CPdfgenBase::s_midgetPropertyTask;

const char* const CPdfgenBase::GETPROPERTIES_TASK_CLASS = 
        "com.rho.pdfgen.PdfgenBase$getPropertiesTask";

jclass CPdfgenBase::s_clsgetPropertiesTask = 0;
jmethodID CPdfgenBase::s_midgetPropertiesTask;

const char* const CPdfgenBase::GETALLPROPERTIES_TASK_CLASS = 
        "com.rho.pdfgen.PdfgenBase$getAllPropertiesTask";

jclass CPdfgenBase::s_clsgetAllPropertiesTask = 0;
jmethodID CPdfgenBase::s_midgetAllPropertiesTask;

const char* const CPdfgenBase::SETPROPERTY_TASK_CLASS = 
        "com.rho.pdfgen.PdfgenBase$setPropertyTask";

jclass CPdfgenBase::s_clssetPropertyTask = 0;
jmethodID CPdfgenBase::s_midsetPropertyTask;

const char* const CPdfgenBase::SETPROPERTIES_TASK_CLASS = 
        "com.rho.pdfgen.PdfgenBase$setPropertiesTask";

jclass CPdfgenBase::s_clssetPropertiesTask = 0;
jmethodID CPdfgenBase::s_midsetPropertiesTask;


//----------------------------------------------------------------------------------------------------------------------

JNIEnv* CPdfgenBase::jniInit()
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

JNIEnv* CPdfgenBase::jniInit(JNIEnv* env)
{
    static bool initialized = false;
    env = MethodExecutorJni::jniInit(env);
    if (!env) {
        LOG(FATAL) + "JNI init failed";
        return 0;
    }

    if(!initialized)
    {
        //init PdfgenFactorySingleton JNI
        s_clsFactorySingleton = loadClass(env, FACTORY_SINGLETON_CLASS);
        if (!s_clsFactorySingleton) return 0;

        s_midFactorySetInstance = env->GetStaticMethodID(s_clsFactorySingleton, "setInstance", "(Lcom/rho/pdfgen/IPdfgenFactory;)V");
        if(!s_midFactorySetInstance)
        {
            LOG(FATAL) + "Failed to get method 'setInstance' for java class " + FACTORY_SINGLETON_CLASS;
            return NULL;
        }
        s_midFactoryGetInstance = env->GetStaticMethodID(s_clsFactorySingleton, "getInstance", "()Lcom/rho/pdfgen/IPdfgenFactory;");
        if(!s_midFactoryGetInstance)
        {
            LOG(FATAL) + "Failed to get method 'getInstance' for java class " + FACTORY_SINGLETON_CLASS;
            return NULL;
        }

        //init IPdfgenFactory JNI
        s_clsIFactory = loadClass(env, IFACTORY_CLASS);
        if (!s_clsIFactory) return 0;
        s_midGetApiSingleton = env->GetMethodID(s_clsIFactory, "getApiSingleton", "()Lcom/rho/pdfgen/IPdfgenSingleton;");
        if(!s_midGetApiSingleton)
        {
            LOG(FATAL) + "Failed to get method 'getApiSingleton' for java class " + IFACTORY_CLASS;
            return NULL;
        }
        s_midGetApiObject = env->GetMethodID(s_clsIFactory, "getApiObject", "(Ljava/lang/String;)Lcom/rho/pdfgen/IPdfgen;");
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
                        "(Lcom/rho/pdfgen/IPdfgen;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetSimpleStringPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETSIMPLESTRINGPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clssetSimpleStringPropertyTask = loadClass(env, SETSIMPLESTRINGPROPERTY_TASK_CLASS);
        if (!s_clssetSimpleStringPropertyTask) return 0;
        s_midsetSimpleStringPropertyTask = env->GetMethodID(s_clssetSimpleStringPropertyTask, "<init>",
                        "(Lcom/rho/pdfgen/IPdfgen;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetSimpleStringPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETSIMPLESTRINGPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clsenumerateTask = loadClass(env, ENUMERATE_TASK_CLASS);
        if (!s_clsenumerateTask) return 0;
        s_midenumerateTask = env->GetMethodID(s_clsenumerateTask, "<init>",
                        "(Lcom/rho/pdfgen/IPdfgenSingleton;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midenumerateTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + ENUMERATE_TASK_CLASS;
            return NULL;
        }

        s_clsgenerateAndroidPDFTask = loadClass(env, GENERATEANDROIDPDF_TASK_CLASS);
        if (!s_clsgenerateAndroidPDFTask) return 0;
        s_midgenerateAndroidPDFTask = env->GetMethodID(s_clsgenerateAndroidPDFTask, "<init>",
                        "(Lcom/rho/pdfgen/IPdfgen;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgenerateAndroidPDFTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GENERATEANDROIDPDF_TASK_CLASS;
            return NULL;
        }

        s_clsgenerateAndroidPDFChartsTask = loadClass(env, GENERATEANDROIDPDFCHARTS_TASK_CLASS);
        if (!s_clsgenerateAndroidPDFChartsTask) return 0;
        s_midgenerateAndroidPDFChartsTask = env->GetMethodID(s_clsgenerateAndroidPDFChartsTask, "<init>",
                        "(Lcom/rho/pdfgen/IPdfgen;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgenerateAndroidPDFChartsTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GENERATEANDROIDPDFCHARTS_TASK_CLASS;
            return NULL;
        }

        s_clsgenerateIOSPDFTask = loadClass(env, GENERATEIOSPDF_TASK_CLASS);
        if (!s_clsgenerateIOSPDFTask) return 0;
        s_midgenerateIOSPDFTask = env->GetMethodID(s_clsgenerateIOSPDFTask, "<init>",
                        "(Lcom/rho/pdfgen/IPdfgen;Ljava/lang/String;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgenerateIOSPDFTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GENERATEIOSPDF_TASK_CLASS;
            return NULL;
        }

        s_clsmergeIOSPDFTask = loadClass(env, MERGEIOSPDF_TASK_CLASS);
        if (!s_clsmergeIOSPDFTask) return 0;
        s_midmergeIOSPDFTask = env->GetMethodID(s_clsmergeIOSPDFTask, "<init>",
                        "(Lcom/rho/pdfgen/IPdfgen;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midmergeIOSPDFTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + MERGEIOSPDF_TASK_CLASS;
            return NULL;
        }

        s_clsgetPropertyTask = loadClass(env, GETPROPERTY_TASK_CLASS);
        if (!s_clsgetPropertyTask) return 0;
        s_midgetPropertyTask = env->GetMethodID(s_clsgetPropertyTask, "<init>",
                        "(Lcom/rho/pdfgen/IPdfgen;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clsgetPropertiesTask = loadClass(env, GETPROPERTIES_TASK_CLASS);
        if (!s_clsgetPropertiesTask) return 0;
        s_midgetPropertiesTask = env->GetMethodID(s_clsgetPropertiesTask, "<init>",
                        "(Lcom/rho/pdfgen/IPdfgen;Ljava/util/List;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETPROPERTIES_TASK_CLASS;
            return NULL;
        }

        s_clsgetAllPropertiesTask = loadClass(env, GETALLPROPERTIES_TASK_CLASS);
        if (!s_clsgetAllPropertiesTask) return 0;
        s_midgetAllPropertiesTask = env->GetMethodID(s_clsgetAllPropertiesTask, "<init>",
                        "(Lcom/rho/pdfgen/IPdfgen;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midgetAllPropertiesTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + GETALLPROPERTIES_TASK_CLASS;
            return NULL;
        }

        s_clssetPropertyTask = loadClass(env, SETPROPERTY_TASK_CLASS);
        if (!s_clssetPropertyTask) return 0;
        s_midsetPropertyTask = env->GetMethodID(s_clssetPropertyTask, "<init>",
                        "(Lcom/rho/pdfgen/IPdfgen;Ljava/lang/String;Ljava/lang/String;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
        if(!s_midsetPropertyTask)
        {
            LOG(FATAL) + "Failed to get constructor for java class " + SETPROPERTY_TASK_CLASS;
            return NULL;
        }

        s_clssetPropertiesTask = loadClass(env, SETPROPERTIES_TASK_CLASS);
        if (!s_clssetPropertiesTask) return 0;
        s_midsetPropertiesTask = env->GetMethodID(s_clssetPropertiesTask, "<init>",
                        "(Lcom/rho/pdfgen/IPdfgen;Ljava/util/Map;Lcom/rhomobile/rhodes/api/IMethodResult;)V");
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
        LOG(TRACE) + "CPdfgen JNI init succeeded";
    }
    return env;
}
//----------------------------------------------------------------------------------------------------------------------

void CPdfgenBase::setJavaFactory(JNIEnv* env, jobject jFactory)
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

rho::String CPdfgenBase::getDefaultID()
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

void CPdfgenBase::setDefaultID(const rho::String& id)
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

jobject CPdfgenBase::getFactory(JNIEnv* env)
{
    jobject res = env->CallStaticObjectMethod(s_clsFactorySingleton, s_midFactoryGetInstance);
    return res;
}
//----------------------------------------------------------------------------------------------------------------------

jobject CPdfgenBase::getSingleton(JNIEnv* env)
{
    jhobject jhFactory = getFactory(env);
    jobject res = env->CallObjectMethod(jhFactory.get(), s_midGetApiSingleton);
    return res;
}
//----------------------------------------------------------------------------------------------------------------------

jobject CPdfgenBase::getObject(JNIEnv* env)
{
    jhstring jhId = rho_cast<jstring>(env, m_id);
    jhobject jhFactory = getFactory(env);
    jobject res = env->CallObjectMethod(jhFactory.get(), s_midGetApiObject, jhId.get());
    return res;
}
//----------------------------------------------------------------------------------------------------------------------


}
