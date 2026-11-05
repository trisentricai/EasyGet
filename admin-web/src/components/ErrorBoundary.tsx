import { Component, ErrorInfo, ReactNode } from "react";
import { Card } from "./ui";

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false, error: null };

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error("ErrorBoundary caught:", error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }
      return (
        <div style={{ padding: 48, textAlign: "center" }}>
          <div style={{ fontSize: 48, marginBottom: 16 }}>🛠️</div>
          <h2 style={{ marginBottom: 8 }}>Something went wrong</h2>
          <p className="muted" style={{ marginBottom: 24 }}>
            We've logged this error. Please refresh the page.
          </p>
          <button className="btn btn-primary" onClick={() => window.location.reload()}>
            Refresh page
          </button>
          {this.state.error && (import.meta as any).env?.DEV && (
            <details style={{ marginTop: 24, textAlign: "left", maxWidth: 600, margin: "24px auto 0" }}>
              <summary className="muted" style={{ cursor: "pointer" }}>
                Error details (development only)
              </summary>
              <pre style={{ marginTop: 12, padding: 12, background: "var(--bg-sunken)", borderRadius: 8, overflow: "auto", fontSize: 12 }}>
                {this.state.error.toString()}
                {this.state.error.stack && `\n\n${this.state.error.stack}`}
              </pre>
            </details>
          )}
        </div>
      );
    }
    return this.props.children;
  }
}

export function withErrorBoundary<P extends object>(
  WrappedComponent: React.ComponentType<P>,
  fallback?: ReactNode,
) {
  return function WithErrorBoundary(props: P) {
    return (
      <ErrorBoundary fallback={fallback}>
        <WrappedComponent {...props} />
      </ErrorBoundary>
    );
  };
}