import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getAnalytics } from "firebase/analytics";
import { getStorage } from "firebase/storage";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyCflmR_9YJzJ0beM7KAjy6HIkC_mKFqFcg",
  authDomain: "travelbud-3ec6b.firebaseapp.com",
  projectId: "travelbud-3ec6b",
  storageBucket: "travelbud-3ec6b.firebasestorage.app",
  messagingSenderId: "380695043874",
  appId: "1:380695043874:web:8b367d1e78c7ae081f8f7b",
  measurementId: "G-906BZLFJ67"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize services
export const auth = getAuth(app);
export const analytics = getAnalytics(app);
export const storage = getStorage(app);
export const db = getFirestore(app);

export default app; 