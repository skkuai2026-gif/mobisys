#import <Foundation/Foundation.h>
#include "common/app_build_capabilities.h"

extern void Init_Pdfgen_API();

void Init_Pdfgen_extension()
{
    Init_Pdfgen_API();
}