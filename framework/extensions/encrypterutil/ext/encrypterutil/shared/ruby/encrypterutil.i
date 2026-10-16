/* encrypterutil.i */
%module EncrypterUtil
%{
#include "ruby/ext/rho/rhoruby.h"

extern VALUE encrypterutil_native_encrypt(const char* str);
extern VALUE encrypterutil_native_decrypt(const char* str);
extern int encrypterutil_calc_summ(int x, int y);

#define native_encrypt encrypterutil_native_encrypt 
#define native_decrypt encrypterutil_native_decrypt
#define calc_summ encrypterutil_calc_summ 

%}

extern VALUE native_encrypt(const char* str);
extern VALUE native_decrypt(const char* str);
extern int calc_summ(int x, int y);
