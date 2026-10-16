#include "ruby.h"

static VALUE rb_api_mParent;
static VALUE rb_api_mPdfgen;

VALUE rb_Pdfgen_getSimpleStringProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Pdfgen_def_getSimpleStringProperty(int argc, VALUE *argv);
VALUE rb_Pdfgen_setSimpleStringProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Pdfgen_def_setSimpleStringProperty(int argc, VALUE *argv);
VALUE rb_s_Pdfgen_enumerate(int argc, VALUE *argv);
VALUE rb_Pdfgen_generateAndroidPDF(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Pdfgen_def_generateAndroidPDF(int argc, VALUE *argv);
VALUE rb_Pdfgen_generateAndroidPDFCharts(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Pdfgen_def_generateAndroidPDFCharts(int argc, VALUE *argv);
VALUE rb_Pdfgen_generateIOSPDF(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Pdfgen_def_generateIOSPDF(int argc, VALUE *argv);
VALUE rb_Pdfgen_mergeIOSPDF(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Pdfgen_def_mergeIOSPDF(int argc, VALUE *argv);
VALUE rb_Pdfgen_getProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Pdfgen_def_getProperty(int argc, VALUE *argv);
VALUE rb_Pdfgen_getProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Pdfgen_def_getProperties(int argc, VALUE *argv);
VALUE rb_Pdfgen_getAllProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Pdfgen_def_getAllProperties(int argc, VALUE *argv);
VALUE rb_Pdfgen_setProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Pdfgen_def_setProperty(int argc, VALUE *argv);
VALUE rb_Pdfgen_setProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_Pdfgen_def_setProperties(int argc, VALUE *argv);



VALUE rb_Pdfgen_s_default(VALUE klass);
VALUE rb_Pdfgen_s_setDefault(VALUE klass, VALUE obj);


VALUE getRuby_Pdfgen_Module(){ return rb_api_mPdfgen; }



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

void Init_RubyAPI_Pdfgen(void)
{

    VALUE tmpParent = Qnil;
    rb_api_mParent = rb_define_module("Rho");
    

	rb_api_mPdfgen = rb_define_class_under(rb_api_mParent, "Pdfgen", rb_cObject);

	rb_define_alloc_func(rb_api_mPdfgen, _allocate_class_object);
    //Constructor should be not available in case of static members
    //rb_undef_alloc_func(rb_api_mPdfgen);

    rb_define_method(rb_api_mPdfgen, "simpleStringProperty", rb_Pdfgen_getSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mPdfgen, "simpleStringProperty", rb_s_Pdfgen_def_getSimpleStringProperty, -1);
    rb_define_method(rb_api_mPdfgen, "simpleStringProperty=", rb_Pdfgen_setSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mPdfgen, "simpleStringProperty=", rb_s_Pdfgen_def_setSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mPdfgen, "enumerate", rb_s_Pdfgen_enumerate, -1);
    rb_define_method(rb_api_mPdfgen, "generateAndroidPDF", rb_Pdfgen_generateAndroidPDF, -1);
    rb_define_singleton_method(rb_api_mPdfgen, "generateAndroidPDF", rb_s_Pdfgen_def_generateAndroidPDF, -1);
    rb_define_method(rb_api_mPdfgen, "generateAndroidPDFCharts", rb_Pdfgen_generateAndroidPDFCharts, -1);
    rb_define_singleton_method(rb_api_mPdfgen, "generateAndroidPDFCharts", rb_s_Pdfgen_def_generateAndroidPDFCharts, -1);
    rb_define_method(rb_api_mPdfgen, "generateIOSPDF", rb_Pdfgen_generateIOSPDF, -1);
    rb_define_singleton_method(rb_api_mPdfgen, "generateIOSPDF", rb_s_Pdfgen_def_generateIOSPDF, -1);
    rb_define_method(rb_api_mPdfgen, "mergeIOSPDF", rb_Pdfgen_mergeIOSPDF, -1);
    rb_define_singleton_method(rb_api_mPdfgen, "mergeIOSPDF", rb_s_Pdfgen_def_mergeIOSPDF, -1);
    rb_define_method(rb_api_mPdfgen, "getProperty", rb_Pdfgen_getProperty, -1);
    rb_define_singleton_method(rb_api_mPdfgen, "getProperty", rb_s_Pdfgen_def_getProperty, -1);
    rb_define_method(rb_api_mPdfgen, "getProperties", rb_Pdfgen_getProperties, -1);
    rb_define_singleton_method(rb_api_mPdfgen, "getProperties", rb_s_Pdfgen_def_getProperties, -1);
    rb_define_method(rb_api_mPdfgen, "getAllProperties", rb_Pdfgen_getAllProperties, -1);
    rb_define_singleton_method(rb_api_mPdfgen, "getAllProperties", rb_s_Pdfgen_def_getAllProperties, -1);
    rb_define_method(rb_api_mPdfgen, "setProperty", rb_Pdfgen_setProperty, -1);
    rb_define_singleton_method(rb_api_mPdfgen, "setProperty", rb_s_Pdfgen_def_setProperty, -1);
    rb_define_method(rb_api_mPdfgen, "setProperties", rb_Pdfgen_setProperties, -1);
    rb_define_singleton_method(rb_api_mPdfgen, "setProperties", rb_s_Pdfgen_def_setProperties, -1);



    rb_define_singleton_method(rb_api_mPdfgen, "getDefault", rb_Pdfgen_s_default, 0);
    rb_define_singleton_method(rb_api_mPdfgen, "setDefault", rb_Pdfgen_s_setDefault, 1);






}

