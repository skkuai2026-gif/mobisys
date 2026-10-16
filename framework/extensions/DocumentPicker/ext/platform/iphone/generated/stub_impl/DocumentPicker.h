
#import "IDocumentPicker.h"
#import "DocumentPickerBase.h"

@interface DocumentPicker : DocumentPickerBase<IDocumentPicker> {
}

-(void) pickDocument:(NSString*)supportedExtensionList methodResult:(id<IMethodResult>)methodResult;



@end