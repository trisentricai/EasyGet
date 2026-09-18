import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./styles.css";

function App() {
  return <main><p className="eyebrow">EASYGET ADMIN</p><h1>Operations start here.</h1><p>Admin dashboard foundation is ready for Phase 8.</p></main>;
}

createRoot(document.getElementById("root")!).render(<StrictMode><App /></StrictMode>);
