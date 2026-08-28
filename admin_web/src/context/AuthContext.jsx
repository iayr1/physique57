import React, { createContext, useContext, useState, useEffect } from 'react';
import { auth, db } from '../firebase/config';
import {
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  onAuthStateChanged
} from 'firebase/auth';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  onSnapshot,
  serverTimestamp
} from 'firebase/firestore';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [currentUser, setCurrentUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [authError, setAuthError] = useState(null);

  // Initialize and listen to Firebase Auth & Firestore live user session
  useEffect(() => {
    // Ensure localStorage is cleared - everything is managed in Firestore database
    try {
      if (typeof window !== 'undefined' && window.localStorage) {
        window.localStorage.clear();
      }
    } catch (_) {}

    // Listen to Firebase Auth state
    const unsubscribeAuth = onAuthStateChanged(auth, async (fbUser) => {
      if (fbUser && fbUser.email) {
        try {
          const adminDocRef = doc(db, 'admins', fbUser.email.toLowerCase());
          const adminSnap = await getDoc(adminDocRef);

          if (adminSnap.exists() && adminSnap.data()?.sessionActive) {
            const data = adminSnap.data();
            setCurrentUser({
              email: fbUser.email,
              name: data.name || fbUser.displayName || 'System Administrator',
              role: data.role || 'admin',
              department: data.department || 'Executive Board',
              uid: fbUser.uid,
              lastLogin: data.lastLogin || new Date().toISOString(),
            });
          }
        } catch (err) {
          console.warn('Firestore session fetch error:', err);
        }
      }
      setLoading(false);
    });

    // Also check Firestore admin session directly in database
    const checkFirestoreSession = async () => {
      try {
        const adminDocRef = doc(db, 'admins', 'admin@gmail.com');
        const adminSnap = await getDoc(adminDocRef);
        if (adminSnap.exists() && adminSnap.data()?.sessionActive) {
          const data = adminSnap.data();
          setCurrentUser({
            email: 'admin@gmail.com',
            name: data.name || 'Executive Administrator',
            role: data.role || 'Super Administrator',
            department: data.department || 'Executive Board',
            uid: 'ADMIN-ROOT-001',
            lastLogin: data.lastLogin || new Date().toISOString(),
          });
        }
      } catch (_) {}
      setLoading(false);
    };

    checkFirestoreSession();

    return () => unsubscribeAuth();
  }, []);

  const login = async (email, password) => {
    setLoading(true);
    setAuthError(null);

    const cleanEmail = email.trim().toLowerCase();
    const cleanPassword = password.trim();

    try {
      // 1. Verify admin credentials: admin@gmail.com / admin123
      if (cleanEmail === 'admin@gmail.com' && cleanPassword === 'admin123') {
        const adminDocRef = doc(db, 'admins', 'admin@gmail.com');

        // Store and activate session directly in Firestore database
        const adminData = {
          email: 'admin@gmail.com',
          name: 'Executive Administrator',
          role: 'Super Administrator',
          department: 'Executive Board',
          isActive: true,
          sessionActive: true,
          lastLogin: serverTimestamp(),
          updatedAt: serverTimestamp(),
        };

        await setDoc(adminDocRef, adminData, { merge: true });

        // Record in audit log in database
        const auditId = `AUD-${Date.now()}`;
        await setDoc(doc(db, 'audit_logs', auditId), {
          id: auditId,
          action: 'ADMIN_SIGN_IN',
          performedBy: 'admin@gmail.com',
          targetEmail: 'admin@gmail.com',
          details: 'Administrator logged in to Web Management Console',
          timestamp: serverTimestamp(),
        });

        // Attempt silent Firebase Auth sync if available
        try {
          await signInWithEmailAndPassword(auth, cleanEmail, cleanPassword);
        } catch (_) {}

        setCurrentUser({
          email: 'admin@gmail.com',
          name: 'Executive Administrator',
          role: 'Super Administrator',
          department: 'Executive Board',
          uid: 'ADMIN-ROOT-001',
          lastLogin: new Date().toISOString(),
        });

        setLoading(false);
        return { success: true };
      }

      // 2. Check if user exists in Firestore employees with admin role
      const empRef = doc(db, 'employees', cleanEmail);
      const empSnap = await getDoc(empRef);

      if (empSnap.exists()) {
        const empData = empSnap.data();
        if (empData.password === cleanPassword && (empData.role === 'admin' || empData.role === 'manager')) {
          const adminDocRef = doc(db, 'admins', cleanEmail);
          await setDoc(adminDocRef, {
            email: cleanEmail,
            name: empData.name || 'Administrator',
            role: empData.role,
            department: empData.department || 'Management',
            isActive: true,
            sessionActive: true,
            lastLogin: serverTimestamp(),
            updatedAt: serverTimestamp(),
          }, { merge: true });

          setCurrentUser({
            email: cleanEmail,
            name: empData.name,
            role: empData.role,
            department: empData.department,
            uid: empData.id || cleanEmail,
            lastLogin: new Date().toISOString(),
          });

          setLoading(false);
          return { success: true };
        }
      }

      // 3. Try Firebase Auth
      try {
        const cred = await signInWithEmailAndPassword(auth, cleanEmail, cleanPassword);
        const adminDocRef = doc(db, 'admins', cleanEmail);
        await setDoc(adminDocRef, {
          email: cleanEmail,
          name: cred.user.displayName || 'Administrator',
          role: 'admin',
          sessionActive: true,
          lastLogin: serverTimestamp(),
        }, { merge: true });

        setCurrentUser({
          email: cred.user.email,
          name: cred.user.displayName || 'Administrator',
          role: 'admin',
          uid: cred.user.uid,
          lastLogin: new Date().toISOString(),
        });

        setLoading(false);
        return { success: true };
      } catch (_) {
        throw new Error('Invalid email or password. Please use admin@gmail.com / admin123.');
      }
    } catch (err) {
      setAuthError(err.message);
      setLoading(false);
      return { success: false, error: err.message };
    }
  };

  const logout = async () => {
    try {
      if (currentUser?.email) {
        // Update database session state in Firestore
        const adminDocRef = doc(db, 'admins', currentUser.email.toLowerCase());
        await updateDoc(adminDocRef, {
          sessionActive: false,
          lastLogout: serverTimestamp(),
        });

        // Record in audit log in database
        const auditId = `AUD-${Date.now()}`;
        await setDoc(doc(db, 'audit_logs', auditId), {
          id: auditId,
          action: 'ADMIN_SIGN_OUT',
          performedBy: currentUser.email,
          targetEmail: currentUser.email,
          details: 'Administrator signed out of Web Console',
          timestamp: serverTimestamp(),
        });
      }
    } catch (_) {}

    try {
      await firebaseSignOut(auth);
    } catch (_) {}

    setCurrentUser(null);
  };

  return (
    <AuthContext.Provider value={{ currentUser, login, logout, loading, authError }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
