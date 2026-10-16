package com.encrypterutil;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.math.BigInteger;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.spec.AlgorithmParameterSpec;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.KeySpec;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.CipherInputStream;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.PBEParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import com.rhomobile.rhodes.Base64;
import com.rhomobile.rhodes.Logger;



/**
 * This class is for encrypting and decrypting strings using Cipher algorithms. The class is created with a key and can be used repeatedly to encrypt and
 * decrypt strings using that key. With algorithms : PBEWithMD5AndDES
 * 
 */

public class EncrypterUtil {
	private static final String TAG = "EncrypterUtilJava";
	
	private Cipher encryptAESCipher;
	private Cipher decryptAESCipher;

	private static EncrypterUtil encrypterUtil = null;
	private static final String AES_ECB_ISO10126PADDING = "AES/ECB/ISO10126Padding";
	private static final String AES_ECB_PKCS5PADDING = "AES/ECB/PKCS5Padding";
	
	/**
	 * Constructor used to create this object. Responsible for setting and initializing this object's encrypter and decrypter Chipher instances given a Pass
	 * Phrase and algorithm.
	 * 
	 * @param passPhraseKey
	 *            Pass Phrase used to initialize both the encrypter and decrypter instances.
	 */
	private EncrypterUtil(byte[] aesKeyBytes) {

		try {
			// AES Ciphers
			SecretKeySpec aesKey = new SecretKeySpec(aesKeyBytes, "AES");
			encryptAESCipher = Cipher.getInstance(AES_ECB_PKCS5PADDING);
			encryptAESCipher.init(Cipher.ENCRYPT_MODE, aesKey);
			
			decryptAESCipher = Cipher.getInstance(AES_ECB_PKCS5PADDING);
			decryptAESCipher.init(Cipher.DECRYPT_MODE, aesKey);
		} catch (NoSuchAlgorithmException e) {
			Logger.E(TAG, "EXCEPTION: NoSuchAlgorithmException");
		} catch (NoSuchPaddingException e) {
			Logger.E(TAG, "EXCEPTION: NoSuchPaddingException");
		} catch (InvalidKeyException e) {
			Logger.E(TAG, "EXCEPTION: InvalidKeyException. Upgrade JRE to have unlimited JCE Policy.");
		}

	}

	/**
	 * Returns Singleton EncrypterUtil
	 * 
	 * @return EncrypterUtil
	 */
	public static EncrypterUtil getInstance() {
		if (EncrypterUtil.encrypterUtil == null) {
			encrypterUtil = new EncrypterUtil(getAESKey());
			Logger.I(TAG, "returning new instance with key" + new String(getAESKey()));
		}
		return encrypterUtil;
	}

	private static byte[] getAESKey(){
		return new byte[] { (byte)0x20, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                			0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
                			0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
                			0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f};
	}

	/**
	 * Takes a String and uses the initialized aes cipher to encrypt it
	 * 
	 * @param str
	 *            String to be encrypted
	 * @return <code>String</code> AES Encrypted version of the provided String
	 */
	
	public String encryptAES(String str)
	{
		String encryptedString = null;
		
		try {
			
			// Encode the string into bytes using utf-8
			byte[] utf8 = str.getBytes("UTF8");
			
		    ByteArrayInputStream bIn = new ByteArrayInputStream(utf8);
		    CipherInputStream cIn = new CipherInputStream(bIn, encryptAESCipher);
		    ByteArrayOutputStream bOut = new ByteArrayOutputStream();
		    int ch;
		    while ((ch = cIn.read()) >= 0) {
		        bOut.write(ch);
		    }
		    
		    byte[] enc = bOut.toByteArray();
		    
			// Encode bytes to base64 to get a string
			encryptedString = new String(Base64.encodeToByte(enc, false));
		} catch (UnsupportedEncodingException e) {
			Logger.E(TAG, "Exception: UnsupportedEncodingException");
		} catch (IOException e) {
			Logger.E(TAG, "Exception: IOException");
		}
		return encryptedString;
	}

	/**
	 * Takes a AES encrypted String and uses the initialized aes cipher to decrypt it
	 * 
	 * @param str
	 *            AES encrypted String to be decrypted
	 * @return <code>String</code> Decrypted version of the provided String
	 */
	
	public String decryptAES(String str)
	{
		String decryptedString = null;
		
		try {
			// Decode base64 to get bytes
			byte[] enc = Base64.decode(str.getBytes());
	
		    ByteArrayInputStream bIn = new ByteArrayInputStream(enc);
		    CipherInputStream cIn = new CipherInputStream(bIn, decryptAESCipher);
		    ByteArrayOutputStream bOut = new ByteArrayOutputStream();
		    int ch;
		    while ((ch = cIn.read()) >= 0) {
		        bOut.write(ch);
		    }
		    
		    byte[] dec = bOut.toByteArray();
		    // Decode using utf-8
			decryptedString = new String(dec, "UTF8");
		} catch (UnsupportedEncodingException e) {
			Logger.E(TAG, "Exception: UnsupportedEncodingException");
		} catch (IOException e) {
			Logger.E(TAG, "Exception: IOException");
		}
		return decryptedString;
	}

	public static String encrypt(String str) {
		return EncrypterUtil.getInstance().encryptAES(str);        
	}

	public static String decrypt(String str) {
		return EncrypterUtil.getInstance().decryptAES(str);
	}
	
}
