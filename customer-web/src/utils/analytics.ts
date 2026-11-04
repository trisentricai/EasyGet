/**
 * Analytics facade.
 *
 * The app only calls `trackEvent`; the sink is replaceable so GA4, Mixpanel,
 * or a first-party collector can be dropped in without touching the funnel
 * code. The default sink logs to the console, which also makes local QA and
 * Playwright assertions straightforward.
 */

export type AnalyticsProperties = Record<string, unknown>;

export type AnalyticsProvider = {
  track: (eventName: string, properties: AnalyticsProperties) => void;
};

const consoleProvider: AnalyticsProvider = {
  track(eventName, properties) {
    console.log(`[Analytics] ${eventName}`, properties);
  },
};

let provider: AnalyticsProvider = consoleProvider;

/** Swap the sink, or pass null to restore the console logger. */
export function setAnalyticsProvider(next: AnalyticsProvider | null): void {
  provider = next ?? consoleProvider;
}

/** Fire one funnel event. Call from the user action that owns it. */
export function trackEvent(
  eventName: string,
  properties: AnalyticsProperties = {},
): void {
  provider.track(eventName, properties);
}
