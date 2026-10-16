package com.rho.fingerprint;

import java.io.IOException;
import java.security.cert.CertificateException;
import java.security.InvalidKeyException;
import java.security.InvalidAlgorithmParameterException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.UnrecoverableKeyException;

import com.rhomobile.rhodes.api.IMethodResult;
import com.rhomobile.rhodes.api.MethodResult;
import com.rhomobile.rhodes.util.ContextFactory;
import com.rhomobile.rhodes.Logger;

import android.annotation.TargetApi;
import android.app.KeyguardManager;
import android.content.Context;
import android.hardware.fingerprint.FingerprintManager;
import android.os.Build;
import android.security.keystore.KeyProperties;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyPermanentlyInvalidatedException;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.SecretKey;

public class Fingerprint extends FingerprintBase implements IFingerprint {
	private static final String TAG = Fingerprint.class.getSimpleName();
	
	// Variable used for storing the key in the Android Keystore container
	private static final String KEY_NAME = "C2LBIZ";
	private KeyStore keyStore;
	private Cipher cipher;

	public Fingerprint(String id) {
		super(id);
	}


	@Override
	public void enableFingerprintScan(IMethodResult result) {
		Context activityContext = ContextFactory.getContext();

		// Initializing both Android Keyguard Manager and Fingerprint Manager
		KeyguardManager keyguardManager = (KeyguardManager) activityContext.getSystemService(Context.KEYGUARD_SERVICE);
		FingerprintManager fingerprintManager = (FingerprintManager) activityContext.getSystemService(Context.FINGERPRINT_SERVICE);

		// Check whether the device has a Fingerprint sensor.
		if(!fingerprintManager.isHardwareDetected()){
			Logger.I(TAG, "Your Device does not have a Fingerprint Sensor");
		}
		else{
			// Check whether at least one fingerprint is registered
			if(!fingerprintManager.hasEnrolledFingerprints()) {
				Logger.I(TAG, "Register at least one fingerprint in Settings");
			}
			else{
				// Checks whether lock screen security is enabled or not
				if(!keyguardManager.isKeyguardSecure()) {
					Logger.I(TAG, "Lock screen security not enabled in Settings");
				}
				else{
					Logger.I(TAG, "All conditions satisfied for fingerprint recognition");

					generateKey();

					if (cipherInit()) {
						FingerprintManager.CryptoObject cryptoObject = new FingerprintManager.CryptoObject(cipher);
						FingerprintHandler helper = new FingerprintHandler(activityContext, result);
						helper.startAuth(fingerprintManager, cryptoObject);
					}
				}
			}
		}
	}


	@TargetApi(Build.VERSION_CODES.M)
	protected void generateKey() {
		try {
			keyStore = KeyStore.getInstance("AndroidKeyStore");
		} catch (Exception e) {
			e.printStackTrace();
		}

		KeyGenerator keyGenerator;
		try {
			keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
		} catch (NoSuchAlgorithmException e) {
			throw new RuntimeException("Failed to get KeyGenerator instance", e);
		} catch (NoSuchProviderException e) {
			throw new RuntimeException("Failed to get KeyGenerator instance", e);
		}

		try {
			keyStore.load(null);
			keyGenerator.init(new
				KeyGenParameterSpec.Builder(KEY_NAME,
					KeyProperties.PURPOSE_ENCRYPT |
					KeyProperties.PURPOSE_DECRYPT)
				.setBlockModes(KeyProperties.BLOCK_MODE_CBC)
				.setUserAuthenticationRequired(true)
				.setEncryptionPaddings(
					KeyProperties.ENCRYPTION_PADDING_PKCS7)
				.build());
			keyGenerator.generateKey();
		} catch (NoSuchAlgorithmException e) {
			throw new RuntimeException(e);
		} catch (InvalidAlgorithmParameterException e) {
			throw new RuntimeException(e);
		} catch (CertificateException e) {
			throw new RuntimeException(e);
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}


	@TargetApi(Build.VERSION_CODES.M)
	public boolean cipherInit() {
		try {
			cipher = Cipher.getInstance(KeyProperties.KEY_ALGORITHM_AES + "/" + KeyProperties.BLOCK_MODE_CBC + "/" + KeyProperties.ENCRYPTION_PADDING_PKCS7);
		} catch (NoSuchAlgorithmException e) {
			throw new RuntimeException("Failed to get Cipher", e);
		} catch (NoSuchPaddingException e) {
			throw new RuntimeException("Failed to get Cipher", e);
		}


		try {
			keyStore.load(null);
			SecretKey key = (SecretKey) keyStore.getKey(KEY_NAME, null);
			cipher.init(Cipher.ENCRYPT_MODE, key);
			return true;
		} catch (KeyPermanentlyInvalidatedException e) {
			return false;
		} catch (KeyStoreException e) {
			throw new RuntimeException("Failed to init Cipher", e);
		} catch (CertificateException e) {
			throw new RuntimeException("Failed to init Cipher", e);
		} catch (UnrecoverableKeyException e) {
			throw new RuntimeException("Failed to init Cipher", e);
		} catch (IOException e) {
			throw new RuntimeException("Failed to init Cipher", e);
		} catch (NoSuchAlgorithmException e) {
			throw new RuntimeException("Failed to init Cipher", e);
		} catch (InvalidKeyException e) {
			throw new RuntimeException("Failed to init Cipher", e);
		}
	}
}