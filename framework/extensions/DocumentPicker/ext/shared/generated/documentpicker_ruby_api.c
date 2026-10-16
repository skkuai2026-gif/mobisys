#include "ruby.h"

static VALUE rb_api_mParent;
static VALUE rb_api_mDocumentPicker;

VALUE rb_DocumentPicker_getSimpleStringProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_DocumentPicker_def_getSimpleStringProperty(int argc, VALUE *argv);
VALUE rb_DocumentPicker_setSimpleStringProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_DocumentPicker_def_setSimpleStringProperty(int argc, VALUE *argv);
VALUE rb_s_DocumentPicker_enumerate(int argc, VALUE *argv);
VALUE rb_DocumentPicker_pickDocument(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_DocumentPicker_def_pickDocument(int argc, VALUE *argv);
VALUE rb_DocumentPicker_getProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_DocumentPicker_def_getProperty(int argc, VALUE *argv);
VALUE rb_DocumentPicker_getProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_DocumentPicker_def_getProperties(int argc, VALUE *argv);
VALUE rb_DocumentPicker_getAllProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_DocumentPicker_def_getAllProperties(int argc, VALUE *argv);
VALUE rb_DocumentPicker_setProperty(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_DocumentPicker_def_setProperty(int argc, VALUE *argv);
VALUE rb_DocumentPicker_setProperties(int argc, VALUE *argv, VALUE obj);
VALUE rb_s_DocumentPicker_def_setProperties(int argc, VALUE *argv);



VALUE rb_DocumentPicker_s_default(VALUE klass);
VALUE rb_DocumentPicker_s_setDefault(VALUE klass, VALUE obj);


VALUE getRuby_DocumentPicker_Module(){ return rb_api_mDocumentPicker; }



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

void Init_RubyAPI_DocumentPicker(void)
{

    VALUE tmpParent = Qnil;
    rb_api_mParent = rb_define_module("Rho");
    

	rb_api_mDocumentPicker = rb_define_class_under(rb_api_mParent, "DocumentPicker", rb_cObject);

	rb_define_alloc_func(rb_api_mDocumentPicker, _allocate_class_object);
    //Constructor should be not available in case of static members
    //rb_undef_alloc_func(rb_api_mDocumentPicker);

    rb_define_method(rb_api_mDocumentPicker, "simpleStringProperty", rb_DocumentPicker_getSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mDocumentPicker, "simpleStringProperty", rb_s_DocumentPicker_def_getSimpleStringProperty, -1);
    rb_define_method(rb_api_mDocumentPicker, "simpleStringProperty=", rb_DocumentPicker_setSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mDocumentPicker, "simpleStringProperty=", rb_s_DocumentPicker_def_setSimpleStringProperty, -1);
    rb_define_singleton_method(rb_api_mDocumentPicker, "enumerate", rb_s_DocumentPicker_enumerate, -1);
    rb_define_method(rb_api_mDocumentPicker, "pickDocument", rb_DocumentPicker_pickDocument, -1);
    rb_define_singleton_method(rb_api_mDocumentPicker, "pickDocument", rb_s_DocumentPicker_def_pickDocument, -1);
    rb_define_method(rb_api_mDocumentPicker, "getProperty", rb_DocumentPicker_getProperty, -1);
    rb_define_singleton_method(rb_api_mDocumentPicker, "getProperty", rb_s_DocumentPicker_def_getProperty, -1);
    rb_define_method(rb_api_mDocumentPicker, "getProperties", rb_DocumentPicker_getProperties, -1);
    rb_define_singleton_method(rb_api_mDocumentPicker, "getProperties", rb_s_DocumentPicker_def_getProperties, -1);
    rb_define_method(rb_api_mDocumentPicker, "getAllProperties", rb_DocumentPicker_getAllProperties, -1);
    rb_define_singleton_method(rb_api_mDocumentPicker, "getAllProperties", rb_s_DocumentPicker_def_getAllProperties, -1);
    rb_define_method(rb_api_mDocumentPicker, "setProperty", rb_DocumentPicker_setProperty, -1);
    rb_define_singleton_method(rb_api_mDocumentPicker, "setProperty", rb_s_DocumentPicker_def_setProperty, -1);
    rb_define_method(rb_api_mDocumentPicker, "setProperties", rb_DocumentPicker_setProperties, -1);
    rb_define_singleton_method(rb_api_mDocumentPicker, "setProperties", rb_s_DocumentPicker_def_setProperties, -1);



    rb_define_singleton_method(rb_api_mDocumentPicker, "getDefault", rb_DocumentPicker_s_default, 0);
    rb_define_singleton_method(rb_api_mDocumentPicker, "setDefault", rb_DocumentPicker_s_setDefault, 1);






}

