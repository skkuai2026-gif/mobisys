package com.rho.documentpicker;

import java.util.Map;
import java.util.HashMap;
import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileOutputStream;

import android.content.Intent;
import android.net.Uri;
import android.webkit.MimeTypeMap;

import com.rhomobile.rhodes.Logger;
import com.rhomobile.rhodes.RhodesActivity;
import com.rhomobile.rhodes.extmanager.AbstractRhoListener;
import com.rhomobile.rhodes.extmanager.IRhoListener;
import com.rhomobile.rhodes.extmanager.IRhoExtManager;
import com.rhomobile.rhodes.util.ContextFactory;
import com.rhomobile.rhodes.api.IMethodResult;

public class DocumentPickerRhoListener extends AbstractRhoListener implements IRhoListener {
	private static final String LOG_TAG = DocumentPicker.class.getSimpleName();
	private static final int READ_REQUEST_CODE = 42;
	private static DocumentPickerRhoListener sInstance = null;
	private IMethodResult mMethodResult;
	
	@Override
	public void onActivityResult(RhodesActivity activity, int requestCode, int resultCode, Intent resultData) {
		Map resultMap = new HashMap();
		if (mMethodResult != null) {
			if (requestCode == READ_REQUEST_CODE && resultCode == RhodesActivity.RESULT_OK) {
				Uri content_describer = resultData.getData();
				String filePath = content_describer.getPath();
				InputStream in = null;
				OutputStream out = null;
				try {
					try {
						// open the user-picked file for reading:
						in = ContextFactory.getUiContext().getContentResolver().openInputStream(content_describer);
						
						String filename = filePath.substring(filePath.lastIndexOf("/")+1);
						Logger.I(LOG_TAG, "in onActivityResult source---------------------"+filePath.toString());
						if(filePath.lastIndexOf(".") == -1){
							String mimeType = ContextFactory.getUiContext().getContentResolver().getType(content_describer);
							String extension = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType);
							filename = filename.replaceAll("[\\\\/:*?\"<>|=;]", "");
							filename += "." + extension;
							Logger.I(LOG_TAG, "in onActivityResult mimeType---------------------"+mimeType.toString());
							Logger.I(LOG_TAG, "in onActivityResult extension---------------------"+extension.toString());
						}
						
						File destination = new File(ContextFactory.getUiContext().getApplicationInfo().dataDir + "/rhodata/apps/" + filename);
						Logger.I(LOG_TAG, "in onActivityResult destination---------------------"+destination.toString());
						// open the output-file:
						out = new FileOutputStream(destination);
						// copy the content:
						byte[] buffer = new byte[1024];
						int len;
						while ((len = in.read(buffer)) != -1) {
							out.write(buffer, 0, len);
						}
						// Contents are copied!
						resultMap.put("status", "ok");
						resultMap.put("filePath", destination.toString());
						mMethodResult.set(resultMap);
					}
					catch(Exception e){
						Logger.E(LOG_TAG, e);
						resultMap.put("status", "error");
						resultMap.put("filePath", "");
						mMethodResult.set(resultMap);
					}
					finally {
						if (in != null) {
							in.close();
						}
						if (out != null){
							out.close();
						}
					}
				}
				catch(Exception e){
					Logger.E(LOG_TAG, e);
					resultMap.put("status", "error");
					resultMap.put("filePath", "");
					mMethodResult.set(resultMap);
				}
			}
			else{
				resultMap.put("status", "cancel");
				resultMap.put("filePath", "");
				mMethodResult.set(resultMap);
			}
		}
	}

	static DocumentPickerRhoListener getInstance() {
		return sInstance;
	}

	void setMethodResult(IMethodResult result) {
		mMethodResult = result;
	}

	@Override
	public void onCreateApplication(IRhoExtManager extManager) {
		Logger.I(LOG_TAG, "in onCreateApplication---------------------");
		sInstance = this;
		extManager.addRhoListener(this);
	}
}
