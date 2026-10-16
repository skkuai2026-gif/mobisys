#include "rhodes.h"
#include "Apptracking.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "Apptracking_impl"

#define APPTRACKING_FACTORY_CLASS "com.rho.apptracking.ApptrackingFactory"

extern "C" void Init_Apptracking_API(void);

extern "C" void Init_Apptracking(void)
{
    RAWTRACE(__FUNCTION__);

    JNIEnv *env = jnienv();
    if(env)
    {
        jclass cls = rho_find_class(env, APPTRACKING_FACTORY_CLASS);
        if(!cls)
        {
            RAWLOG_ERROR1("Failed to find java class: %s", APPTRACKING_FACTORY_CLASS);
            return;
        }
        jmethodID midFactory = env->GetMethodID(cls, "<init>", "()V");
        if(!midFactory)
        {
            RAWLOG_ERROR1("Failed to get constructor for java class %s", APPTRACKING_FACTORY_CLASS);
            return;
        }
        jobject jFactory = env->NewObject(cls, midFactory);
        if(env->IsSameObject(jFactory, NULL))
        {
            RAWLOG_ERROR1("Failed to create %s instance", APPTRACKING_FACTORY_CLASS);
            return;
        }
        
        RAWTRACE("Initializing Java factory");

        rho::CApptrackingBase::setJavaFactory(env, jFactory);

        RAWTRACE("Deleting JNI reference");

        env->DeleteLocalRef(jFactory);

        RAWTRACE("Initializing API");

        Init_Apptracking_API();

        RAWTRACE("Init_Apptracking succeeded");
    }
    else
    {
        RAWLOG_ERROR("Failed to initialize Apptracking API: jnienv() is failed");
    }

}

extern "C" void Init_Apptracking_extension() {
    Init_Apptracking();
}
