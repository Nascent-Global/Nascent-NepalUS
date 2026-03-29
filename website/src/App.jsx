import { Toaster } from "@/components/ui/toaster";
import { QueryClientProvider } from "@tanstack/react-query";
import { queryClientInstance } from "@/lib/query-client";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import PageNotFound from "./lib/PageNotFound";
import { AuthProvider, useAuth } from "@/lib/AuthContext";
import UserNotRegisteredError from "@/components/UserNotRegisteredError";
import { LanguageProvider } from "@/lib/LanguageContext";

import AppLayout from "@/components/layout/AppLayout";
import Dashboard from "@/pages/Dashboard";
import DailyLog from "@/pages/DailyLog";
import History from "@/pages/History";
import RelaxingSounds from "@/pages/RelaxingSounds";
import Pomodoro from "@/pages/Pomodoro";
import Psychologist from "@/pages/Psychologist";
import Education from "@/pages/Education";
import RadioProgram from "@/pages/RadioProgram";
import PsychologistDetail from "@/pages/PsychologistDetail";

const AuthenticatedApp = () => {
  const { isLoadingAuth, isLoadingPublicSettings, authError, navigateToLogin } =
    useAuth();

  if (isLoadingPublicSettings || isLoadingAuth) {
    return (
      <div className="fixed inset-0 flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-slate-200 border-t-slate-800 rounded-full animate-spin"></div>
      </div>
    );
  }

  if (authError) {
    if (authError.type === "user_not_registered") {
      return <UserNotRegisteredError />;
    } else if (authError.type === "auth_required") {
      navigateToLogin(window.location.href);
      return null;
    }
  }

  return (
    <Routes>
      <Route element={<AppLayout />}>
        <Route path="/" element={<Dashboard />} />
        <Route path="/log" element={<DailyLog />} />
        <Route path="/history" element={<History />} />
        <Route path="/sounds" element={<RelaxingSounds />} />
        <Route path="/pomodoro" element={<Pomodoro />} />
        <Route path="/psychologist" element={<Psychologist />} />
        <Route path="/psychologist/:id" element={<PsychologistDetail />} />
        <Route path="/education" element={<Education />} />
        <Route path="/education/radio-program" element={<RadioProgram />} />
      </Route>
      <Route path="*" element={<PageNotFound />} />
    </Routes>
  );
};

function App() {
  return (
    <AuthProvider>
      <LanguageProvider>
        <QueryClientProvider client={queryClientInstance}>
          <Router>
            <AuthenticatedApp />
          </Router>
          <Toaster />
        </QueryClientProvider>
      </LanguageProvider>
    </AuthProvider>
  );
}

export default App;
