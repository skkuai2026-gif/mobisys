#import "DocumentPicker.h"
#import <PDFKit/PDFKit.h>

@implementation DocumentPicker
@synthesize supportedExtensionArray;

-(void) pickDocument:(NSString *)supportedExtensionList methodResult:(id<IMethodResult>)methodResult {
	dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		dispatch_sync(dispatch_get_main_queue(), ^{
			self.supportedExtensionArray = [[NSMutableArray alloc]init];
		    for (id extension in [supportedExtensionList componentsSeparatedByString:@","]) {
		        [self.supportedExtensionArray addObject:extension];
		    }
		    NSLog(@"supported array===== %@",self.supportedExtensionArray);
			// Populate UTIs based on file extensions
			NSMutableArray *UTIs = [[NSMutableArray alloc]init];
			for (id extension in [supportedExtensionList componentsSeparatedByString:@","]) {
				[UTIs addObject:(__bridge NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, nil)];
			}
			UIViewController *vc = nil;
			// if (!IsAtLeastiOSVersion(@"11.0")) {
			// 	vc = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:UTIs inMode:UIDocumentPickerModeImport];
			// 	((UIDocumentMenuViewController *)vc).delegate = self;
			// 	vc.popoverPresentationController.sourceView = self.viewController.view;
			// 	if (!CGRectEqualToRect(senderFrame, CGRectZero)) {
			// 		vc.popoverPresentationController.sourceRect = senderFrame;
			// 	}
			// } else {
				vc = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:UTIs inMode:UIDocumentPickerModeImport];
				((UIDocumentPickerViewController *)vc).delegate = self;
				methodResultLocal = methodResult;
				vc.modalPresentationStyle = UIModalPresentationFullScreen;
			// }
				[[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:vc animated:YES completion:nil];
			// }
		});
	});
}

-(void) validatePdf:(NSString *)pdfPath methodResult:(id<IMethodResult>)methodResult {
		NSLog(@"~~~~pdfPath %@", pdfPath);
		NSURL *pdfUrl = [NSURL fileURLWithPath:pdfPath];

		NSError *error;
		// NSData* data = [pdfData dataUsingEncoding:NSUTF8StringEncoding];
		NSData *data = [[NSData alloc] initWithContentsOfURL:pdfUrl options:0 error:&error];
	    BOOL isLocked = false;
        BOOL isValidPDF = [self isValidPDF:data];
        NSLog(@"~~~pdf isValidPDF: %d", isValidPDF);
        
        if(isValidPDF) {

        	PDFDocument *pdfDocument = [[PDFDocument alloc] initWithURL:pdfUrl];
        	// PDFDocument *pdfDocument = [[PDFDocument alloc] initWithData:data];
        	NSLog(@"~~~pdf isLocked: %d", pdfDocument.isLocked);
        	isLocked = pdfDocument.isLocked;

        	if(isLocked) {
        		self.status = @"error";
        		self.message = @"PDF is locked";
				NSLog(@"PDF is locked");
        		
        	}
        	else {
        		self.status = @"ok";
        		self.message = @"PDF is valid";
				NSLog(@"PDF is not locked");

        	}
        }
        else {
        	self.status = @"error";
        	self.message = @"PDF is corrupted or invalid";
			NSLog(@"PDF is corrupted or invalid");
        }

        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: self.status, @"status", self.message, @"message", nil];
		[methodResult setResult:dict];

}

#pragma mark - UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
	NSString *tempURL = [urls componentsJoinedByString:@","];

	//get path to destination file
	self.filePath = [NSString pathWithComponents:@[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], @"apps", [tempURL lastPathComponent]]];

	NSString *ext = [self.filePath pathExtension];
	NSLog(@"extension: %@", ext);

	
	if (![self.supportedExtensionArray containsObject:ext]) {
		//extension not included
		self.status = @"extnotsupported";
		self.filePath = @"";
	}
	else
	{
		if (![[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
			NSURL *url = [NSURL URLWithString:tempURL];
			NSError *error;
			NSData *data = [[NSData alloc] initWithContentsOfURL:url options:0 error:&error];
	        BOOL isLocked = false;
	        BOOL isValidPDF = [self isValidPDF:data];
	        NSLog(@"~~~pdf isValidPDF: %d", isValidPDF);
	        
	        if(isValidPDF) {
	        	PDFDocument *pdfDocument = [[PDFDocument alloc] initWithURL:url];
	        	NSLog(@"~~~pdf isLocked: %d", pdfDocument.isLocked);
	        	isLocked = pdfDocument.isLocked;

	        	if(!isLocked) {
	        		if (!data) {
						// check if download has failed
						self.status = @"error";
						self.filePath = @"";
						self.message = @"Error fetching file";
						NSLog(@"Error fetching file %@", error);
					}
					else {
						// successful download
						if (![data writeToFile:self.filePath options:NSDataWritingAtomic error:&error]) {
							// check if writing failed
							self.status = @"error";
							self.filePath = @"";
							self.message = @"Error writing file";
							NSLog(@"Error writing file %@", error);
						}
						else {
							self.status = @"ok";
							NSLog(@"File saved.");
						}
					}
	        	}
	        	else {
	        		self.status = @"error";
	        		self.message = @"PDF is locked";
					self.filePath = @"";
					NSLog(@"PDF is locked");

	        	}
	        }
	        else {
	        	self.status = @"error";
	        	self.message = @"PDF is corrupted or invalid";
				self.filePath = @"";
				NSLog(@"PDF is corrupted or invalid");
	        }

	        // fileURL is NSURL file path instance created using base64 pdf content
	        
	        
	        
	        
	        
			
		}
	}
	[self updateResult];
}

- (BOOL)isPNGValid:(NSData *)data
{
    BOOL val = YES;

    if ([data length] < 4) 
        val = NO;

    const char * bytes = (const char *)[data bytes];

    if (bytes[0] != 0x89 || bytes[1] != 0x50) 
        val = NO;
    if (bytes[[data length] - 2] != 0x60 || 
        bytes[[data length] - 1] != 0x82) 
        val = NO;

    return val;
}

-(BOOL)isValidJPEG:(NSData *)data
{
    if (!data || data.length < 2) return NO;

    NSInteger totalBytes = data.length;
    const char *bytes = (const char*)[data bytes];

    return (bytes[0] == (char)0xff && 
            bytes[1] == (char)0xd8 &&
            bytes[totalBytes-2] == (char)0xff &&
            bytes[totalBytes-1] == (char)0xd9);
}

// Validate PDF using NSData
- (BOOL)isValidPDF:(NSData *)pdfData {
    BOOL isPDFValid = true;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)pdfData);
	CGPDFDocumentRef document = CGPDFDocumentCreateWithProvider(provider);

	if (document == nil) {
	    NSLog(@"~~~The PDF is corrupted");
	    isPDFValid = false;
	}
	else {
	    NSLog(@"~~~The PDF is OK");

	}
    return isPDFValid;
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
	self.status = @"cancel";
	self.filePath = @"";
	[self updateResult];
}

- (void)updateResult {
	NSLog(@"%@", self.status);
	NSLog(@"%@", self.filePath);
	NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: self.status, @"status", self.filePath, @"filePath", self.message, @"message", nil];
	[methodResultLocal setResult:dict];
}

@end
