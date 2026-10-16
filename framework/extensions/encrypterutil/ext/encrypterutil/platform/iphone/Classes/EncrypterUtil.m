
#import <EncrypterUtil.h>

#include <RhodesAppBase.h>
#include "ruby/ext/rho/rhoruby.h"

int byteKeyLength = kCCKeySizeAES256;

Byte byteKey[kCCKeySizeAES256] = {	0x20, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                                    0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
                                    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
                                    0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f
                                };

VALUE encrypterutil_native_encrypt(const char* str) {

	// initilization
    NSData* outputData = nil;
    
    
    NSString* inputUTFData = [[[NSString alloc] initWithCString:str
                                                      encoding:NSUTF8StringEncoding]
                              autorelease];
    
    printf("UTF NSString: |%s|\n", [inputUTFData UTF8String]);
    
    NSData* inputData = [inputUTFData dataUsingEncoding:NSUTF8StringEncoding
                                   allowLossyConversion:YES];
    
    CCAlgorithm algo = kCCAlgorithmAES128;
    
    NSData* key = [NSData dataWithBytes: byteKey
                                 length: byteKeyLength];
    
    CCOptions opts = kCCOptionPKCS7Padding;
    
    CCCryptorStatus status = kCCSuccess;
    
    printf("call to encrypt - |%s|\n", [inputData bytes]);

    // call to encrypt
    outputData = [inputData dataEncryptedUsingAlgorithm: algo   // kCCAlgorithmAES128
                                                    key: key    // 256b (32B) key
                                                options: opts   // kCCOptionECBMode
                                                  error: &status];

    printf("completed encrypt\n");

    // prepare return value
	VALUE result;
    char* outputBase64;
    
    if ( status != kCCSuccess )
	{
		NSError * err = [NSError errorWithCCCryptorStatus: status];
		result = rho_ruby_create_string([@"AES Encryption failed" UTF8String]);
        printf("encryption fail: %s\n", [err.localizedDescription UTF8String]);
	}
	else
	{
        printf("Output NSData: |%s|\n", [outputData bytes]);
        int inputLen = [outputData length];
        int outputLen = rho_base64_encode([outputData bytes],
                                          inputLen,
                                          0);
        outputBase64 = (char*)malloc(outputLen);
        printf("inputLen: %d\nOutputLen: %d\n", inputLen, outputLen);
        outputLen = rho_base64_encode([outputData bytes],
                                       inputLen,
                                       outputBase64);
        
	    result = rho_ruby_create_string(outputBase64);
        printf("inputLen: %d\nOutputLen: %d\n", inputLen, outputLen);
        
        printf("encryption success: |%s|\n", outputBase64);
	}
	
    // return
    return result;
}

VALUE encrypterutil_native_decrypt(const char* str) {
	printf("*******Decryption*******\n");
    // initilization
    NSData* outputData = nil;
    
    int inputLen = strlen(str);
    int outputLen = rho_base64_decode(str,
                                      inputLen,
                                      0);
    char* outputBase64 = (char*)malloc(outputLen);
    printf("inputLen: %d\nOutputLen: %d\n", inputLen, outputLen);
    
    outputLen = rho_base64_decode(str,
                                  inputLen,
                                  outputBase64);

    printf("UTF input string: |%s|\n", outputBase64);
    printf("inputLen: %d\nOutputLen: %d\n", inputLen, outputLen);
    
    NSData* inputData = [NSData dataWithBytes: outputBase64
                                       length: outputLen];

    CCAlgorithm algo = kCCAlgorithmAES128;
    
    NSData* key = [NSData dataWithBytes: byteKey
                                 length: byteKeyLength];
    
    CCOptions opts = kCCOptionPKCS7Padding;
    
    CCCryptorStatus status = kCCSuccess;
    
    printf("call to decrypt - |%s|\n", [inputData bytes]);
    
    // call to decrypt
    outputData = [inputData decryptedDataUsingAlgorithm: algo   // kCCAlgorithmAES128
                                                    key: key    // 256b (32B) key
                                                options: opts   // kCCOptionECBMode
                                                  error: &status];
    
    printf("completed decrypt\n");
    
    // prepare return value
	VALUE result;
    
    if ( status != kCCSuccess )
	{
		NSError * err = [NSError errorWithCCCryptorStatus: status];
		result = rho_ruby_create_string([@"AES decryption failed" UTF8String]);
        printf("decryption fail: %s\n", [err.localizedDescription UTF8String]);
	}
	else
	{
        printf("Output NSData: |%s|\n", [outputData bytes]);

        NSString* output = [NSString stringWithUTF8String:[outputData bytes]];
        
	    result = rho_ruby_create_string([output UTF8String]);
        printf("decryption success: |%s|\n", [output UTF8String]);
	}
	
    // return
    return result;
}

int encrypterutil_calc_summ(int x, int y) {
	return (x+y);
}

