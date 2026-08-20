# Web Google Drive OAuth-Origin Inspection

**Inspection date:** 20 August 2026 (GMT+6)

The owner account can access the **Expense Tracker** Google Cloud project. The existing web OAuth client is named **Expense Ledger - Web Drive Backup** and uses client ID `657477735157-74m42hh9s280ner0mad72hthi60a1bs7.apps.googleusercontent.com`.

At inspection, its **Authorized JavaScript origins** list had exactly one entry:

```text
https://expense-ledger.manus.space
```

The live application is served at:

```text
https://expensetrk-btvssrs3.manus.space
```

The live application origin is therefore not currently authorized. Adding it is necessary for the browser Google Drive backup authorization flow to work from the published site. The Google Cloud console notes that OAuth-client changes can take **five minutes to a few hours** to take effect.

**Source:** [Google Auth Platform OAuth client configuration](https://console.cloud.google.com/auth/clients/657477735157-74m42hh9s280ner0mad72hthi60a1bs7.apps.googleusercontent.com?authuser=1&project=expense-tracker-79ef7)
