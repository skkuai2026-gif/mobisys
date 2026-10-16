#include "rhodes.h"
#include "Bmp.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "Bmp_impl"

#define BMP_FACTORY_CLASS "com.rho.bmp.BmpFactory"

extern "C" void Init_Bmp_API(void);

extern "C" void Init_Bmp(void)
{
    RAWTRACE(__FUNCTION__);

    JNIEnv *env = jnienv();
    if(env)
    {
        jclass cls = rho_find_class(env, BMP_FACTORY_CLASS);
        if(!cls)
        {
            RAWLOG_ERROR1("Failed to find java class: %s", BMP_FACTORY_CLASS);
            return;
        }
        jmethodID midFactory = env->GetMethodID(cls, "<init>", "()V");
        if(!midFactory)
        {
            RAWLOG_ERROR1("Failed to get constructor for java class %s", BMP_FACTORY_CLASS);
            return;
        }
        jobject jFactory = env->NewObject(cls, midFactory);
        if(env->IsSameObject(jFactory, NULL))
        {
            RAWLOG_ERROR1("Failed to create %s instance", BMP_FACTORY_CLASS);
            return;
        }
        
        RAWTRACE("Initializing Java factory");

        rho::CBmpBase::setJavaFactory(env, jFactory);

        RAWTRACE("Deleting JNI reference");

        env->DeleteLocalRef(jFactory);

        RAWTRACE("Initializing API");

        Init_Bmp_API();

        RAWTRACE("Init_Bmp succeeded");
    }
    else
    {
        RAWLOG_ERROR("Failed to initialize Bmp API: jnienv() is failed");
    }

}

extern "C" void Init_Bmp_extension() {
    Init_Bmp();
}
