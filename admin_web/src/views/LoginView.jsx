import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { ShieldCheck, Lock, Mail, ArrowRight, Eye, EyeOff, Sparkles, CheckCircle2 } from 'lucide-react';

export const LoginView = () => {
  const { login, loading, authError } = useAuth();
  const [email, setEmail] = useState('admin@gmail.com');
  const [password, setPassword] = useState('admin123');
  const [showPassword, setShowPassword] = useState(false);
  const [errorMsg, setErrorMsg] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErrorMsg(null);
    if (!email.trim() || !password.trim()) {
      setErrorMsg('Please enter both email and password.');
      return;
    }

    const res = await login(email, password);
    if (!res.success) {
      setErrorMsg(res.error || 'Authentication failed. Please verify credentials.');
    }
  };

  const autofillCredentials = () => {
    setEmail('admin@gmail.com');
    setPassword('admin123');
    setErrorMsg(null);
  };

  return (
    <div className="min-h-screen w-full bg-slate-50 flex items-center justify-center p-4 sm:p-6 lg:p-8 font-sans selection:bg-blue-600 selection:text-white">
      <div className="w-full max-w-5xl bg-white rounded-3xl border border-slate-200/80 shadow-soft-lg overflow-hidden grid grid-cols-1 lg:grid-cols-2">
        {/* Left Side: Hero Image Banner */}
        <div className="relative hidden lg:flex flex-col justify-between p-10 text-white bg-slate-900 overflow-hidden">
          <img
            src="/banner.jpg"
            alt="Physique 57 Studio"
            className="absolute inset-0 w-full h-full object-cover opacity-50"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-900/80 to-blue-950/60" />

          {/* Top Brand Logo */}
          <div className="relative z-10 flex items-center gap-3">
            <img
              src="/logo.jpg"
              alt="Physique 57 Logo"
              className="h-12 w-12 rounded-2xl object-cover border border-white/40 shadow-lg"
            />
            <div>
              <h3 className="text-lg font-extrabold tracking-tight">Physique 57</h3>
              <p className="text-xs text-blue-200 font-medium">Boutique Fitness Studio Portal</p>
            </div>
          </div>

          {/* Bottom Quote & Tagline */}
          <div className="relative z-10 space-y-3">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/15 backdrop-blur-md text-xs font-bold text-blue-100 border border-white/20">
              <Sparkles className="w-3.5 h-3.5 text-blue-300 animate-pulse" />
              <span>Enterprise Admin Portal</span>
            </div>
            <h2 className="text-2xl font-extrabold leading-snug">
              Empowering Staff Performance & Real-time Operations
            </h2>
            <p className="text-xs text-slate-300 font-medium leading-relaxed">
              Seamlessly manage staff attendance, task delegation, leave approvals, and company broadcasts with high-speed cloud sync.
            </p>
          </div>
        </div>

        {/* Right Side: Login Form */}
        <div className="p-6 sm:p-10 flex flex-col justify-center">
          {/* Mobile Logo */}
          <div className="lg:hidden text-center mb-6">
            <img
              src="/logo.jpg"
              alt="Physique 57"
              className="h-16 w-16 rounded-2xl object-cover mx-auto mb-3 shadow-md border border-slate-100"
            />
            <h1 className="text-xl font-extrabold text-slate-900 tracking-tight">Physique 57 ERMS</h1>
            <p className="text-xs text-slate-500 font-medium mt-0.5">Enterprise Management Console</p>
          </div>

          <div className="mb-6">
            <h2 className="text-xl font-extrabold text-slate-900">Administrator Sign In</h2>
            <p className="text-xs text-slate-500 font-medium mt-1">
              Enter your credentials to access system management
            </p>
          </div>

          {/* Quick Demo Helper Box */}
          <div className="mb-6 p-3.5 rounded-2xl bg-blue-50/80 border border-blue-100 flex items-center justify-between text-xs">
            <div className="flex items-center gap-2 text-blue-900">
              <Sparkles className="w-4 h-4 text-blue-600 shrink-0" />
              <div>
                <p className="font-bold">Authorized Admin Account:</p>
                <p className="text-blue-700 font-mono text-[11px]">admin@gmail.com / admin123</p>
              </div>
            </div>
            <button
              type="button"
              onClick={autofillCredentials}
              className="px-2.5 py-1 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition-colors shadow-xs shrink-0 cursor-pointer"
            >
              Fill In
            </button>
          </div>

          {/* Error Message */}
          {(errorMsg || authError) && (
            <div className="mb-5 p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-xs font-semibold text-rose-700 flex items-start gap-2.5">
              <div className="h-1.5 w-1.5 rounded-full bg-rose-600 mt-1.5 shrink-0" />
              <p>{errorMsg || authError}</p>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Email Field */}
            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                Admin Email Address
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                  <Mail className="w-4.5 h-4.5" />
                </div>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@gmail.com"
                  required
                  className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 placeholder:text-slate-400 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white transition-all"
                />
              </div>
            </div>

            {/* Password Field */}
            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                Password
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                  <Lock className="w-4.5 h-4.5" />
                </div>
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  className="w-full pl-10 pr-10 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 placeholder:text-slate-400 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:bg-white transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute inset-y-0 right-0 pr-3.5 flex items-center text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading}
              className="w-full mt-2 py-3 px-4 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-bold rounded-xl shadow-md shadow-blue-500/25 flex items-center justify-center gap-2 transition-all duration-150 disabled:opacity-60 cursor-pointer"
            >
              {loading ? (
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  <span>Verifying Session...</span>
                </div>
              ) : (
                <>
                  <span>Sign In to Admin Portal</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>

          {/* Security Banner */}
          <div className="mt-6 pt-5 border-t border-slate-100 flex items-center justify-center gap-2 text-xs text-slate-400 font-medium">
            <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
            <span>256-bit Encrypted Enterprise Connection</span>
          </div>
        </div>
      </div>
    </div>
  );
};
