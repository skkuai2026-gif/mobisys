package com.rho.documentpicker;

import java.util.Arrays;

import android.content.Intent;
import android.os.Build;
import android.webkit.MimeTypeMap;

import com.rhomobile.rhodes.RhodesActivity;
import com.rhomobile.rhodes.extmanager.RhoExtManager;
import com.rhomobile.rhodes.Logger;
import com.rhomobile.rhodes.api.IMethodResult;

public class DocumentPicker extends DocumentPickerBase implements IDocumentPicker {
	private static final String LOG_TAG = DocumentPicker.class.getSimpleName();
	private static final int READ_REQUEST_CODE = 42;

	public DocumentPicker(String id) {
		super(id);
	}

	@Override
	public void pickDocument(String supportedExtensionList, IMethodResult result) {
		performFileSearch(supportedExtensionList);
		DocumentPickerRhoListener.getInstance().setMethodResult(result);
	}
	
	private void performFileSearch(String supportedExtensionList) {
		String supportedExtensionListArray[] = supportedExtensionList.split(",");
		String supportedMimeTypes = "";
		for (int i = 0; i < supportedExtensionListArray.length; i++) {
			supportedMimeTypes += ";" + MimeTypeMap.getSingleton().getMimeTypeFromExtension(supportedExtensionListArray[i]);
			supportedExtensionListArray[i] = MimeTypeMap.getSingleton().getMimeTypeFromExtension(supportedExtensionListArray[i]);
		}
		supportedMimeTypes = supportedMimeTypes.substring(1);
		Logger.I(LOG_TAG, "in onActivityResult supportedMimeTypes---------------------"+supportedMimeTypes);
		Logger.I(LOG_TAG, "in onActivityResult supportedExtensionListArray---------------------"+Arrays.toString(supportedExtensionListArray));
		Intent intent = null;
		if(android.os.Build.MANUFACTURER.equals("samsung")){
			intent = new Intent("com.sec.android.app.myfiles.PICK_DATA");
			intent.addCategory(Intent.CATEGORY_DEFAULT);
			intent.putExtra("CONTENT_TYPE", supportedMimeTypes);
		}
		else{
			intent = new Intent(Intent.ACTION_GET_CONTENT);
			intent.addCategory(Intent.CATEGORY_OPENABLE);
			intent.setType("*/*");
			intent.putExtra(Intent.EXTRA_MIME_TYPES, supportedExtensionListArray);
		}
		RhodesActivity.safeGetInstance().startActivityForResult(intent, READ_REQUEST_CODE);
	}
}