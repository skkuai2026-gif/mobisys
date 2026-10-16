package com.rho.fingerprint;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.hardware.fingerprint.FingerprintManager;
import android.os.CancellationSignal;
import android.support.v4.app.ActivityCompat;

import com.rhomobile.rhodes.Logger;
import com.rhomobile.rhodes.api.IMethodResult;

import java.util.HashMap;
import java.util.Map;


public class FingerprintHandler extends FingerprintManager.AuthenticationCallback {
	private static final String TAG = FingerprintHandler.class.getSimpleName();
	private Context context;
	private IMethodResult result;

	// Constructor
	public FingerprintHandler(Context mContext, IMethodResult mResult) {
		context = mContext;
		result = mResult;
	}

	public void startAuth(FingerprintManager manager, FingerprintManager.CryptoObject cryptoObject) {
		CancellationSignal cancellationSignal = new CancellationSignal();
		if (ActivityCompat.checkSelfPermission(context, Manifest.permission.USE_FINGERPRINT) != PackageManager.PERMISSION_GRANTED) {
			return;
		}
		manager.authenticate(cryptoObject, cancellationSignal, 0, this, null);
	}

	@Override
	public void onAuthenticationError(int errMsgId, CharSequence errString) {
		this.update("Fingerprint Authentication error\n" + errString, false);
	}

	@Override
	public void onAuthenticationHelp(int helpMsgId, CharSequence helpString) {
		this.update("Fingerprint Authentication help\n" + helpString, false);
	}

	@Override
	public void onAuthenticationFailed() {
		this.update("Fingerprint Authentication failed.", false);
	}

	@Override
	public void onAuthenticationSucceeded(FingerprintManager.AuthenticationResult result) {
		this.update("Fingerprint Authentication succeeded.", true);
	}

	public void update(String e, Boolean success){
		Map resultMap = new HashMap();
		resultMap.put("authStatus", success.toString());
		resultMap.put("statusMessage", e);
		result.set(resultMap);
		Logger.I(TAG, e);
	}
}