
#import "IDocumentPicker.h"

@interface DocumentPickerFactoryBase : NSObject<IDocumentPickerFactory> {
    NSMutableDictionary* mDocumentPickerInstances;
    id<IDocumentPickerSingleton> mDocumentPickerSingleton;
}

-(id)init;

-(id<IDocumentPickerSingleton>) getDocumentPickerSingleton;
-(id<IDocumentPicker>) getDocumentPickerByID:(NSString*)ID;

-(void) destroyObjectByID:(NSString*)ID;

-(id<IDocumentPicker>)createDocumentPickerByID:(NSString*)ID;

-(NSArray*) enumerateDocumentPickerInstances;

-(void)dealloc;

@end