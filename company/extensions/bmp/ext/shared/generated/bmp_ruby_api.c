#include "ruby.h"

static VALUE rb_api_mParent;
static VALUE rb_api_mBmp;

VALUE rb_Bmp_getSimpleStringProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Bmp_def_getSimpleStringProperty(int argc, VALUE *argv);
VALUE rb_Bmp_setSimpleStringProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Bmp_def_setSimpleStringProperty(int argc, VALUE *argv);
VALUE rb_s_Bmp_enumerate(int argc, VALUE *argv);
VALUE rb_Bmp_sensorDataFetch(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Bmp_def_sensorDataFetch(int argc, VALUE *argv);
VALUE rb_Bmp_getProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Bmp_def_getProperty(int argc, VALUE *argv);
VALUE rb_Bmp_getProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Bmp_def_getProperties(int argc, VALUE *argv);
VALUE rb_Bmp_getAllProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Bmp_def_getAllProperties(int argc, VALUE *argv);
VALUE rb_Bmp_setProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Bmp_def_setProperty(int argc, VALUE *argv);
VALUE rb_Bmp_setProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Bmp_def_setProperties(int argc, VALUE *argv);



VALUE rb_Bmp_s_default(VALUE klass);
VALUE rb_Bmp_s_setDefault(VALUE klass, VALUE obj);


VALUE getRuby_Bmp_Module(){ return rb_api_mBmp; }



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

void Init_RubyAPI_Bmp(void)
{

    VALUE tmpParent = Qnil;
    rb_api_mParent = rb_define_module("Rho");
    

	rb_api_mBmp = rb_define_class_under(rb_api_mParent, "Bmp", rb_cObject);

	rb_define_alloc_func(rb_api_mBmp, _allocate_class_object);
    //Constructor should be not available in case of static members
    //rb_undef_alloc_func(rb_api_mBmp);

    rb_define_method(rb_api_mBmp, "simpleStringProperty", rb_Bmp_getSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mBmp, "simpleStringProperty", rb_s_Bmp_def_getSimpleStringProperty, -1);
    rb_define_method(rb_api_mBmp, "simpleStringProperty=", rb_Bmp_setSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mBmp, "simpleStringProperty=", rb_s_Bmp_def_setSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mBmp, "enumerate", rb_s_Bmp_enumerate, -1);
    rb_define_method(rb_api_mBmp, "sensorDataFetch", rb_Bmp_sensorDataFetch, -1);
    rb_define_singleton_method(rb_api_mBmp, "sensorDataFetch", rb_s_Bmp_def_sensorDataFetch, -1);
    rb_define_method(rb_api_mBmp, "getProperty", rb_Bmp_getProperty, -1);
    rb_define_singleton_method(rb_api_mBmp, "getProperty", rb_s_Bmp_def_getProperty, -1);
    rb_define_method(rb_api_mBmp, "getProperties", rb_Bmp_getProperties, -1);
    rb_define_singleton_method(rb_api_mBmp, "getProperties", rb_s_Bmp_def_getProperties, -1);
    rb_define_method(rb_api_mBmp, "getAllProperties", rb_Bmp_getAllProperties, -1);
    rb_define_singleton_method(rb_api_mBmp, "getAllProperties", rb_s_Bmp_def_getAllProperties, -1);
    rb_define_method(rb_api_mBmp, "setProperty", rb_Bmp_setProperty, -1);
    rb_define_singleton_method(rb_api_mBmp, "setProperty", rb_s_Bmp_def_setProperty, -1);
    rb_define_method(rb_api_mBmp, "setProperties", rb_Bmp_setProperties, -1);
    rb_define_singleton_method(rb_api_mBmp, "setProperties", rb_s_Bmp_def_setProperties, -1);



    rb_define_singleton_method(rb_api_mBmp, "getDefault", rb_Bmp_s_default, 0);
    rb_define_singleton_method(rb_api_mBmp, "setDefault", rb_Bmp_s_setDefault, 1);






}

