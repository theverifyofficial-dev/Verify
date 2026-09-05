# Verify — Real Estate App (Flutter)

## Project Purpose

"Verify" (package `com.swaven.verifyapp`) is a real-estate-first consumer app with
secondary bolt-on modules: property browsing/search/booking, a paid yearly
"membership" that unlocks free property-visit booking (Razorpay), vehicle
verification (QR/RC scan), basic insurance and services listings, push
notifications for "vehicle alerts", and a legacy backend at
`verifyrealestateandservices.in` split across two technologies (see API
Architecture).

Users are consumers only (renters/buyers/tenants browsing and booking) — there
is no in-app role for property owners, brokers, or field workers to log in.
"Verification" is not a software workflow with a status field; it is
represented entirely by **field-worker attribution** baked into every
property record (see Business Domain below). There is no admin/back-office
UI in this codebase — that almost certainly lives in the PHP backend or a
separate internal tool, which is outside this repo.

## Business Domain: Field Workers & the "Verify" Model

Every property record (`detailed_property_model.dart`, `filter_model.dart`,
`search_model.dart`, `Office_model.dart`, etc.) carries a **field worker**
identity: `field_warkar_name`, `field_workar_number`, `fieldworkar_address`,
`field_worker_current_location` (note the inconsistent backend spelling
"workar"/"warkar", copied verbatim into Dart field names). This is the
concrete mechanism behind the brand name "Verify": a human field worker
physically visits/lists a property, and their name+number+location travel
with the listing as the trust signal shown to the user — there is no
separate verification status, badge state, or approval workflow in the
client. Property ids are keyed as `PVR_id` in most backend responses
(read here as "Property [Verification?] Record id" — not confirmed against
backend code, which this repo does not contain).

- **Booking a free visit** (`Visit Property/Visit Book.dart`) requires the
  user to pick a field worker from a **hardcoded, client-side list of 4
  names** (`fieldWorkerOptions`: Saurabh Yadav, Faizan Khan, Ravi Kumar,
  Yash) — this is not fetched from any API. Treat this list as stale the
  moment real staffing changes; there is no code path that keeps it in sync
  with whatever roster the backend/field app uses.
- **`Home.dart`'s featured-listings fetch is hardcoded to one field worker.**
  `fetchData()` calls
  `WebService4.asmx/show_RealEstate_by_fieldworkarnumber?fieldworkarnumber=9711775300`
  — a **literal phone number baked into the source**, not derived from the
  logged-in user or any selection. Every user, regardless of who they are,
  sees listings for the same single field worker on the home screen. This
  is very likely an unintended leftover from testing rather than intended
  business logic — flag to the user before assuming it's correct behavior.
- **Services module** (`Services/My_service.dart`) runs a 4-stage workflow —
  Pending/Waiting → Assigned → In Progress → Completed — driven by **4
  separate endpoints** (one per tab) rather than one endpoint with a status
  filter. Completion allows a rating (`insert_raiting.php`). Professionals
  are labeled "Verified Technician" in the UI, but as with properties this
  is a display label, not a driven-by-data verification state visible in
  the client.
- **Vehicle module** looks up a vehicle by RC number
  (`show_vehicle_details.php`) and lets the user send a "vehicle alert" SMS
  to the registered owner's mobile (`send_vehicle_alert.php`) — a
  lost/suspicious-vehicle notification flow, unrelated to real estate.

## Major Modules (`lib/Screens/`)

