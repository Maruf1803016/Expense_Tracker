// Ink & Ledger account context: a quiet, explicit boundary between the demonstration fieldbook and a signed-in cloud ledger.
import {
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  reload,
  sendEmailVerification,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  type User,
} from "firebase/auth";
import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { firebaseAuth } from "@/lib/firebase";

type AuthOperation = "signIn" | "signUp" | "passwordReset" | "verification";

interface AuthContextValue {
  user: User | null;
  loading: boolean;
  error: string | null;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string) => Promise<void>;
  sendVerification: () => Promise<void>;
  refreshVerification: () => Promise<void>;
  requestPasswordReset: (email: string) => Promise<void>;
  signOut: () => Promise<void>;
  clearError: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function friendlyAuthError(error: unknown, operation: AuthOperation) {
  const code = typeof error === "object" && error !== null && "code" in error ? String(error.code) : "";
  if (code === "auth/operation-not-allowed") return "This sign-in option is not available at the moment. Please try again later.";
  if (code === "auth/invalid-email") return "Enter a valid email address.";
  if (code === "auth/weak-password") return "Use a password with at least six characters.";
  if (code === "auth/email-already-in-use") return "An account already exists for this email. Sign in instead.";
  if (code === "auth/invalid-credential" || code === "auth/wrong-password" || code === "auth/user-not-found") return "The email address or password is not recognised.";
  if (code === "auth/too-many-requests") return "Too many attempts were made. Wait a moment, then try again.";
  if (code === "auth/requires-recent-login") return "For your security, sign in again before making this account change.";
  if (operation === "passwordReset") return "The password-reset email could not be sent. Check the address and try again.";
  if (operation === "verification") return "The verification email could not be sent. Check your connection and try again.";
  return operation === "signUp" ? "The account could not be created. Check your connection and try again." : "The session could not be opened. Check your connection and try again.";
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [accountRevision, setAccountRevision] = useState(0);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(
      firebaseAuth,
      (nextUser) => {
        setUser(nextUser);
        setLoading(false);
      },
      () => {
        setError("Your sign-in status could not be confirmed. Check your network and refresh the page.");
        setLoading(false);
      },
    );
    return unsubscribe;
  }, []);

  const value = useMemo<AuthContextValue>(() => ({
    user,
    loading,
    error,
    clearError: () => setError(null),
    signIn: async (email, password) => {
      setError(null);
      try {
        await signInWithEmailAndPassword(firebaseAuth, email.trim(), password);
      } catch (caught) {
        const message = friendlyAuthError(caught, "signIn");
        setError(message);
        throw new Error(message);
      }
    },
    signUp: async (email, password) => {
      setError(null);
      try {
        await createUserWithEmailAndPassword(firebaseAuth, email.trim(), password);
      } catch (caught) {
        const message = friendlyAuthError(caught, "signUp");
        setError(message);
        throw new Error(message);
      }
    },
    sendVerification: async () => {
      setError(null);
      const currentUser = firebaseAuth.currentUser;
      if (!currentUser) {
        const message = "Sign in before requesting a verification email.";
        setError(message);
        throw new Error(message);
      }
      if (currentUser.emailVerified) return;
      try {
        await sendEmailVerification(currentUser);
      } catch (caught) {
        const message = friendlyAuthError(caught, "verification");
        setError(message);
        throw new Error(message);
      }
    },
    refreshVerification: async () => {
      setError(null);
      const currentUser = firebaseAuth.currentUser;
      if (!currentUser) {
        const message = "Sign in before refreshing your account status.";
        setError(message);
        throw new Error(message);
      }
      try {
        await reload(currentUser);
        setAccountRevision((current) => current + 1);
      } catch (caught) {
        const message = friendlyAuthError(caught, "verification");
        setError(message);
        throw new Error(message);
      }
    },
    requestPasswordReset: async (email) => {
      setError(null);
      try {
        await sendPasswordResetEmail(firebaseAuth, email.trim());
      } catch (caught) {
        const message = friendlyAuthError(caught, "passwordReset");
        setError(message);
        throw new Error(message);
      }
    },
    signOut: async () => {
      setError(null);
      try {
        await firebaseSignOut(firebaseAuth);
      } catch {
        const message = "The session could not be closed. Check your connection and try again.";
        setError(message);
        throw new Error(message);
      }
    },
  }), [accountRevision, error, loading, user]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used inside AuthProvider.");
  return context;
}
