
#import "IDocumentPicker.h"
#import "DocumentPickerSingletonBase.h"

@interface DocumentPickerSingleton : DocumentPickerSingletonBase<IDocumentPickerSingleton> {
}


-(NSString*)getInitialDefaultID;


-(void) enumerate:(id<IMethodResult>)methodResult;




@end