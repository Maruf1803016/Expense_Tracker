package com.maruf.expenseledger;

import android.app.Activity;
import android.content.Intent;

import androidx.activity.result.ActivityResult;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "GoogleDriveAuth")
public class GoogleDriveAuthorizationPlugin extends Plugin {
    @PluginMethod
    public void authorize(PluginCall call) {
        Intent intent = new Intent(getContext(), GoogleDriveAuthorizationActivity.class);
        startActivityForResult(call, intent, "handleAuthorization");
    }

    @ActivityCallback
    private void handleAuthorization(PluginCall call, ActivityResult result) {
        if (call == null) return;

        if (result.getResultCode() != Activity.RESULT_OK || result.getData() == null) {
            String message = result.getData() == null
                ? "Google Drive permission was cancelled."
                : result.getData().getStringExtra(GoogleDriveAuthorizationActivity.EXTRA_ERROR);
            call.reject(message == null ? "Google Drive permission was cancelled." : message);
            return;
        }

        String accessToken = result.getData().getStringExtra(GoogleDriveAuthorizationActivity.EXTRA_ACCESS_TOKEN);
        if (accessToken == null || accessToken.trim().isEmpty()) {
            call.reject("Android Google Drive authorization did not return a usable access token.");
            return;
        }

        JSObject response = new JSObject();
        response.put("accessToken", accessToken);
        call.resolve(response);
    }
}
