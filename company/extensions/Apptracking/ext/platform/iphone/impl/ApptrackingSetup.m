#import <Foundation/Foundation.h>
#include "common/app_build_capabilities.h"

extern void Init_Apptracking_API();

void Init_Apptracking_extension()
{
    Init_Apptracking_API();
}