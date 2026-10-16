#include "rhodes.h"
#include "Pdfgen.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "Pdfgen_impl"

#define PDFGEN_FACTORY_CLASS "com.rho.pdfgen.PdfgenFactory"

extern "C" void Init_Pdfgen_API(void);

extern "C" void Init_Pdfgen(void)
{
    RAWTRACE(__FUNCTION__);

    JNIEnv *env = jnienv();
    if(env)
    {
        jclass cls = rho_find_class(env, PDFGEN_FACTORY_CLASS);
        if(!cls)
        {
            RAWLOG_ERROR1("Failed to find java class: %s", PDFGEN_FACTORY_CLASS);
            return;
        }
        jmethodID midFactory = env->GetMethodID(cls, "<init>", "()V");
        if(!midFactory)
        {
            RAWLOG_ERROR1("Failed to get constructor for java class %s", PDFGEN_FACTORY_CLASS);
            return;
        }
        jobject jFactory = env->NewObject(cls, midFactory);
        if(env->IsSameObject(jFactory, NULL))
        {
            RAWLOG_ERROR1("Failed to create %s instance", PDFGEN_FACTORY_CLASS);
            return;
        }
        
        RAWTRACE("Initializing Java factory");

        rho::CPdfgenBase::setJavaFactory(env, jFactory);

        RAWTRACE("Deleting JNI reference");

        env->DeleteLocalRef(jFactory);

        RAWTRACE("Initializing API");

        Init_Pdfgen_API();

        RAWTRACE("Init_Pdfgen succeeded");
    }
    else
    {
        RAWLOG_ERROR("Failed to initialize Pdfgen API: jnienv() is failed");
    }

}

extern "C" void Init_Pdfgen_extension() {
    Init_Pdfgen();
}
