#import <Foundation/Foundation.h>
#include "common/app_build_capabilities.h"

extern void Init_BGService_API();

void Init_BGService_extension()
{
    Init_BGService_API();
}