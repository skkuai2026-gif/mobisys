#include "rhodes.h"
#include "BGService.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "BGService_impl"

#define BGSERVICE_FACTORY_CLASS "com.rho.bgservice.BGServiceFactory"

extern "C" void Init_BGService_API(void);

extern "C" void Init_BGService(void)
{
    RAWTRACE(__FUNCTION__);

    JNIEnv *env = jnienv();
    if(env)
    {
        jclass cls = rho_find_class(env, BGSERVICE_FACTORY_CLASS);
        if(!cls)
        {
            RAWLOG_ERROR1("Failed to find java class: %s", BGSERVICE_FACTORY_CLASS);
            return;
        }
        jmethodID midFactory = env->GetMethodID(cls, "<init>", "()V");
        if(!midFactory)
        {
            RAWLOG_ERROR1("Failed to get constructor for java class %s", BGSERVICE_FACTORY_CLASS);
            return;
        }
        jobject jFactory = env->NewObject(cls, midFactory);
        if(env->IsSameObject(jFactory, NULL))
        {
            RAWLOG_ERROR1("Failed to create %s instance", BGSERVICE_FACTORY_CLASS);
            return;
        }
        
        RAWTRACE("Initializing Java factory");

        rho::CBGServiceBase::setJavaFactory(env, jFactory);

        RAWTRACE("Deleting JNI reference");

        env->DeleteLocalRef(jFactory);

        RAWTRACE("Initializing API");

        Init_BGService_API();

        RAWTRACE("Init_BGService succeeded");
    }
    else
    {
        RAWLOG_ERROR("Failed to initialize BGService API: jnienv() is failed");
    }

}

extern "C" void Init_BGService_extension() {
    Init_BGService();
}
