package com.maruf.expenseledger;

import android.app.Activity;
import android.content.Intent;
import android.content.IntentSender;
import android.os.Bundle;

import com.google.android.gms.auth.api.identity.AuthorizationRequest;
import com.google.android.gms.auth.api.identity.AuthorizationResult;
import com.google.android.gms.auth.api.identity.Identity;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.Scope;

import java.util.Collections;

public class GoogleDriveAuthorizationActivity extends Activity {
    static final String EXTRA_ACCESS_TOKEN = "com.maruf.expenseledger.drive.ACCESS_TOKEN";
    static final String EXTRA_ERROR = "com.maruf.expenseledger.drive.ERROR";

    private static final int REQUEST_CODE_GOOGLE_DRIVE_AUTHORIZATION = 2201;
    private static final String DRIVE_FILE_SCOPE = "https://www.googleapis.com/auth/drive.file";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (savedInstanceState == null) beginAuthorization();
    }

    private void beginAuthorization() {
        AuthorizationRequest request = AuthorizationRequest.builder()
            .setRequestedScopes(Collections.singletonList(new Scope(DRIVE_FILE_SCOPE)))
            .build();

        Identity.getAuthorizationClient(this)
            .authorize(request)
            .addOnSuccessListener(result -> {
                if (result.hasResolution()) {
                    try {
                        startIntentSenderForResult(
                            result.getPendingIntent().getIntentSender(),
                            REQUEST_CODE_GOOGLE_DRIVE_AUTHORIZATION,
                            null,
                            0,
                            0,
                            0
                        );
                    } catch (IntentSender.SendIntentException exception) {
                        finishWithError("Google Drive permission could not be opened. Please try again.");
                    }
                    return;
                }
                finishWithToken(result);
            })
            .addOnFailureListener(error -> finishWithError(describeAuthorizationError(error)));
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != REQUEST_CODE_GOOGLE_DRIVE_AUTHORIZATION) return;
        if (data == null) {
            finishWithError("Google Drive permission was cancelled.");
            return;
        }

        try {
            AuthorizationResult result = Identity.getAuthorizationClient(this).getAuthorizationResultFromIntent(data);
            finishWithToken(result);
        } catch (ApiException exception) {
            finishWithError(describeAuthorizationError(exception));
        }
    }

    private void finishWithToken(AuthorizationResult result) {
        String accessToken = result.getAccessToken();
        if (accessToken == null || accessToken.trim().isEmpty()) {
            finishWithError("Google Drive permission was granted without a usable access token. Please try again.");
            return;
        }

        Intent resultIntent = new Intent();
        resultIntent.putExtra(EXTRA_ACCESS_TOKEN, accessToken);
        setResult(Activity.RESULT_OK, resultIntent);
        finish();
    }

    private void finishWithError(String message) {
        Intent resultIntent = new Intent();
        resultIntent.putExtra(EXTRA_ERROR, message);
        setResult(Activity.RESULT_CANCELED, resultIntent);
        finish();
    }

    private String describeAuthorizationError(Exception error) {
        if (error instanceof ApiException && ((ApiException) error).getStatusCode() == 10) {
            return "Android Google Drive authorization is not configured yet. Add the Android OAuth client for com.maruf.expenseledger and this APK’s SHA-1, then try again.";
        }
        return "Google Drive permission could not be completed. Please try again.";
    }
}