- **Real Estate/** — core browsing: `Home.dart`, `All property.dart`, `filter.dart`,
  `search_result.dart`, `wishlist.dart`. `Sub_Srceen/Types/` has one screen per
  property type (`Office.dart`, `shop.dart`, `Godown.dart`, `farmhouse.dart`,
  `flat/buy_flat.dart`, `flat/Rent_flat.dart`) — **these are heavily
  copy-pasted** (Office/shop/Godown/farmhouse are >50% textually identical).
  `Visit Property/` handles visit booking + membership gating.
- **Membership/** — `membership_page.dart`: yearly membership purchase via
  Razorpay. Newest module, currently mid-refactor (uncommitted at analysis
  time).
- **Vehicle/** — QR/RC scan + vehicle dashboard/results.
- **Services/**, **Insurace/** — secondary listing/booking flows.
- **Reset_password/** — OTP-based password reset via a third-party SMS API
  (2Factor.in), independent of the main login flow.
- **profile.dart** — account screen; also surfaces membership status/CTA.
- `lib/model/` — hand-written JSON model classes (no codegen).
- `lib/custom_widget/` — shared widgets. Note: `Paths.dart` despite its name
  only holds **asset** paths (images/icons), not API endpoints.
- `lib/utilities/` — `hex_color.dart` (`"#RRGGBB".toColor()` extension),
  `theme-helper.dart` (`AppColors.textColor/bgColor`), `membership_helper.dart`
  (SharedPreferences wrapper for membership status/expiry).

## Architecture

Flat, screen-centric. **No layered architecture** — no repository/service/DI
layer. Each screen's `State` class directly makes `http` calls, decodes JSON
inline, and reads/writes `SharedPreferences` itself. There is no shared
`ApiClient`/service class anywhere in the codebase (36 raw `http.get/post`
call sites across 29 files as of 2026-09-02, each hardcoding the full backend
URL — recount this before quoting it again, it drifts every time
`Visit Book.dart`/`profile.dart` get refactored).

## Authentication & Session

- Login: `LoginPage` (`Screens/Loginpage.dart`) POSTs mobile+password (+FCM
  token) to a PHP login endpoint. On success, the entire user record and a
  `login=true` bool are written straight into `SharedPreferences` (no token
  scheme — subsequent requests just embed the raw numeric `id`).
- `Splash.dart` is the sole router: reads `login` bool from SharedPreferences
  to decide `Homepage()` vs `LoginPage()` at app start.
- Logout (`profile.dart`) simply clears SharedPreferences.
- **No auth token/session header exists.** Server-side requests are
  authorized only by the client-supplied `id` — there is no bearer token,
  signed session, or equivalent. Treat any endpoint that accepts a raw
  `user_id`/`id` field as unauthenticated from the client's perspective.
- Password reset uses a **separate** OTP flow via 2Factor.in's SMS API
  (`forget.dart`, `otp.dart`), not the main backend.

## API / WebService Architecture

- **Backend is actually two different technologies behind one domain**,
  both at `verifyrealestateandservices.in`:
  - **Legacy PHP**, the vast majority of endpoints, organized in ad hoc
    folders reflected directly in URLs, e.g.
    `.../PHP_Files/Login_Main_App/Login_Main_APP.php`,
    `.../Second PHP FILE/book_shedual/{create_order,update_membership,verify_key_id}.php`,
    `.../Second PHP FILE/profie_image_update_main_realestate/<file>`.
  - **An ASP.NET `WebService4.asmx`** (classic ASMX web service, a distinct
    technology from the PHP files) used by exactly two call sites:
    `Home.dart` (`show_RealEstate_by_fieldworkarnumber`, see Business Domain
    above) and `Reset_password/forget.dart`
    (`CheckMobileNumber?FNumber=<number>`, used to validate a phone number
    exists before sending an OTP). Confirm with the backend owner whether
    ASMX is being phased out or is still actively maintained — it's a much
    older stack than the PHP side and a second surface to secure/patch.
- No shared client: every screen builds its own `Uri.parse(...)` +
  `http.post/get`. No centralized timeout/retry/error normalization.
- No auth headers are sent; identity travels as a plain field in the request
  body (e.g. `user_id`, `id`).
- Membership/payment endpoints of note:
  - `verify_key_id.php` — returns the Razorpay `key_id` to the client.
  - `update_membership.php` — client calls this directly after Razorpay's
    **client-side** success callback. **Verified against the current working
    tree (2026-09-02): the POST body is `id`, `membership_status`,
    `membership_expiry_date`, `family_structure`, `family_member` — it does
    NOT include `paymentId`, `order_id`, or any Razorpay signature at all.**
    `response.paymentId` is read in `_handlePaymentSuccess` but then
    discarded rather than forwarded. `membership_expiry_date` is a
    client-computed `DateTime.now() + 365 days`, and `amountInPaise` is a
    client-computed value passed straight into the Razorpay checkout
    options with no server-created order. This means, purely from the
    Flutter code, any authenticated user (or anyone who can reach this
    endpoint with a valid `id`) can set their own membership to active for
    a year with **no Razorpay interaction required at all** — the app never
    proves a payment happened. This is worse than "likely forgeable"; it's
    forgeable by construction unless `update_membership.php` independently
    re-verifies something the client isn't sending (unlikely, since the
    client sends nothing to verify). Treat as confirmed-severity, not
    suspected, until the PHP source says otherwise.
  - `create_order.php` — despite the name, in the current (uncommitted)
    refactor this is used for a **free** visit booking, not a paid order; an
    older paid-order version of this flow existed before the refactor.
- Third-party APIs called directly from the client (not proxied): 2Factor.in
  SMS (OTP), Google Places Autocomplete (`Booking_form.dart`), Google Maps
  (via API key in `AndroidManifest.xml`, same key referenced from
  `Booking_form.dart`).

## Models & Data Flow

- `lib/model/*.dart` — plain hand-written classes with `FromJson` factories,
  no `json_serializable`/`freezed`. Fields are almost all `String`-typed even
  for numeric backend values.
- **Known fragile pattern:** some fields fall back to a numeric literal on a
  `String`-typed field, e.g. `All_model.dart`: `id: json['PVR_id'] ?? 0` where
  `id` is declared `String`. Because the RHS is `dynamic`, this compiles but
  throws a runtime cast error the first time the API omits that key. Check
  for this pattern (`?? 0` / `?? false` assigned into `String` fields) before
  trusting any model's null-safety.
- Data generally flows: PHP endpoint → raw `Map<String,dynamic>` via
  `jsonDecode` → manually mapped into a model class → used directly in
  widget `build()`. No caching layer.

## State Management

- Pure `StatefulWidget` + `setState`. **`provider` is a declared dependency
  in `pubspec.yaml` but is not actually used anywhere in the code** (only a
  commented-out reference remains in `Splash.dart`) — it's dead weight, not
  an active pattern. Don't assume any global app state container exists;
  each screen re-reads `SharedPreferences` independently when it needs
  session/membership data.

## Local Storage / Session

- `shared_preferences` is the only persistence mechanism used for
  session/user data. Keys in use: `login` (bool), `name`, `email`, `number`,
  `id` (int), `fcm_token`, `profile_image_url`, plus `membership_status` and
  `membership_expiry_date` (owned by `MembershipHelper`, values are the raw
  strings `membership_active` / `membership_expiry` / `no_membership`).
- No `flutter_secure_storage` or any encrypted storage is used anywhere,
  despite session/PII being persisted.

## Navigation

- Imperative `Navigator.push` / `Navigator.pushReplacement` with
  `MaterialPageRoute` throughout — no named routes, no `go_router`.
- `Homepage.dart` is the post-login shell: a 2-tab `PageView`
  (`Home`, `Profile`) driven by a `BottomNavigationBar`, with a
  `WillPopScope` back-handler (Profile→Home, then Home→exit-confirm dialog).
- `Splash.dart` → `LoginPage` or `Homepage` is the only routing decision made
  outside a widget's own navigation calls.

## Android / iOS Configuration

- `applicationId` / iOS bundle: `com.swaven.verifyapp`.
- Signing: release signing config reads from `android/key.properties`
  (gitignored, not committed) — correct practice, keep it that way.
- **Release builds currently ship with `isMinifyEnabled = false` and
  `isShrinkResources = false`** (`android/app/build.gradle.kts`) — no R8/
  ProGuard shrinking or obfuscation, so any embedded API key or endpoint is
  trivially recoverable from a shipped APK.
- Firebase config files (`android/app/google-services.json`,
  `ios/Runner/GoogleService-Info.plist`) **are committed to git** (this is
  common practice for Firebase client configs, not a secret leak by itself,
  but be aware they're tracked).
- Firebase Messaging: background handler in `main.dart` shows a high-priority
  "Vehicle Alert" local notification (channel `vehicle_alerts_v2`); app
  subscribes to FCM topic `wollengod` on init.
- `flutter_launcher_icons` configured against `assets/images/VerifyLogo.png`.

## Build / Deployment

- `pubspec.yaml` version format `1.0.2+N` (build number bumped per release;
  currently mid-bump in working tree, from `+8` to `+10`).
- No CI config or test suite beyond the default `test/widget_test.dart`
  counter stub — there is effectively **no automated test coverage**,
  including for the login, booking, and payment flows.
- `analysis_options.yaml` just includes `flutter_lints` defaults, no custom
  rules enabled/disabled.

## Known Security Issues (do not "fix" silently without flagging to user — several require backend changes)

1. **Membership payment is forgeable by construction, confirmed from source
   (2026-09-02).** `update_membership.php` is called with no `paymentId`,
   no `order_id`, and no signature — see API Architecture above for the
   exact POST body. The client never proves a payment occurred. This is a
   confirmed finding, not a guess, and is the single highest-priority item
   in this codebase if membership revenue matters.
2. **Membership/visit-booking gate is client-side only.** `Visit Book.dart`
   checks `MembershipHelper.isActive()` locally before allowing a booking
   POST; nothing in the request proves membership server-side.
3. **Hardcoded, duplicated third-party API key.** The 2Factor.in SMS API key
   is hardcoded identically in both `Reset_password/forget.dart` and
   `Reset_password/otp.dart`. It's extractable from the shipped app and
   currently has no server-side proxy.
4. **Google Places API key called directly from the client**
   (`Services/Booking_form.dart`), same key as in `AndroidManifest.xml`.
   Confirm it's restricted (package+SHA-1 / bundle ID, API-restricted)
   before assuming it's safe.
5. **No code shrinking/obfuscation on release Android builds** (see above),
   compounding 3 and 4.
6. **Debug logging leaks response data** — e.g. `Loginpage.dart` prints the
   full login API response (`print(data)`) to device logs. ~26 `print`/
   `debugPrint` calls exist across the app; audit before release builds.
7. No auth token/session scheme — all "authorization" is a client-supplied
   `id`/`user_id` field (see Authentication section).
8. **`Home.dart` leaks a hardcoded field-worker phone number into the
   featured-listings API call** (`fieldworkarnumber=9711775300`) — not a
   confidentiality issue since it's a business phone number, but it's a
   functional bug that likely means the home screen shows the wrong/static
   data to every user (see Business Domain section). Flag to the user; this
   reads like leftover test code rather than intended behavior.
9. **`verify-upload-cert.pem` is a tracked, modified file in the working
   tree** (`git diff --stat` shows it changed alongside the membership
   refactor). It is a certificate, not necessarily a private key, but
   confirm with the user what it is and whether it belongs in git before
   touching it — do not inspect or repeat its contents without asking.

## Known Technical Debt / Risky Areas

- Heavy copy-paste across property-type screens (`Office.dart`, `shop.dart`,
  `Godown.dart`, `farmhouse.dart`) — good candidate to unify, but any fix
  must be requested/approved before touching (per user's standing
  instruction not to modify source).
- `provider` dependency is unused dead weight — either wire it up or drop it,
  don't assume it's doing anything today.
- As of 2026-09-02: `membership_page.dart` and `membership_helper.dart` are
  **staged** as new files; `Loginpage.dart`, `membership_page.dart` (further
  edits on top of the staged version), `Visit Book.dart`, `profile.dart`,
  `pubspec.yaml`, and `verify-upload-cert.pem` are modified but **unstaged**.
  `Visit Book.dart` shrank by ~2000 lines in this diff (paid-order flow
  removed in favor of the free-visit flow described above). Check
  `git status`/`git diff` before assuming the current working tree matches
  the last commit — this area changes fast.
- Inconsistent JSON null-fallback typing in models (see Models section) —
  a recurring source of latent runtime crashes.
- No repository/service abstraction — any change touching API calls means
  grepping across ~29 files rather than one client class.
- **Field-worker roster is hardcoded in two places independently**
  (`Visit Book.dart`'s 4-name list, `Home.dart`'s single hardcoded phone
  number) — see Business Domain section. Both are correctness bugs
  waiting to surface as stale data, not just style issues.

## Cross-App Relationship ("Verify Field" / wider Verify system)

This repository is the **consumer-facing** app only. There is no code in
this repo for a field-worker app, an owner/broker portal, or an internal
admin tool — if "Verify Field" exists as a separate Flutter/native app, its
source is not here and this analysis cannot see it. What this repo *does*
show about the wider system:

- **The only observable link is data, not code.** Every property, booking,
  and visit record carries field-worker identity fields (name, number,
  address, current location — see Business Domain). That data has to come
  from somewhere; the natural inference is a field-worker-facing app or
  admin tool writes it into the same PHP/ASMX backend this app reads from.
  Nothing in this repo confirms that, though — it's an inference from the
  shape of the data, not a verified fact.
- **No shared auth.** There's no token, API key, or shared identity scheme
  visible here that would let this app and a hypothetical field-worker app
  recognize each other's sessions — each would independently trust
  whatever `id` the backend hands back.
- **No shared package/module.** No monorepo markers, no shared Dart
  package, no common models directory referenced from outside `lib/`.
- **The field-worker roster is not wired up.** Both places this app needs a
  field worker (`Visit Book.dart`'s picker, `Home.dart`'s listings fetch)
  use a hardcoded name list or hardcoded number instead of querying a
  roster endpoint — so even if a "Verify Field" backend/roster exists, this
  app isn't currently consuming it dynamically.
- If the user confirms a separate Verify Field repo exists, the highest-value
  next step is comparing its API base URL and endpoint naming against this
  app's `verifyrealestateandservices.in` calls to see whether they already
  share a backend (likely, given the domain and folder-per-feature PHP
  layout) or are fully separate systems.

## Conventions & Dependencies Worth Knowing

- Color from hex string: `"#001234".toColor()` (extension in
  `utilities/hex_color.dart`) — used everywhere instead of `Color(0xFF...)`.
- Theme colors: `AppColors.textColor(context)` / `AppColors.bgColor(context)`
  (`utilities/theme-helper.dart`) — app is **fixed light theme only**
  (`main.dart` hardcodes `Brightness.light`), no dark mode.
- Key packages: `http` (raw REST), `shared_preferences`, `firebase_core` /
  `firebase_messaging` / `firebase_performance`, `razorpay_flutter`,
  `google_maps_flutter` + `geolocator`/`geocoding`, `mobile_scanner` (QR),
  `image_picker` + `flutter_image_compress`, `webview_flutter`,
  `speech_to_text`, `audio_waveforms`.
- Fonts: Poppins (Regular/Medium/Bold/Light) bundled locally.
- `assets/images/`, `assets/Icons/` are the only declared asset directories.

## For Future Claude Code Sessions

- Before touching any screen that does networking, check whether it's one of
  the ~29 files with inline `http` calls to `verifyrealestateandservices.in`
  — there is no shared client to update instead. Two of those calls
  (`Home.dart`, `Reset_password/forget.dart`) hit the older ASP.NET
  `WebService4.asmx` endpoint, not PHP — don't assume every backend call
  follows the PHP folder-per-feature URL pattern.
- Before trusting a model's parsed field, check its `FromJson` for
  type-mismatched `??` fallbacks.
- Don't assume `provider` is wired into anything — verify via grep before
  building on it.
- Payment/membership logic is the most security-sensitive and most actively
  changing area right now — always check `git status`/`git diff` on
  `Membership/`, `Visit Property/`, and `profile.dart` before reasoning
  about "current" behavior, since these have had large uncommitted
  refactors.
- Never hardcode a new secret/API key into Dart source — the app ships
  unobfuscated (see Build/Deployment) so anything embedded is effectively
  public.
