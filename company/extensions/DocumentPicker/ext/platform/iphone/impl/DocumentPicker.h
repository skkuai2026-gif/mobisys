#import "IDocumentPicker.h"
#import "DocumentPickerBase.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface DocumentPicker : DocumentPickerBase<IDocumentPicker> {
	id<IMethodResult> * methodResultLocal;
}

-(void) pickDocument:(NSString*)supportedExtensionList methodResult:(id<IMethodResult>)methodResult;

@property (nonatomic, assign) NSString* status;
@property (nonatomic, assign) NSString* filePath;
@property (nonatomic, assign) NSString* message;
@property (nonatomic, assign) NSMutableArray* supportedExtensionArray;


@end