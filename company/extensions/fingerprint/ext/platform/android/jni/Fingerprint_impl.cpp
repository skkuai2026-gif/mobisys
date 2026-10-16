#include "rhodes.h"
#include "Fingerprint.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "Fingerprint_impl"

#define FINGERPRINT_FACTORY_CLASS "com.rho.fingerprint.FingerprintFactory"

extern "C" void Init_Fingerprint_API(void);

extern "C" void Init_Fingerprint(void)
{
    RAWTRACE(__FUNCTION__);

    JNIEnv *env = jnienv();
    if(env)
    {
        jclass cls = rho_find_class(env, FINGERPRINT_FACTORY_CLASS);
        if(!cls)
        {
            RAWLOG_ERROR1("Failed to find java class: %s", FINGERPRINT_FACTORY_CLASS);
            return;
        }
        jmethodID midFactory = env->GetMethodID(cls, "<init>", "()V");
        if(!midFactory)
        {
            RAWLOG_ERROR1("Failed to get constructor for java class %s", FINGERPRINT_FACTORY_CLASS);
            return;
        }
        jobject jFactory = env->NewObject(cls, midFactory);
        if(env->IsSameObject(jFactory, NULL))
        {
            RAWLOG_ERROR1("Failed to create %s instance", FINGERPRINT_FACTORY_CLASS);
            return;
        }
        
        RAWTRACE("Initializing Java factory");

        rho::CFingerprintBase::setJavaFactory(env, jFactory);

        RAWTRACE("Deleting JNI reference");

        env->DeleteLocalRef(jFactory);

        RAWTRACE("Initializing API");

        Init_Fingerprint_API();

        RAWTRACE("Init_Fingerprint succeeded");
    }
    else
    {
        RAWLOG_ERROR("Failed to initialize Fingerprint API: jnienv() is failed");
    }

}

extern "C" void Init_Fingerprint_extension() {
    Init_Fingerprint();
}
