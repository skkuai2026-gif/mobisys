#include "rhodes.h"
#include "DocumentPicker.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "DocumentPicker_impl"

#define DOCUMENTPICKER_FACTORY_CLASS "com.rho.documentpicker.DocumentPickerFactory"

extern "C" void Init_DocumentPicker_API(void);

extern "C" void Init_DocumentPicker(void)
{
    RAWTRACE(__FUNCTION__);

    JNIEnv *env = jnienv();
    if(env)
    {
        jclass cls = rho_find_class(env, DOCUMENTPICKER_FACTORY_CLASS);
        if(!cls)
        {
            RAWLOG_ERROR1("Failed to find java class: %s", DOCUMENTPICKER_FACTORY_CLASS);
            return;
        }
        jmethodID midFactory = env->GetMethodID(cls, "<init>", "()V");
        if(!midFactory)
        {
            RAWLOG_ERROR1("Failed to get constructor for java class %s", DOCUMENTPICKER_FACTORY_CLASS);
            return;
        }
        jobject jFactory = env->NewObject(cls, midFactory);
        if(env->IsSameObject(jFactory, NULL))
        {
            RAWLOG_ERROR1("Failed to create %s instance", DOCUMENTPICKER_FACTORY_CLASS);
            return;
        }
        
        RAWTRACE("Initializing Java factory");

        rho::CDocumentPickerBase::setJavaFactory(env, jFactory);

        RAWTRACE("Deleting JNI reference");

        env->DeleteLocalRef(jFactory);

        RAWTRACE("Initializing API");

        Init_DocumentPicker_API();

        RAWTRACE("Init_DocumentPicker succeeded");
    }
    else
    {
        RAWLOG_ERROR("Failed to initialize DocumentPicker API: jnienv() is failed");
    }

}

extern "C" void Init_DocumentPicker_extension() {
    Init_DocumentPicker();
}
