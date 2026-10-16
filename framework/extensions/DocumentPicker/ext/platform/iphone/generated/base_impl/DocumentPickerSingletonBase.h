

#import "IDocumentPicker.h"

@interface DocumentPickerSingletonBase : NSObject {
    NSString* mDefaultID;
}

-(id)init;

-(NSString*) getDefaultID;
-(void) setDefaultID:(NSString*)defaultID;

-(void)dealloc;

@end