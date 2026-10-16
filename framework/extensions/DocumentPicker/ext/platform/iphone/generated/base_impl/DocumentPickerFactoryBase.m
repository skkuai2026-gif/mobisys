
#import "DocumentPickerFactoryBase.h"
#import "DocumentPicker.h"
#import "DocumentPickerSingleton.h"



@implementation DocumentPickerFactoryBase

-(id)init {
    self = [super init];
    mDocumentPickerInstances = [[NSMutableDictionary dictionaryWithCapacity:4] retain];
    mDocumentPickerSingleton = nil;
    return self;
}

-(id<IDocumentPicker>) getDocumentPickerByID:(NSString*)ID {
    id<IDocumentPicker> obj = (DocumentPicker*)[mDocumentPickerInstances objectForKey:ID];
    if (obj == nil) {
        obj = [self createDocumentPickerByID:ID];
        [mDocumentPickerInstances setObject:obj forKey:ID];
    }
    return obj;
}

-(void) destroyObjectByID:(NSString*)ID {
    DocumentPicker* obj = [mDocumentPickerInstances objectForKey:ID];
    if (obj != nil) {
        [mDocumentPickerInstances removeObjectForKey:ID];
    }
}


-(id<IDocumentPicker>)createDocumentPickerByID:(NSString*)ID {
    DocumentPicker* obj = [[DocumentPicker alloc] init];

    [obj setProperty:@"ID" propertyValue:ID methodResult:nil];

    return obj;
}


-(id<IDocumentPickerSingleton>) getDocumentPickerSingleton {
    if (mDocumentPickerSingleton == nil) {
        mDocumentPickerSingleton = [[DocumentPickerSingleton alloc] init];
    }
    return mDocumentPickerSingleton;
}

-(NSArray*) enumerateDocumentPickerInstances {
    return [mDocumentPickerInstances allKeys];
}

-(void)dealloc {
    [mDocumentPickerInstances release];
    [super dealloc];
}


@end