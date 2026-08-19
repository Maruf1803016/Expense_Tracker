# Direct Google Drive Backup Authorization

The planned direct backup uses a browser-based, user-authorized Google Drive connection. Google’s current guidance states that web applications must obtain an access token before calling Google APIs, and that Google Identity Services separates sign-in from user consent for authorization.[^1]

For Expense Ledger, the intended flow is: the user explicitly selects **Connect Google Drive**, chooses their own Google account, grants only the Drive permission required to create the backup, and then chooses **Back up now**. The application must never upload a ledger export before this user action and consent.

The setup requires a Google OAuth web client ID and the final application origin(s) registered in the Google Cloud console. The Drive API scope must be configured both in the app and in the Google Cloud console.[^2]

## Implemented browser flow

The implementation now loads Google Identity Services and, only after the account holder presses **Save to Google Drive**, requests the narrow `https://www.googleapis.com/auth/drive.file` scope through `google.accounts.oauth2.initTokenClient()`. Google’s token model returns a short-lived browser access token after the user chooses an account and grants consent; Expense Ledger does not store a Drive password, refresh token, or client secret.[^3]

The encrypted-browser session then sends the generated JSON backup with Drive API v3’s multipart file-creation endpoint. This sends the file content and its filename in one request, and the browser receives only the newly created file’s ID, name, and optional Drive link.[^4]

[^1]: [Google Identity Services — Authorizing for Web](https://developers.google.com/identity/oauth2/web/guides/overview)
[^2]: [Google Drive API — Choose Google Drive API scopes](https://developers.google.com/workspace/drive/api/guides/api-specific-auth)
[^3]: [Google Identity Services — Use the token model](https://developers.google.com/identity/oauth2/web/guides/use-token-model)
[^4]: [Google Drive API — Upload file data](https://developers.google.com/workspace/drive/api/guides/manage-uploads)
