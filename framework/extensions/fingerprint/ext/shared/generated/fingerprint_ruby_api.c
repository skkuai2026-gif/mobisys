#include "ruby.h"

static VALUE rb_api_mParent;
static VALUE rb_api_mFingerprint;

VALUE rb_Fingerprint_getSimpleStringProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Fingerprint_def_getSimpleStringProperty(int argc, VALUE *argv);
VALUE rb_Fingerprint_setSimpleStringProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Fingerprint_def_setSimpleStringProperty(int argc, VALUE *argv);
VALUE rb_s_Fingerprint_enumerate(int argc, VALUE *argv);
VALUE rb_Fingerprint_enableFingerprintScan(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Fingerprint_def_enableFingerprintScan(int argc, VALUE *argv);
VALUE rb_Fingerprint_getProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Fingerprint_def_getProperty(int argc, VALUE *argv);
VALUE rb_Fingerprint_getProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Fingerprint_def_getProperties(int argc, VALUE *argv);
VALUE rb_Fingerprint_getAllProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Fingerprint_def_getAllProperties(int argc, VALUE *argv);
VALUE rb_Fingerprint_setProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Fingerprint_def_setProperty(int argc, VALUE *argv);
VALUE rb_Fingerprint_setProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Fingerprint_def_setProperties(int argc, VALUE *argv);



VALUE rb_Fingerprint_s_default(VALUE klass);
VALUE rb_Fingerprint_s_setDefault(VALUE klass, VALUE obj);


VALUE getRuby_Fingerprint_Module(){ return rb_api_mFingerprint; }



static void _free_class_object(void *p)
{
    ruby_xfree(p);
}

static VALUE _allocate_class_object(VALUE klass)
{
    VALUE valObj = 0;
    char ** ppString = NULL;
    void* pData = ALLOC(void*);
    memset( pData, 0, sizeof(pData) );
    
	valObj = Data_Wrap_Struct(klass, 0, _free_class_object, pData);

    Data_Get_Struct(valObj, char *, ppString);
    *ppString = xmalloc(10);
    sprintf(*ppString, "%X", valObj);

    return valObj;
}

void Init_RubyAPI_Fingerprint(void)
{

    VALUE tmpParent = Qnil;
    rb_api_mParent = rb_define_module("Rho");
    

	rb_api_mFingerprint = rb_define_class_under(rb_api_mParent, "Fingerprint", rb_cObject);

	rb_define_alloc_func(rb_api_mFingerprint, _allocate_class_object);
    //Constructor should be not available in case of static members
    //rb_undef_alloc_func(rb_api_mFingerprint);

    rb_define_method(rb_api_mFingerprint, "simpleStringProperty", rb_Fingerprint_getSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mFingerprint, "simpleStringProperty", rb_s_Fingerprint_def_getSimpleStringProperty, -1);
    rb_define_method(rb_api_mFingerprint, "simpleStringProperty=", rb_Fingerprint_setSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mFingerprint, "simpleStringProperty=", rb_s_Fingerprint_def_setSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mFingerprint, "enumerate", rb_s_Fingerprint_enumerate, -1);
    rb_define_method(rb_api_mFingerprint, "enableFingerprintScan", rb_Fingerprint_enableFingerprintScan, -1);
    rb_define_singleton_method(rb_api_mFingerprint, "enableFingerprintScan", rb_s_Fingerprint_def_enableFingerprintScan, -1);
    rb_define_method(rb_api_mFingerprint, "getProperty", rb_Fingerprint_getProperty, -1);
    rb_define_singleton_method(rb_api_mFingerprint, "getProperty", rb_s_Fingerprint_def_getProperty, -1);
    rb_define_method(rb_api_mFingerprint, "getProperties", rb_Fingerprint_getProperties, -1);
    rb_define_singleton_method(rb_api_mFingerprint, "getProperties", rb_s_Fingerprint_def_getProperties, -1);
    rb_define_method(rb_api_mFingerprint, "getAllProperties", rb_Fingerprint_getAllProperties, -1);
    rb_define_singleton_method(rb_api_mFingerprint, "getAllProperties", rb_s_Fingerprint_def_getAllProperties, -1);
    rb_define_method(rb_api_mFingerprint, "setProperty", rb_Fingerprint_setProperty, -1);
    rb_define_singleton_method(rb_api_mFingerprint, "setProperty", rb_s_Fingerprint_def_setProperty, -1);
    rb_define_method(rb_api_mFingerprint, "setProperties", rb_Fingerprint_setProperties, -1);
    rb_define_singleton_method(rb_api_mFingerprint, "setProperties", rb_s_Fingerprint_def_setProperties, -1);



    rb_define_singleton_method(rb_api_mFingerprint, "getDefault", rb_Fingerprint_s_default, 0);
    rb_define_singleton_method(rb_api_mFingerprint, "setDefault", rb_Fingerprint_s_setDefault, 1);






}

