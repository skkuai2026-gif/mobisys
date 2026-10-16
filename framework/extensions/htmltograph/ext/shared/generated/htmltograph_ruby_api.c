#include "ruby.h"

static VALUE rb_api_mParent;
static VALUE rb_api_mHtmlToGraph;

VALUE rb_HtmlToGraph_getSimpleStringProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_HtmlToGraph_def_getSimpleStringProperty(int argc, VALUE *argv);
VALUE rb_HtmlToGraph_setSimpleStringProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_HtmlToGraph_def_setSimpleStringProperty(int argc, VALUE *argv);
VALUE rb_s_HtmlToGraph_enumerate(int argc, VALUE *argv);
VALUE rb_HtmlToGraph_getPlatformName(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_HtmlToGraph_def_getPlatformName(int argc, VALUE *argv);
VALUE rb_HtmlToGraph_getGraphIOS(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_HtmlToGraph_def_getGraphIOS(int argc, VALUE *argv);
VALUE rb_HtmlToGraph_getGraphAndroid(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_HtmlToGraph_def_getGraphAndroid(int argc, VALUE *argv);
VALUE rb_HtmlToGraph_calcSumm(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_HtmlToGraph_def_calcSumm(int argc, VALUE *argv);
VALUE rb_HtmlToGraph_joinStrings(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_HtmlToGraph_def_joinStrings(int argc, VALUE *argv);
VALUE rb_HtmlToGraph_getProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_HtmlToGraph_def_getProperty(int argc, VALUE *argv);
VALUE rb_HtmlToGraph_getProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_HtmlToGraph_def_getProperties(int argc, VALUE *argv);
VALUE rb_HtmlToGraph_getAllProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_HtmlToGraph_def_getAllProperties(int argc, VALUE *argv);
VALUE rb_HtmlToGraph_setProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_HtmlToGraph_def_setProperty(int argc, VALUE *argv);
VALUE rb_HtmlToGraph_setProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_HtmlToGraph_def_setProperties(int argc, VALUE *argv);



VALUE rb_HtmlToGraph_s_default(VALUE klass);
VALUE rb_HtmlToGraph_s_setDefault(VALUE klass, VALUE obj);


VALUE getRuby_HtmlToGraph_Module(){ return rb_api_mHtmlToGraph; }



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

void Init_RubyAPI_HtmlToGraph(void)
{

    VALUE tmpParent = Qnil;
    rb_api_mParent = rb_define_module("Rho");
    

	rb_api_mHtmlToGraph = rb_define_class_under(rb_api_mParent, "HtmlToGraph", rb_cObject);

	rb_define_alloc_func(rb_api_mHtmlToGraph, _allocate_class_object);
    //Constructor should be not available in case of static members
    //rb_undef_alloc_func(rb_api_mHtmlToGraph);

    rb_define_method(rb_api_mHtmlToGraph, "simpleStringProperty", rb_HtmlToGraph_getSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mHtmlToGraph, "simpleStringProperty", rb_s_HtmlToGraph_def_getSimpleStringProperty, -1);
    rb_define_method(rb_api_mHtmlToGraph, "simpleStringProperty=", rb_HtmlToGraph_setSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mHtmlToGraph, "simpleStringProperty=", rb_s_HtmlToGraph_def_setSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mHtmlToGraph, "enumerate", rb_s_HtmlToGraph_enumerate, -1);
    rb_define_method(rb_api_mHtmlToGraph, "getPlatformName", rb_HtmlToGraph_getPlatformName, -1);
    rb_define_singleton_method(rb_api_mHtmlToGraph, "getPlatformName", rb_s_HtmlToGraph_def_getPlatformName, -1);
    rb_define_method(rb_api_mHtmlToGraph, "getGraphIOS", rb_HtmlToGraph_getGraphIOS, -1);
    rb_define_singleton_method(rb_api_mHtmlToGraph, "getGraphIOS", rb_s_HtmlToGraph_def_getGraphIOS, -1);
    rb_define_method(rb_api_mHtmlToGraph, "getGraphAndroid", rb_HtmlToGraph_getGraphAndroid, -1);
    rb_define_singleton_method(rb_api_mHtmlToGraph, "getGraphAndroid", rb_s_HtmlToGraph_def_getGraphAndroid, -1);
    rb_define_method(rb_api_mHtmlToGraph, "calcSumm", rb_HtmlToGraph_calcSumm, -1);
    rb_define_singleton_method(rb_api_mHtmlToGraph, "calcSumm", rb_s_HtmlToGraph_def_calcSumm, -1);
    rb_define_method(rb_api_mHtmlToGraph, "joinStrings", rb_HtmlToGraph_joinStrings, -1);
    rb_define_singleton_method(rb_api_mHtmlToGraph, "joinStrings", rb_s_HtmlToGraph_def_joinStrings, -1);
    rb_define_method(rb_api_mHtmlToGraph, "getProperty", rb_HtmlToGraph_getProperty, -1);
    rb_define_singleton_method(rb_api_mHtmlToGraph, "getProperty", rb_s_HtmlToGraph_def_getProperty, -1);
    rb_define_method(rb_api_mHtmlToGraph, "getProperties", rb_HtmlToGraph_getProperties, -1);
    rb_define_singleton_method(rb_api_mHtmlToGraph, "getProperties", rb_s_HtmlToGraph_def_getProperties, -1);
    rb_define_method(rb_api_mHtmlToGraph, "getAllProperties", rb_HtmlToGraph_getAllProperties, -1);
    rb_define_singleton_method(rb_api_mHtmlToGraph, "getAllProperties", rb_s_HtmlToGraph_def_getAllProperties, -1);
    rb_define_method(rb_api_mHtmlToGraph, "setProperty", rb_HtmlToGraph_setProperty, -1);
    rb_define_singleton_method(rb_api_mHtmlToGraph, "setProperty", rb_s_HtmlToGraph_def_setProperty, -1);
    rb_define_method(rb_api_mHtmlToGraph, "setProperties", rb_HtmlToGraph_setProperties, -1);
    rb_define_singleton_method(rb_api_mHtmlToGraph, "setProperties", rb_s_HtmlToGraph_def_setProperties, -1);



    rb_define_singleton_method(rb_api_mHtmlToGraph, "getDefault", rb_HtmlToGraph_s_default, 0);
    rb_define_singleton_method(rb_api_mHtmlToGraph, "setDefault", rb_HtmlToGraph_s_setDefault, 1);






}

