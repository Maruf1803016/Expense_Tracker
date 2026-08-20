package com.maruf.expenseledger;

import android.content.Intent;
import android.os.Bundle;

import androidx.activity.ComponentActivity;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.IntentSenderRequest;
import androidx.activity.result.contract.ActivityResultContracts;

import com.google.android.gms.auth.api.identity.AuthorizationRequest;
import com.google.android.gms.auth.api.identity.AuthorizationResult;
import com.google.android.gms.auth.api.identity.Identity;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.Scope;

import java.util.Collections;

public class GoogleDriveAuthorizationActivity extends ComponentActivity {
    static final String EXTRA_ACCESS_TOKEN = "com.maruf.expenseledger.drive.ACCESS_TOKEN";
    static final String EXTRA_ERROR = "com.maruf.expenseledger.drive.ERROR";

    private static final String DRIVE_FILE_SCOPE = "https://www.googleapis.com/auth/drive.file";

    private ActivityResultLauncher<IntentSenderRequest> authorizationResolutionLauncher;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        authorizationResolutionLauncher = registerForActivityResult(
            new ActivityResultContracts.StartIntentSenderForResult(),
            result -> handleAuthorizationResolution(result.getResultCode(), result.getData())
        );
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
                        IntentSenderRequest resolutionRequest = new IntentSenderRequest.Builder(
                            result.getPendingIntent().getIntentSender()
                        ).build();
                        authorizationResolutionLauncher.launch(resolutionRequest);
                    } catch (Exception exception) {
                        finishWithError("Google Drive permission could not be opened. Please try again.");
                    }
                    return;
                }
                finishWithToken(result);
            })
            .addOnFailureListener(error -> finishWithError(describeAuthorizationError(error)));
    }

    private void handleAuthorizationResolution(int resultCode, Intent data) {
        if (resultCode != RESULT_OK) {
            finishWithError("Google Drive permission was cancelled.");
            return;
        }
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
        setResult(RESULT_OK, resultIntent);
        finish();
    }

    private void finishWithError(String message) {
        Intent resultIntent = new Intent();
        resultIntent.putExtra(EXTRA_ERROR, message);
        setResult(RESULT_CANCELED, resultIntent);
        finish();
    }

    private String describeAuthorizationError(Exception error) {
        if (error instanceof ApiException && ((ApiException) error).getStatusCode() == 10) {
            return "Android Google Drive authorization is not configured yet. Add the Android OAuth client for com.maruf.expenseledger and this APK’s SHA-1, then try again.";
        }
        return "Google Drive permission could not be completed. Please try again.";
    }
}
