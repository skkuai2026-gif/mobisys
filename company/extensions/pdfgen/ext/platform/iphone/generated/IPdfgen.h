
#import <Foundation/Foundation.h>

#import "api_generator/iphone/IMethodResult.h"


// hash keys used in properties and parameters

#define PROPERTY_SIMPLE_STRING_PROPERTY @"simpleStringProperty"


@protocol IPdfgen <NSObject>


/* getter for "simpleStringProperty" property */
-(void) getSimpleStringProperty:(id<IMethodResult>)methodResult;

/* setter for "simpleStringProperty" property */
-(void) setSimpleStringProperty:(NSString*)simpleStringProperty methodResult:(id<IMethodResult>)methodResult;

/* Generate PDF using iText for Android */
-(void) generateAndroidPDF:(NSString*)inputHTMLFileName orientation:(NSString*)orientation isSinglePDFRequired:(NSString*)isSinglePDFRequired password:(NSString*)password methodResult:(id<IMethodResult>)methodResult;

/* Generate Charts for PDF using MPAndroidCharts on Android */
-(void) generateAndroidPDFCharts:(NSString*)chartJSON chartOutputFileName:(NSString*)chartOutputFileName chartType:(NSString*)chartType methodResult:(id<IMethodResult>)methodResult;

/* Generate PDF for iOS */
-(void) generateIOSPDF:(NSString*)htmlContent targetFilePath:(NSString*)targetFilePath methodResult:(id<IMethodResult>)methodResult;

/* Merge PDF in iOS */
-(void) mergeIOSPDF:(NSString*)listOfPaths targetFilePath:(NSString*)targetFilePath masterPassword:(NSString*)masterPassword password:(NSString*)password methodResult:(id<IMethodResult>)methodResult;

/* This method will return the value of the propertyName that is passed in. The propertyName must be a valid property of the API class. */
-(void) getProperty:(NSString*)propertyName methodResult:(id<IMethodResult>)methodResult;

/* This method will return a set of object/value pairs for the list of the propertyName that is passed in. The propertyNames must be a valid property of the API class. */
-(void) getProperties:(NSArray*)arrayofNames methodResult:(id<IMethodResult>)methodResult;

/* This method will return all of object/value pairs for the propertyNames of the API class. */
-(void) getAllProperties:(id<IMethodResult>)methodResult;

/* This method will set the value of a property for the API class. The propertyName must be a valid property for the class and must also not be read only. */
-(void) setProperty:(NSString*)propertyName propertyValue:(NSString*)propertyValue methodResult:(id<IMethodResult>)methodResult;

/* This method will set the values of a list of properties for the API class. The propertyName must be a valid property for the class and must also not be read only. */
-(void) setProperties:(NSDictionary*)propertyMap methodResult:(id<IMethodResult>)methodResult;


// NOTE: if you want to hold methodResult(for example periodically call callbacks) you should release it manually when you stop using it!
@end


@protocol IPdfgenSingleton <NSObject>


-(NSString*) getDefaultID;
-(void) setDefaultID:(NSString*)defaultID;
-(NSString*)getInitialDefaultID;
    


-(void) enumerate:(id<IMethodResult>)methodResult;


@end


@protocol IPdfgenFactory <NSObject>
-(id<IPdfgenSingleton>) getPdfgenSingleton;
-(id<IPdfgen>) getPdfgenByID:(NSString*)ID;
-(void) destroyObjectByID:(NSString*)ID;
-(NSArray*) enumeratePdfgenInstances;
@end


@interface PdfgenFactorySingleton : NSObject {
}
+(id<IPdfgenFactory>) getPdfgenFactoryInstance;
@end


