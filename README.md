# Custom Collage

Flutter photo collage editor with optional premium upgrade delivered through native in-app purchases.

## In-app purchase integration

- Uses the official [`in_app_purchase`](https://pub.dev/packages/in_app_purchase) plugin.
- Purchase orchestration lives in `lib/services/purchase_service.dart`.
- Premium entitlement is synced into the collage state via `ChangeNotifierProxyProvider` in `lib/main.dart`.
- The account screen (`lib/screens/profile_screen.dart`) now lists the available products and launches purchases or restore flows.

### Configure store products

1. Create subscription products in both Play Console and App Store Connect that match the IDs used in `_plans`:
   - `collage_pro_weekly`
   - `collage_pro_monthly`
   - `collage_pro_yearly`
   Feel free to rename these IDs in both the store dashboards and the `_PlanOption` definitions if you prefer different identifiers.
2. On Android, submit at least one test release to the Play Store and add your testers to the license testers list so subscriptions can be purchased in the dev build.
3. On iOS, enable the `In-App Purchase` capability for the Runner target and add the products inside App Store Connect. Use Sandbox tester accounts to validate the flow.
4. After provisioning the products, run `flutter pub get` (on a host machine with Flutter installed) to pull the updated dependencies and regenerate platform build files.

### Testing tips

- Use the “Restore purchases” link at the bottom of the account screen to trigger `restore()` when testing with iOS sandbox accounts.
- The UI disables purchase buttons while the store is processing a transaction and surfaces error feedback via snack bars.
- Run the app on physical devices and sign into a sandbox/test account for realistic billing flows.

### Next steps

- Replace the placeholder pricing copy in `_PlanOption` with the actual localized pricing from your store listings once the products are live.
- Wire your backend receipt validation or server-side verification if needed before shipping to production.
