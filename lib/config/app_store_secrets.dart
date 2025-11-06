/// Provides build-time injected secrets for App Store receipt validation.
///
/// Declare these via `--dart-define` so that sensitive values are not baked
/// directly into source control. Example:
///
/// ```sh
/// flutter build ios --dart-define=APP_STORE_SHARED_SECRET=your_secret
/// ```
const String appStoreSharedSecret = String.fromEnvironment(
  'APP_STORE_SHARED_SECRET',
  defaultValue: '',
);
