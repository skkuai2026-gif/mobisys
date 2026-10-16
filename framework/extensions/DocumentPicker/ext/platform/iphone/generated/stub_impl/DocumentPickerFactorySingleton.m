
#import "IDocumentPicker.h"
#import "DocumentPickerFactoryBase.h"

static DocumentPickerFactoryBase* ourDocumentPickerFactory = nil;

@implementation DocumentPickerFactorySingleton

+(id<IDocumentPickerFactory>) getDocumentPickerFactoryInstance {
    if (ourDocumentPickerFactory == nil) {
        ourDocumentPickerFactory = [[DocumentPickerFactoryBase alloc] init];
    }
    return ourDocumentPickerFactory;
}

@end