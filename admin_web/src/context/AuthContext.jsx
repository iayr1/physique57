import React, { createContext, useContext, useState, useEffect } from 'react';
import { auth } from '../firebase/config';
import { signInWithEmailAndPassword, signOut as firebaseSignOut, onAuthStateChanged } from 'firebase/auth';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [currentUser, setCurrentUser] = useState(() => {
    const saved = localStorage.getItem('erms_admin_session');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch {
        return null;
      }
    }
    return null;
  });
  const [loading, setLoading] = useState(false);
  const [authError, setAuthError] = useState(null);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      if (user && user.email === 'admin@gmail.com') {
        const adminData = {
          email: user.email,
          name: user.displayName || 'System Administrator',
          role: 'admin',
          uid: user.uid,
          photoUrl: user.photoURL || '',
          lastLogin: new Date().toISOString()
        };
        setCurrentUser(adminData);
        localStorage.setItem('erms_admin_session', JSON.stringify(adminData));
      }
    });
    return () => unsubscribe();
  }, []);

  const login = async (email, password) => {
    setLoading(true);
    setAuthError(null);

    const cleanEmail = email.trim().toLowerCase();
    const cleanPassword = password.trim();

    try {
      // Check admin credentials specified: admin@gmail.com / admin123
      if (cleanEmail === 'admin@gmail.com' && cleanPassword === 'admin123') {
        const adminData = {
          email: 'admin@gmail.com',
          name: 'Executive Administrator',
          role: 'Super Administrator',
          department: 'Executive Board',
          uid: 'ADMIN-ROOT-001',
          lastLogin: new Date().toISOString()
        };
        setCurrentUser(adminData);
        localStorage.setItem('erms_admin_session', JSON.stringify(adminData));

        // Attempt silent Firebase Auth sync if account exists in Auth
        try {
          await signInWithEmailAndPassword(auth, cleanEmail, cleanPassword);
        } catch (_) {
          // Fallback accepted based on user specification
        }
        setLoading(false);
        return { success: true };
      }

      // Try standard Firebase Auth
      try {
        const cred = await signInWithEmailAndPassword(auth, cleanEmail, cleanPassword);
        const adminData = {
          email: cred.user.email,
          name: cred.user.displayName || 'System Administrator',
          role: 'admin',
          uid: cred.user.uid,
          lastLogin: new Date().toISOString()
        };
        setCurrentUser(adminData);
        localStorage.setItem('erms_admin_session', JSON.stringify(adminData));
        setLoading(false);
        return { success: true };
      } catch (fbErr) {
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
      await firebaseSignOut(auth);
    } catch (_) {}
    setCurrentUser(null);
    localStorage.removeItem('erms_admin_session');
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
