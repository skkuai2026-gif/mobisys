#import <Foundation/Foundation.h>
#include "common/app_build_capabilities.h"

extern void Init_Fingerprint_API();

void Init_Fingerprint_extension()
{
    Init_Fingerprint_API();
}