# Trusted Account Emails — No-Cost Plan

## Decision

Expense Ledger will keep Firebase Authentication’s default verification and password-reset links because no owned custom domain is currently available. This is the correct **no-cost** option. The long `oobCode` query parameter is a Firebase one-time security code; it must remain intact and must not be sent through a public URL shortener.

| Item | No-cost decision |
| --- | --- |
| Email delivery | Firebase Authentication’s built-in verification and reset messages |
| Action-link domain | Firebase’s default project authentication domain |
| Secure code | Retained exactly as Firebase creates it |
| User reassurance | Clear in-app explanation before and after a request, plus recognisable Firebase template wording where available |
| Custom domain | Deferred until the owner controls a real domain and DNS records |

## What users should expect

Before requesting an email, the app should explain that the message is for **Expense Ledger**, is sent through Firebase Authentication, and contains a secure link that may look long. It should tell users to open the link only if they just requested it. After a successful request, the app should restate the expected sender and explain that the request can safely be ignored if it was not initiated by the user.

> The link is deliberately long because it contains a one-time account-security code. A familiar-looking short link would not make password recovery safer.

## Available Firebase template improvement

The owner can edit the **Email address verification** and **Password reset** templates in **Firebase Console → Security → Authentication → Templates** at no cost. The subject and body should identify **Expense Ledger** clearly and avoid technical implementation wording. This improves recognition, but it does not replace Firebase’s default action-link domain.

Suggested template language is: “You requested this secure link for your Expense Ledger account. If you did not request it, you can safely ignore this email.” The button or link target must remain the Firebase-generated action URL.

## Future upgrade path

The public DNS check on 20 August 2026 returned NXDOMAIN for both `expense-ledger.com` and `auth.expense-ledger.com`. If the owner later acquires and configures a domain, Firebase supports a custom authentication email domain after TXT/CNAME verification. Until then, the free default-link model is the secure choice.

## Acceptance criteria

The in-app request flow explains the expected Firebase email; the email template identifies Expense Ledger; the action link retains Firebase’s full one-time code; expired or used links retain Firebase’s safe failure state; and no verification or password-reset email is sent until the owner explicitly authorises the test.

## References

[1] [Firebase: Use a custom domain for Authentication emails](https://firebase.google.com/docs/auth/email-custom-domain)

[2] [Firebase: Generating email action links](https://firebase.google.com/docs/auth/admin/email-action-links)
