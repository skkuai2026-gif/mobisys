#include "ruby.h"

static VALUE rb_api_mParent;
static VALUE rb_api_mBGService;

VALUE rb_BGService_getSimpleStringProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_BGService_def_getSimpleStringProperty(int argc, VALUE *argv);
VALUE rb_BGService_setSimpleStringProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_BGService_def_setSimpleStringProperty(int argc, VALUE *argv);
VALUE rb_s_BGService_enumerate(int argc, VALUE *argv);
VALUE rb_BGService_startBackgroundService(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_BGService_def_startBackgroundService(int argc, VALUE *argv);
VALUE rb_BGService_stopBackgroundService(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_BGService_def_stopBackgroundService(int argc, VALUE *argv);
VALUE rb_BGService_checkBackgroundServiceStatus(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_BGService_def_checkBackgroundServiceStatus(int argc, VALUE *argv);
VALUE rb_BGService_getProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_BGService_def_getProperty(int argc, VALUE *argv);
VALUE rb_BGService_getProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_BGService_def_getProperties(int argc, VALUE *argv);
VALUE rb_BGService_getAllProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_BGService_def_getAllProperties(int argc, VALUE *argv);
VALUE rb_BGService_setProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_BGService_def_setProperty(int argc, VALUE *argv);
VALUE rb_BGService_setProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_BGService_def_setProperties(int argc, VALUE *argv);



VALUE rb_BGService_s_default(VALUE klass);
VALUE rb_BGService_s_setDefault(VALUE klass, VALUE obj);


VALUE getRuby_BGService_Module(){ return rb_api_mBGService; }



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

void Init_RubyAPI_BGService(void)
{

    VALUE tmpParent = Qnil;
    rb_api_mParent = rb_define_module("Rho");
    

	rb_api_mBGService = rb_define_class_under(rb_api_mParent, "BGService", rb_cObject);

	rb_define_alloc_func(rb_api_mBGService, _allocate_class_object);
    //Constructor should be not available in case of static members
    //rb_undef_alloc_func(rb_api_mBGService);

    rb_define_method(rb_api_mBGService, "simpleStringProperty", rb_BGService_getSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mBGService, "simpleStringProperty", rb_s_BGService_def_getSimpleStringProperty, -1);
    rb_define_method(rb_api_mBGService, "simpleStringProperty=", rb_BGService_setSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mBGService, "simpleStringProperty=", rb_s_BGService_def_setSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mBGService, "enumerate", rb_s_BGService_enumerate, -1);
    rb_define_method(rb_api_mBGService, "startBackgroundService", rb_BGService_startBackgroundService, -1);
    rb_define_singleton_method(rb_api_mBGService, "startBackgroundService", rb_s_BGService_def_startBackgroundService, -1);
    rb_define_method(rb_api_mBGService, "stopBackgroundService", rb_BGService_stopBackgroundService, -1);
    rb_define_singleton_method(rb_api_mBGService, "stopBackgroundService", rb_s_BGService_def_stopBackgroundService, -1);
    rb_define_method(rb_api_mBGService, "checkBackgroundServiceStatus", rb_BGService_checkBackgroundServiceStatus, -1);
    rb_define_singleton_method(rb_api_mBGService, "checkBackgroundServiceStatus", rb_s_BGService_def_checkBackgroundServiceStatus, -1);
    rb_define_method(rb_api_mBGService, "getProperty", rb_BGService_getProperty, -1);
    rb_define_singleton_method(rb_api_mBGService, "getProperty", rb_s_BGService_def_getProperty, -1);
    rb_define_method(rb_api_mBGService, "getProperties", rb_BGService_getProperties, -1);
    rb_define_singleton_method(rb_api_mBGService, "getProperties", rb_s_BGService_def_getProperties, -1);
    rb_define_method(rb_api_mBGService, "getAllProperties", rb_BGService_getAllProperties, -1);
    rb_define_singleton_method(rb_api_mBGService, "getAllProperties", rb_s_BGService_def_getAllProperties, -1);
    rb_define_method(rb_api_mBGService, "setProperty", rb_BGService_setProperty, -1);
    rb_define_singleton_method(rb_api_mBGService, "setProperty", rb_s_BGService_def_setProperty, -1);
    rb_define_method(rb_api_mBGService, "setProperties", rb_BGService_setProperties, -1);
    rb_define_singleton_method(rb_api_mBGService, "setProperties", rb_s_BGService_def_setProperties, -1);



    rb_define_singleton_method(rb_api_mBGService, "getDefault", rb_BGService_s_default, 0);
    rb_define_singleton_method(rb_api_mBGService, "setDefault", rb_BGService_s_setDefault, 1);






}

