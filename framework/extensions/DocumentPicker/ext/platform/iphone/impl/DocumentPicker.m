#import "DocumentPicker.h"

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
			
			if (!data) {
				// check if download has failed
				self.status = @"error";
				self.filePath = @"";
				NSLog(@"Error fetching file %@", error);
			}
			else {
				// successful download
				if (![data writeToFile:self.filePath options:NSDataWritingAtomic error:&error]) {
					// check if writing failed
					self.status = @"error";
					self.filePath = @"";
					NSLog(@"Error writing file %@", error);
				}
				else {
					self.status = @"ok";
					NSLog(@"File saved.");
				}
			}
		}
	}
	
	
	[self updateResult];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
	self.status = @"cancel";
	self.filePath = @"";
	[self updateResult];
}

- (void)updateResult {
	NSLog(@"%@", self.status);
	NSLog(@"%@", self.filePath);
	NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: self.status, @"status", self.filePath, @"filePath", nil];
	[methodResultLocal setResult:dict];
}

@end