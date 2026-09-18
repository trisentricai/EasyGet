import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./styles.css";

function App() {
  return <main><p className="eyebrow">EASYGET</p><h1>Essentials, delivered quickly.</h1><p>Customer web foundation is ready for Phase 2.</p></main>;
}

createRoot(document.getElementById("root")!).render(<StrictMode><App /></StrictMode>);
