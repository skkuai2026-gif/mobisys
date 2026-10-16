#include "ruby.h"

static VALUE rb_api_mParent;
static VALUE rb_api_mApptracking;

VALUE rb_Apptracking_getSimpleStringProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Apptracking_def_getSimpleStringProperty(int argc, VALUE *argv);
VALUE rb_Apptracking_setSimpleStringProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Apptracking_def_setSimpleStringProperty(int argc, VALUE *argv);
VALUE rb_s_Apptracking_enumerate(int argc, VALUE *argv);
VALUE rb_Apptracking_requestAppTrackingPermission(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Apptracking_def_requestAppTrackingPermission(int argc, VALUE *argv);
VALUE rb_Apptracking_getProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Apptracking_def_getProperty(int argc, VALUE *argv);
VALUE rb_Apptracking_getProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Apptracking_def_getProperties(int argc, VALUE *argv);
VALUE rb_Apptracking_getAllProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Apptracking_def_getAllProperties(int argc, VALUE *argv);
VALUE rb_Apptracking_setProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Apptracking_def_setProperty(int argc, VALUE *argv);
VALUE rb_Apptracking_setProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Apptracking_def_setProperties(int argc, VALUE *argv);



VALUE rb_Apptracking_s_default(VALUE klass);
VALUE rb_Apptracking_s_setDefault(VALUE klass, VALUE obj);


VALUE getRuby_Apptracking_Module(){ return rb_api_mApptracking; }



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

void Init_RubyAPI_Apptracking(void)
{

    VALUE tmpParent = Qnil;
    rb_api_mParent = rb_define_module("Rho");
    

	rb_api_mApptracking = rb_define_class_under(rb_api_mParent, "Apptracking", rb_cObject);

	rb_define_alloc_func(rb_api_mApptracking, _allocate_class_object);
    //Constructor should be not available in case of static members
    //rb_undef_alloc_func(rb_api_mApptracking);

    rb_define_method(rb_api_mApptracking, "simpleStringProperty", rb_Apptracking_getSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mApptracking, "simpleStringProperty", rb_s_Apptracking_def_getSimpleStringProperty, -1);
    rb_define_method(rb_api_mApptracking, "simpleStringProperty=", rb_Apptracking_setSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mApptracking, "simpleStringProperty=", rb_s_Apptracking_def_setSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mApptracking, "enumerate", rb_s_Apptracking_enumerate, -1);
    rb_define_method(rb_api_mApptracking, "requestAppTrackingPermission", rb_Apptracking_requestAppTrackingPermission, -1);
    rb_define_singleton_method(rb_api_mApptracking, "requestAppTrackingPermission", rb_s_Apptracking_def_requestAppTrackingPermission, -1);
    rb_define_method(rb_api_mApptracking, "getProperty", rb_Apptracking_getProperty, -1);
    rb_define_singleton_method(rb_api_mApptracking, "getProperty", rb_s_Apptracking_def_getProperty, -1);
    rb_define_method(rb_api_mApptracking, "getProperties", rb_Apptracking_getProperties, -1);
    rb_define_singleton_method(rb_api_mApptracking, "getProperties", rb_s_Apptracking_def_getProperties, -1);
    rb_define_method(rb_api_mApptracking, "getAllProperties", rb_Apptracking_getAllProperties, -1);
    rb_define_singleton_method(rb_api_mApptracking, "getAllProperties", rb_s_Apptracking_def_getAllProperties, -1);
    rb_define_method(rb_api_mApptracking, "setProperty", rb_Apptracking_setProperty, -1);
    rb_define_singleton_method(rb_api_mApptracking, "setProperty", rb_s_Apptracking_def_setProperty, -1);
    rb_define_method(rb_api_mApptracking, "setProperties", rb_Apptracking_setProperties, -1);
    rb_define_singleton_method(rb_api_mApptracking, "setProperties", rb_s_Apptracking_def_setProperties, -1);



    rb_define_singleton_method(rb_api_mApptracking, "getDefault", rb_Apptracking_s_default, 0);
    rb_define_singleton_method(rb_api_mApptracking, "setDefault", rb_Apptracking_s_setDefault, 1);






}

