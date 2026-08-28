import { initializeApp, getApps, getApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore, serverTimestamp, Timestamp } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyAjqJGjUWUHL3V2GuYRoRdPxqvHXLYs9ro",
  authDomain: "physique57-b0a01.firebaseapp.com",
  projectId: "physique57-b0a01",
  storageBucket: "physique57-b0a01.firebasestorage.app",
  messagingSenderId: "322561291239",
  appId: "1:322561291239:web:c766d7c258a42af7180342",
  measurementId: "G-2CL9LSN1YL"
};

// Initialize Firebase safely
const app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export { serverTimestamp, Timestamp };
export default app;
