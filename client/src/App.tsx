/**
 * Ink & Ledger design system: warm paper surfaces, editorial hierarchy, and a
 * restrained Ledger Gold accent. Keep application chrome deliberately quiet.
 */
import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import Home from "@/pages/Home";
import ErrorBoundary from "./components/ErrorBoundary";
import { ThemeProvider } from "./contexts/ThemeContext";

export default function App() {
  return (
    <ErrorBoundary>
      <ThemeProvider defaultTheme="light">
        <TooltipProvider>
          <Home />
          <Toaster position="bottom-right" richColors />
        </TooltipProvider>
      </ThemeProvider>
    </ErrorBoundary>
  );
}
