import { Component, type ErrorInfo, type ReactNode } from "react";
import { navigate } from "../hooks/useHashRoute";
import { EmptyState } from "./ui";

type Props = { children: ReactNode };
type State = { hasError: boolean };

/**
 * Route-level crash barrier. A rendering error in a page shows a friendly
 * recovery screen while the header, footer and bottom nav stay usable.
 *
 * No external reporting yet — the component stack is logged to the console.
 */
export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false };

  static getDerivedStateFromError(): State {
    return { hasError: true };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error("EASYGET route error:", error, info.componentStack);
  }

  private goHome = () => {
    this.setState({ hasError: false });
    navigate("home", { replace: true });
  };

  render() {
    if (!this.state.hasError) return this.props.children;

    return (
      <div className="page" role="alert">
        <EmptyState
          icon="warning"
          title="Something went wrong"
          text="An unexpected error stopped this page from loading. Your cart is safe."
          action={
            <div className="form-actions" style={{ justifyContent: "center" }}>
              <button className="btn btn-primary" onClick={() => window.location.reload()}>
                Reload
              </button>
              <button className="btn" onClick={this.goHome}>
                Go home
              </button>
            </div>
          }
        />
      </div>
    );
  }
}
