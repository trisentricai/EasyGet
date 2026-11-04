# EASYGET FRESH MARKET — COMPLETE FLUTTER ARCHITECTURE & CODEBASE SPECIFICATION
*Document Version: 3.0.0 (MNC Enterprise Quick-Commerce Specification)*
*Target Framework: Flutter 3.24+ / Dart 3.5+ with Riverpod 2.x and GoRouter*

---

## 1. DESIGN SYSTEM & DESIGN TOKENS SPECIFICATION

### 1.1 Color Palette (Normative Hex Values)
```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Light Palette — Warm Paper & Forest Leaf
  static const Color lightCanvas = Color(0xFFFAF6EF);       // Scaffold page background
  static const Color lightSurface = Color(0xFFFFFFFF);      // Cards, sheets, app bars
  static const Color lightSunken = Color(0xFFF1EAE0);       // Image wells, skeleton base
  static const Color lightInk = Color(0xFF1B1712);          // Primary body & title text
  static const Color lightMuted = Color(0xFF655D52);        // Secondary subtitle text (4.5:1 contrast)
  static const Color lightFaint = Color(0xFFA79C8F);        // Captions, borders, placeholders
  static const Color lightBorder = Color(0xFFE7DFD3);       // Hairline dividers
  static const Color lightBorderStrong = Color(0xFFD5C9B8); // Inputs & radio rings

  // Brand Accents
  static const Color brand = Color(0xFF0C3B2E);             // Deep Evergreen (headers, active tab, logo)
  static const Color primary = Color(0xFF0E7A4D);           // Live Leaf Green (ONLY BUY actions: CTA, add, in-stock)
  static const Color primaryDark = Color(0xFF0A5C3B);       // Pressed CTA fill
  static const Color primaryTint = Color(0xFFDDF0E4);       // Stepper fill, chips, active pill wash
  static const Color marigold = Color(0xFFE79B12);          // ETA pill icon/text, rating stars
  static const Color marigoldWash = Color(0xFFFCEFD4);      // ETA pill background

  // System Feedback
  static const Color success = Color(0xFF15803D);           // Savings text, verified badges
  static const Color warning = Color(0xFFB45309);           // Low stock warnings
  static const Color danger = Color(0xFFB91C1C);            // Error alerts, cancel order, remove

  // Dark Palette — Warm Charcoal (Not pure black)
  static const Color darkCanvas = Color(0xFF12110F);
  static const Color darkSurface = Color(0xFF1B1A17);
  static const Color darkSunken = Color(0xFF26241F);
  static const Color darkInk = Color(0xFFF4EFE7);
  static const Color darkMuted = Color(0xFFA79C8F);
  static const Color darkFaint = Color(0xFF6F675C);
  static const Color darkBorder = Color(0xFF2B2823);
  static const Color darkBorderStrong = Color(0xFF3E3A33);
  static const Color darkPrimary = Color(0xFF3AA76D);       // Lightened for 4.5:1 dark contrast
  static const Color darkPrimaryTint = Color(0xFF14342A);
  static const Color darkMarigold = Color(0xFFFFB020);
  static const Color darkMarigoldWash = Color(0xFF3A2C10);
}
```

### 1.2 Typography Rules
- **Display / Headings**: Google Fonts `Fraunces` (weights 500 and 600, serif, tracking `-0.5`, line-height `1.15`). Used **only** on hero titles, section headlines, brand logo, and story text.
- **UI / Product Names / Body**: Google Fonts `Inter` (weights 400, 500, 600, 700, sans-serif). Product names **never** use serif.
- **Tabular Figures Law**: **Every single numeric value** (prices, quantities, ETAs, timestamps, order IDs, rating scores, pin codes) **MUST** set `FontFeature.tabularFigures()`. Prices in columns must align strictly.

```dart
// lib/core/theme/app_typography.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle displayHero(Color color) => GoogleFonts.fraunces(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.15,
    color: color,
  );

  static TextStyle screenTitle(Color color) => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.25,
    color: color,
  );

  static TextStyle productName(Color color) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    height: 1.3,
    color: color,
  );

  static TextStyle tabularPrice(Color color, {double size = 16, FontWeight weight = FontWeight.w700}) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: -0.2,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color,
  );
}
```

### 1.3 Spacing, Radii & Touch Target Law
- **Spacing Grid**: 4pt base (`4, 8, 12, 16, 20, 24, 32, 48` dp).
- **Radii**: Card = `18.0`, Image well = `14.0`, Primary CTA = `16.0`, Input = `14.0`, Modal/Bottom Sheet = `24.0 top`, Pill/Badge = `999.0`.
- **Elevation**: Strict 1dp hairline border first. Product cards have **0 elevation** (Instacart shadow-free standard).
- **Touch Target**: Strict `48 × 48` dp minimum for every interactive stepper icon, back arrow, radio option, and chip.
- **Primary CTA**: Full-width, `54 dp` tall, radius 16, `#0E7A4D` fill, bottom-anchored above safe area.

---

## 2. PROJECT FOLDER STRUCTURE (FLUTTER)

```
lib/
├── main.dart
├── core/
│   ├── network/
│   │   ├── api_client.dart           // Dio wrapper with 90s/60s timeouts & auth interceptors
│   │   ├── api_endpoints.dart        // Static constants for all /api/v1/ routes
│   │   └── api_exception.dart        // Human error transformer (clean sentences, no codes)
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_theme.dart
│   ├── router/
│   │   └── app_router.dart           // GoRouter definition with StatefulShellRoute for 5 tabs
│   └── utils/
│       └── haptics.dart              // HapticFeedback wrapper
├── models/
│   ├── product.dart
│   ├── category.dart
│   ├── cart_item.dart
│   ├── order.dart
│   ├── address.dart
│   ├── coupon.dart
│   ├── notification.dart
│   └── user.dart
├── providers/
│   ├── auth_provider.dart
│   ├── cart_provider.dart
│   ├── wishlist_provider.dart
│   ├── address_provider.dart
│   ├── order_provider.dart
│   ├── coupon_provider.dart
│   ├── notification_provider.dart
│   └── connectivity_provider.dart    // Shaky 4G / Offline listener
├── shared_widgets/
│   ├── price_block.dart              // Tabular price + MRP strike + green savings
│   ├── rating_pill.dart              // Marigold star + tabular rating + review count
│   ├── product_card.dart             // Rail (148dp), Grid (2-col 4:5), Line (cart/order 76dp)
│   ├── sticky_bottom_cta.dart        // 54dp bottom-anchored full-width primary button
│   ├── custom_app_bar.dart           // Address row + 12-min ETA pill + bell badge
│   ├── bottom_nav_bar.dart           // 5 fixed tabs with primaryTint indicator wash
│   └── notification_drawer.dart      // Notification center bottom sheet & push toast banner
├── features/
│   ├── auth/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── otp_verify_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── catalog/
│   │   ├── browse_screen.dart
│   │   ├── search_screen.dart
│   │   └── pdp_screen.dart
│   ├── cart/
│   │   └── cart_screen.dart
│   ├── checkout/
│   │   └── checkout_screen.dart
│   ├── orders/
│   │   ├── orders_screen.dart
│   │   └── track_order_screen.dart
│   ├── account/
│   │   ├── account_screen.dart
│   │   └── addresses_screen.dart
│   ├── modals/
│   │   ├── gps_location_modal.dart
│   │   ├── rider_chat_modal.dart
│   │   ├── cancel_order_modal.dart
│   │   ├── rate_order_modal.dart
│   │   └── voice_search_modal.dart
│   └── exceptions/
│       ├── offline_screen.dart
│       ├── server_error_screen.dart
│       └── not_found_screen.dart
```

---

## 3. DATA MODELS (DART SPECIFICATION)

### 3.1 Product (`lib/models/product.dart`)
```dart
class Product {
  final String id;
  final String slug;
  final String name;
  final String category;
  final String weight;
  final int price;
  final int mrp;
  final String? savingsText;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final int stockQty;
  final bool isVeg;
  final String image;
  final List<String> gallery;
  final String description;
  final String story;
  final String origin;
  final String shelfLife;
  final List<String> dietaryTags;
  final List<NutritionItem> nutrition;

  Product({
    required this.id,
    required this.slug,
    required this.name,
    required this.category,
    required this.weight,
    required this.price,
    required this.mrp,
    this.savingsText,
    required this.rating,
    required this.reviewCount,
    required this.inStock,
    required this.stockQty,
    required this.isVeg,
    required this.image,
    required this.gallery,
    required this.description,
    required this.story,
    required this.origin,
    required this.shelfLife,
    this.dietaryTags = const [],
    required this.nutrition,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    slug: json['slug'],
    name: json['name'],
    category: json['category'],
    weight: json['weight'],
    price: json['price'],
    mrp: json['mrp'],
    savingsText: json['savings_text'],
    rating: (json['rating'] as num).toDouble(),
    reviewCount: json['review_count'],
    inStock: json['in_stock'],
    stockQty: json['stock_qty'],
    isVeg: json['is_veg'] ?? true,
    image: json['image'],
    gallery: List<String>.from(json['gallery'] ?? []),
    description: json['description'],
    story: json['story'],
    origin: json['origin'],
    shelfLife: json['shelf_life'],
    dietaryTags: List<String>.from(json['dietary_tags'] ?? []),
    nutrition: (json['nutrition'] as List? ?? [])
        .map((e) => NutritionItem.fromJson(e))
        .toList(),
  );
}

class NutritionItem {
  final String label;
  final String value;
  NutritionItem({required this.label, required this.value});
  factory NutritionItem.fromJson(Map<String, dynamic> json) => NutritionItem(
    label: json['label'],
    value: json['value'],
  );
}
```

### 3.2 Cart & Orders (`lib/models/order.dart` & `cart_item.dart`)
```dart
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});
}

class Order {
  final String id;
  final String date;
  final String status; // 'In Transit' | 'Delivered' | 'Cancelled'
  final int? etaMinutes;
  final List<CartItem> items;
  final int subtotal;
  final int discount;
  final int deliveryFee;
  final int riderTip;
  final List<String> deliveryInstructions;
  final int total;
  final Address address;
  final String paymentMethod;
  final List<OrderEvent> events;
  final String? driverName;
  final String? driverPhone;
  final String? driverVehicle;
  final int? driverRating;

  Order({
    required this.id,
    required this.date,
    required this.status,
    this.etaMinutes,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    this.riderTip = 0,
    this.deliveryInstructions = const [],
    required this.total,
    required this.address,
    required this.paymentMethod,
    required this.events,
    this.driverName,
    this.driverPhone,
    this.driverVehicle,
    this.driverRating,
  });
}

class OrderEvent {
  final String status;
  final String time;
  final String description;
  final bool completed;
  final bool current;

  OrderEvent({
    required this.status,
    required this.time,
    required this.description,
    required this.completed,
    required this.current,
  });
}
```

---

## 4. SCREEN-BY-SCREEN FUNCTIONAL BLUEPRINT

### S1 · Splash / Boot (`/`)
- **Visuals**: Full screen `#0C3B2E` brand evergreen background. Cream `EG` monogram (24dp radius), letterspaced "EASYGET Fresh Market" title. Bottom ETA pill: "10-Minute Doorstep Delivery".
- **Logic**:
  1. Check `SharedPreferences` for saved JWT access & refresh tokens.
  2. If tokens exist -> call `GET /users/me/`. If valid -> redirect to `/home`.
  3. If tokens don't exist -> redirect to `/home` (guest state) or `/login`.
  4. Timer threshold: max 1.2s splash duration (no lagging splash screens).

### S2 · Login (`/login`)
- **Visuals**: 72dp EG monogram -> "Welcome back" (Fraunces 28sp) -> Email input (with prefix mail icon) -> Password input with toggle obscure eye -> 54dp Primary CTA "Sign in" -> "Login via SMS / WhatsApp OTP" button -> "Continue as Guest Shopper" ghost button -> Link to `/register`.
- **Validation**: Email pattern regex, password length >= 6 chars.
- **API Call**: `POST /auth/login/` payload: `{ "email": "...", "password": "..." }`.
- **Cart Merge**: On login success, if local `guest_token` exists, trigger `POST /cart/merge/` to sync guest items into user account.

### S2b · WhatsApp / SMS OTP Verification (`/otp_verify`)
- **Visuals**: Smartphone shield illustration -> "Verify 4-Digit Code" -> Four individual digit input boxes with auto-advancing focus nodes and backspace pop -> 30-second countdown timer for resend -> "Verify & Enter Fresh Market" CTA.
- **Logic**: Auto-submits on 4th digit entered. On success, writes user session to Riverpod `authProvider` and navigates to `/home`.

### S3 · Register (`/register`)
- **Visuals**: Role selector segmented tab (Shopper / Customer vs. Artisan / Farm Merchant) -> Full Name -> Email -> Mobile Phone -> Password (8+ chars) -> 54dp CTA "Create Account".
- **API Call**: `POST /auth/register/` -> Auto-login on HTTP 201 Created -> Land `/home`.

### S4 · Home Storefront (`/home`, Tab 1)
- **Top AppBar**:
  - Left: Address selector row showing current area (e.g., "HSR Layout Sector 4") with chevron. Tap opens `GpsLocationModal`.
  - Right: Marigold wash ETA pill with pulsing clock icon ("12 min") + Notification bell with unread badge count. Tap bell opens `NotificationDrawer`.
- **Persistent Search Bar**: 50dp height, sunken fill, hint "Search atta, Gir cow milk, hass avocado..." + "10 MIN" green badge. Tapping navigates to `/search`.
- **Quiet Offer Ticker**: Single line: "Today's Fresh Code: Use FRESH20 for ₹50 off on farm orders" with View action.
- **Banner Carousel**: 16:7 aspect ratio edge-to-edge cards with micro-dots. Features Dawn Harvest and Fresh Churn stories.
- **Shop by Aisle Grid**: 3-column / 6-column category cards with 1:1 image wells and item counters (Fresh Vegetables, Farm Dairy, Artisan Bakes, Cold Pressed Juices, Organic Grains, Dry Fruits).
- **Product Rails (Horizontal 148dp Cards)**:
  - Rail 1: "Fresh Picks at Dawn" (Hass Avocado, Sweet Berries, Hydroponic Tomatoes).
  - Rail 2: "Heritage & Cold Pressed" (A2 Gir Cow Milk, Wood Pressed Sesame Oil, Wildflower Honey).
  - Rail cards feature: 1:1 image well, RatingPill, veg dot, 2-line clamp title, PriceBlock (price + MRP + save %), and Add-to-stepper morph button.
- **Editorial Store Story Block**: Image + Fraunces serif statement: *"We harvest in the pre-dawn mist so your breakfast table tastes like the orchard."* + Traceability badges.

### S5 · Browse / PLP (`/browse`, Tab 2)
- **Sticky Category Chips**: Horizontal chip scroll bar pinned under app bar ("All Aisles", "Produce", "Dairy", "Bakery", etc.).
- **Toolbar**: Item counter ("Showing 9 items") + "Filter" button (with active badge) + "Sort" dropdown button.
- **Product Grid**: 2 columns, 12dp grid spacing. 4:5 image wells.
- **Filter Bottom Sheet**:
  - Switch: Vegetarian Only.
  - Switch: In Stock Immediately.
  - Dietary lifestyle chips: Organic Certified, Gluten-Free, Vegan, Cold-Pressed.
  - Actions: "Clear All" and "Apply Filters".
- **Sort Bottom Sheet**:
  - Radio options: Relevance, Highest Rated, Price: Low to High, Price: High to Low.
- **Empty State**: Illustrated icon + "No items in this filter" + "Reset Filters" primary button.

### S6 · Search & Discovery (`/search`, Tab 3)
- **Input Bar**: Auto-focused search field + clear `X` button + microphone icon for Voice Search.
- **Voice Search Modal (`VoiceSearchModal`)**: Tapping the mic opens a soundwave modal that simulates voice detection (*"Listening... say 'Avocado' or 'Gir cow milk'"*) and auto-populates query.
- **Empty Query View**:
  - Recent searches as removable pill chips (e.g., "Avocado", "A2 Gir Cow Milk").
  - Trending search queries ranked 01 to 05 with "12 MIN" badges.
  - "Popular in Your Neighborhood" 2-column recommendations grid.
- **Active Query View**: Real-time debounced (300ms) query matching against product titles, categories, origins, and descriptions.

### S7 · Product Detail / PDP (`/product/:slug`)
- **1:1 Image Gallery**: Edge-to-edge swipeable carousel with indicator dots. Top-right floating Wishlist heart toggle and Share button. Top-left green VEG badge.
- **Title Block**: Origin & shelf-life subtitle -> Inter 20sp bold name -> RatingPill (tap opens reviews) -> PriceBlock with savings badge -> Pack Option selector (Standard vs. Family Pack 2x with auto-calculated discount).
- **Delivery Row**: Marigold wash pill ("12-Minute Delivery") + "Delivering to pincode 560102" with inline "Change" dialog.
- **"The Story" Block**: Editorial farm provenance paragraph + harvesting details.
- **Nutrition Grid**: 4-column cards displaying Calories, Healthy Fats, Fiber, and Key Minerals.
- **Trust Badges**: 100% Traceable, Quality Checked at 4°C, Zero Preservatives.
- **Sticky Bottom Thumb Zone Bar**: Total price preview left + 52dp Add-to-stepper button right.

### S8 · Cart & Vouchers (`/cart`, Tab 4)
- **ETA Banner**: "Guaranteed 12-Minute Delivery · Free over ₹300".
- **Free Delivery Progress Bar**: Dynamic progress meter showing `₹{cartSubtotal}/₹300` and remaining gap.
- **Line Item Cards**: 76dp thumbnail left, product name, weight, and PriceBlock center, interactive `- [qty] +` stepper right. Decreasing to 0 triggers remove item.
- **Coupon Row**:
  - Applied state: Green badge with code, savings amount, and "Remove" button.
  - Unapplied state: "Apply Coupon or Voucher" trigger.
  - Coupon Sheet: Lists active vouchers (`FRESH20` for ₹50 off, `MORNING10` for ₹30 off, `FIRSTGET` for ₹75 off) with manual code text input.
- **Out-of-Stock Substitution Preference**: Radio selector for dark store item fulfillment:
  - `📞 Call me`
  - `🔄 Best match`
  - `💵 Refund directly`
- **Tabular Bill Summary**:
  - Item Subtotal (tabular font)
  - Coupon Discount (green, tabular font)
  - Delivery Fee (FREE or ₹25)
  - Rider Tip (if selected)
  - Total To Pay (bold tabular font)
- **Sticky Bottom CTA**: 54dp full-width "Proceed to checkout" button showing live total price.

### S9 · Checkout & Slot Booking (`/checkout`)
- **Numbered Steps Progress**: `1 Address -> 2 Time Slot -> 3 Payment`.
- **Address Card**: Radio card showing selected address details + "Change" button linking to Address Book.
- **Slot Selector (Instacart Pattern)**:
  - Day selector: "Today (Instant / Slotted)" vs. "Tomorrow Morning".
  - Time window radio cards: "10-Minute Express (8:30 - 8:45 AM)", "Morning Slot", "Midday Slot", "Evening Harvest".
- **Payment Method**:
  - UPI Instant (Google Pay, PhonePe, Paytm) — RECOMMENDED.
  - Credit / Debit Card.
  - Cash on Doorstep Handover (COD).
- **Delivery Instructions**: Toggle chips (*"🚪 Leave at door"*, *"🔕 Do not ring bell"*, *"📵 Avoid calling"*, *"🛡️ Hand to security"*, *"🐾 Pet at home"*).
- **Rider Tipping**: Tipping cards (`No tip`, `₹20`, `₹30`, `₹50`) with note *"100% goes directly to electric rider Ravi Kumar"*.
- **Sticky Bottom CTA**: "Place order · ₹X" with double-tap guard and idempotent order creation. On success, navigates to `/order/:id` with medium haptic feedback.

### S10 · Orders History (`/orders`, Tab 5)
- **Segmented Tabs**: "Active Orders" vs. "Past Orders".
- **Order Cards**:
  - Header: Tabular order ID (`#EG-9281`), date, and colored status pill (`In Transit` = Marigold Wash with spinning timer, `Delivered` = Green Wash, `Cancelled` = Neutral Wash).
  - Item Thumbs: Up to 3 item image thumbnails + overflow counter (e.g., `+2`).
  - Total paid in tabular figures.
  - Footer actions: "Track Live Progress" for active orders, "Reorder" 1-click button for delivered orders.

### S11 · Live Track Order & Timeline (`/order/:id`)
- **Status Hero**: `#0C3B2E` brand wash with live minutes & seconds countdown timer (`10:48 minutes away`), driver assignment details, and Ather 450X electric scooter badge.
- **Rider Contact Card**: Shows driver photo, name ("Ravi Kumar"), vehicle registration (`KA 01 EK 8812`), direct Phone Call button, and Live Chat button with green online dot.
- **Vertical Milestones Timeline**:
  - 1. Order Placed (time logged, completed).
  - 2. Packed with Care (chilled items packed, completed).
  - 3. Out for Delivery (rider en route, active pulsing node).
  - 4. Delivered to Doorstep (estimated time, pending).
- **Items & Receipt Breakdown**: Itemized list with quantities, unit prices, and payment receipt.
- **Actions**:
  - "Cancel Order" button for active orders (opens `CancelOrderModal`).
  - "Rate Produce & Rider Ravi Kumar" button for delivered orders (opens `RateOrderModal`).
  - "Reorder Fresh Items" 1-click button.

### S12 · Account & Preferences (`/account`)
- **Profile Monogram Card**: Avatar initials (`AS`), user name, phone number, and "Fresh Market Premium Member" badge.
- **Referral Banner**: "Invite friends, both get ₹100 grocery credit" with copyable referral voucher code (`ANANYA100`).
- **Account Actions**:
  - Delivery Pin & GPS Map (opens `GpsLocationModal`).
  - Saved Addresses (`/addresses`).
  - Notifications & Alerts (opens `NotificationDrawer`).
  - Coupons & Wallet.
- **Settings**:
  - Theme Appearance toggle (Light Warm Paper vs. Dark Warm Charcoal).
  - Doorstep Arrival Haptics toggle.
  - 24x7 Customer Help & FAQ dialog.
  - Sign Out (clears session, navigates to `/login`).

### S13 · Address Book (`/addresses`)
- **Saved Address Cards**: Radio selection cards with type icons (Home, Work, Other), street address, phone number, and "DEFAULT" badge.
- **"Add New Delivery Address" CTA**: Opens bottom sheet with inputs for Address Type, Label, House/Flat/Street, Area, Pincode, and Receiver Phone.

---

## 5. MODAL BOTTOM SHEETS BLUEPRINT

### 5.1 GPS Location Map Picker (`GpsLocationModal`)
- **Vector Map Visualization**: Animated map canvas showing road grid and delivery route.
- **Central Pulsing Pin**: Visual location target with animated ripple wave.
- **"Locate Me" Button**: Reverse geocoding simulation fetching latitude & longitude.
- **Serviceability Status**: "12 Min Delivery Hub #04" badge confirming doorstep coverage.
- **Preset Areas**: Quick buttons for popular local localities (HSR Layout, Indiranagar, Koramangala, Bellandur).
- **Confirmation CTA**: "Confirm Delivery Location" updates address across cart and storefront.

### 5.2 Rider Live Chat (`RiderChatModal`)
- **Header**: Driver avatar, name ("Ravi Kumar"), vehicle number ("KA 01 EK 8812 - Ather 450X"), and phone call trigger.
- **Message List**: Chat bubble history with distinct styling for user (primary green) and rider (surface white with border), with timestamps and double-check read receipts.
- **Quick Reply Chips**: Horizontal chips (*"Leave at flat door, thank you!"*, *"Please don't ring the bell"*, *"Call me once at apartment gate"*, *"Hand over to security guard"*).
- **Interactive Auto-Reply**: Simulates driver replies after 900ms (*"Noted! Reaching your doorstep in 3 minutes."*).

### 5.3 Structured Cancellation (`CancelOrderModal`)
- **Refund Breakdown**: Displays 100% refund amount (e.g., `₹405`) credited back to source in 5 minutes.
- **Reason Radios**: Selectable reasons (*"Placed order by mistake"*, *"Delivery time is higher than expected"*, *"Want to change delivery address or slot"*, etc.).
- **Confirm CTA**: Destructive red button "Confirm Cancellation & Refund" + "Don't Cancel (Keep Order)" secondary button.

### 5.4 Order & Rider Rating (`RateOrderModal`)
- **Produce Rating**: 5-star interactive rating for harvest quality with label descriptor.
- **Rider Rating**: Separate 5-star rating for driver Ravi Kumar's speed and behavior.
- **Feedback Tag Chips**: Selectable tag pills (*"Super Fresh Produce"*, *"Crisp Packaging"*, *"10-Min Fast Delivery"*, *"Polite Rider"*, *"Perfect Ripeness"*, *"Zero Plastic Used"*).
- **Textarea**: Optional comment box.
- **Submit CTA**: "Submit Feedback & Earn 20 Coins".

### 5.5 Voice Search (`VoiceSearchModal`)
- **Audio Wave Graphic**: Pulsing concentric circle animation simulating microphone listening state.
- **Sample Speech Triggers**: Quick clickable speech query cards (*"Organic Hass Avocado"*, *"A2 Gir Cow Milk"*, *"Country Sourdough Loaf"*).
- **Action**: Auto-populates query into search provider and navigates directly to search results.

### 5.6 In-App Notification Center (`NotificationDrawer`)
- **Floating Push Toast**: Appears dynamically on new order events, harvest arrivals, or driver arrival warnings. Includes direct deep-link navigation.
- **Modal Notification Drawer**: Categorized notification cards (Orders, Harvest Promos, System Alerts) with "Mark All as Read" and "Send Ping" test button.

---

## 6. EXCEPTION & ERROR SCREENS BLUEPRINT

### 6.1 Shaky 4G / Offline Screen (`/offline`)
- **Condition**: Triggers when device network drops or connection times out.
- **Visuals**: Rose illustration circle with `WifiOff` icon -> "You're Offline" pill -> "Connection Interrupted" title -> Explanation that local cart and active order tracking are cached.
- **Checklist**:
  - `✓ Cart state preserved locally`
  - `✓ Driver delivery queue is progressing`
- **Actions**:
  - Primary: "Retry Connection Now" (triggers ping with loading spinner).
  - Secondary: "View Cached Basket".

### 6.2 500 Cold Backend Recovery Screen (`/server_error`)
- **Condition**: Triggers if backend database or server microservice is warming up.
- **Visuals**: Amber illustration circle with `ServerCrash` icon -> "Store Server Spinning Up" pill -> "Waking up the store..." title.
- **Progress Animation**: Visual progress bar advancing from 65% to 92% with caption: `GET /storefront/easyget/ · Retrying automatically in ~8s`.
- **Actions**:
  - Primary: "Wake Up Store Now" (auto-retries endpoint).
  - Secondary: "Continue with Offline Cache".

### 6.3 404 Harvest Item Not Found (`/not_found`)
- **Condition**: Triggers if invalid slug or discontinued SKU is accessed.
- **Visuals**: `FileQuestion` icon -> "Item Not In Today's Harvest" -> "Back to Fresh Market Storefront" button.

---

## 7. STATE MANAGEMENT & BUSINESS LOGIC (RIVERPOD BLUEPRINT)

```dart
// lib/providers/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartState {
  final List<CartItem> items;
  final int riderTip;
  final List<String> deliveryInstructions;
  final String substitutionPreference;

  CartState({
    this.items = const [],
    this.riderTip = 20,
    this.deliveryInstructions = const ['leave_door'],
    this.substitutionPreference = 'call',
  });

  int get count => items.fold(0, (sum, item) => sum + item.quantity);
  int get subtotal => items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  int get deliveryFee => (subtotal >= 300 || subtotal == 0) ? 0 : 25;
  int get discount => 50; // Dynamic based on applied coupon
  int get total => (subtotal - discount + deliveryFee + riderTip).clamp(0, 999999);

  CartState copyWith({
    List<CartItem>秩items,
    int? riderTip,
    List<String>? deliveryInstructions,
    String? substitutionPreference,
  }) => CartState(
    items: items ?? this.items,
    riderTip: riderTip ?? this.riderTip,
    deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
    substitutionPreference: substitutionPreference ?? this.substitutionPreference,
  );
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addToCart(Product product, [int delta = 1]) {
    final index = state.items.indexWhere((i) => i.product.id == product.id);
    if (index > -1) {
      final newQty = state.items[index].quantity + delta;
      if (newQty <= 0) {
        state = state.copyWith(items: state.items.where((i) => i.product.id != product.id).toList());
      } else {
        final updated = [...state.items];
        updated[index] = CartItem(product: product, quantity: newQty.clamp(1, product.stockQty));
        state = state.copyWith(items: updated);
      }
    } else if (delta > 0) {
      state = state.copyWith(items: [...state.items, CartItem(product: product, quantity: delta)]);
    }
  }

  void setRiderTip(int tip) => state = state.copyWith(riderTip: tip);

  void toggleInstruction(String instruction) {
    final list = [...state.deliveryInstructions];
    if (list.contains(instruction)) {
      list.remove(instruction);
    } else {
      list.add(instruction);
    }
    state = state.copyWith(deliveryInstructions: list);
  }

  void setSubstitution(String pref) => state = state.copyWith(substitutionPreference: pref);

  void clearCart() => state = state.copyWith(items: []);
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
```

---

## 8. BACKEND API WIRING CONTRACT (ALL ENDPOINTS)

| Method | Path | Description | Payload / Response |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/auth/login/` | User authentication | Request: `{ email, password }` -> Response: `{ access, refresh, user }` |
| `POST` | `/api/v1/auth/register/` | Account creation | Request: `{ name, email, phone, password, role }` |
| `POST` | `/api/v1/auth/otp/send/` | Send 4-digit SMS OTP | Request: `{ phone }` |
| `POST` | `/api/v1/auth/otp/verify/` | Verify SMS/WhatsApp OTP | Request: `{ phone, otp }` -> Response: `{ access, user }` |
| `GET` | `/api/v1/users/me/` | Fetch active user session | Headers: `Bearer <token>` |
| `GET` | `/api/v1/storefront/easyget/` | Fetch Home layout & rails | Response: `{ banners, categories, sections }` |
| `GET` | `/api/v1/products/` | Filtered PLP product list | Query params: `category, is_veg, in_stock, sort, page` |
| `GET` | `/api/v1/products/:slug/` | PDP details, story, nutrition | Response: Full `Product` object |
| `GET` | `/api/v1/products/:slug/reviews/` | Verified customer reviews | Response: Review list + rating distribution |
| `GET` | `/api/v1/search/` | Debounced catalog search | Query param: `q` |
| `GET` | `/api/v1/search/trending/` | Popular search keywords | Response: List of trending strings |
| `GET` | `/api/v1/cart/` | Fetch server cart totals | Response: `{ items, subtotal, discount, total }` |
| `POST` | `/api/v1/cart/merge/` | Merge guest cart on login | Request: `{ guest_token }` |
| `POST` | `/api/v1/coupons/validate/` | Validate voucher code | Request: `{ code, subtotal }` |
| `GET` | `/api/v1/addresses/` | Fetch saved address book | Response: List of `Address` |
| `POST` | `/api/v1/addresses/` | Save new delivery address | Request: `{ label, street, area, pincode, phone }` |
| `POST` | `/api/v1/orders/` | Place idempotent order | Request: `{ address_id, slot, payment_method, tip, instructions }` |
| `GET` | `/api/v1/orders/` | Orders history (Active & Past)| Response: List of `Order` |
| `GET` | `/api/v1/orders/:id/track/` | Live order events & driver ETA | Polled every 30s while in transit |
| `POST` | `/api/v1/orders/:id/cancel/` | Cancel order with refund | Request: `{ reason }` -> Response: `{ refund_status: 'CREDITED' }` |
| `POST` | `/api/v1/orders/:id/review/` | Submit produce & driver rating | Request: `{ product_rating, driver_rating, tags, comment }` |
| `POST` | `/api/v1/orders/:id/chat/` | Send message to rider | Request: `{ text }` -> Response: `{ reply }` |

---

## 9. ACCEPTANCE CHECKLIST FOR FLUTTER IMPLEMENTATION

- [ ] Zero hardcoded magic numbers or rogue colors outside `AppColors` and `AppTypography`.
- [ ] Tabular numerics applied to **every** price, ETA, order ID, and count using `FontFeature.tabularFigures()`.
- [ ] Strict two-tap buying: Product -> Add button morphs to `- [qty] +` stepper in 180ms ease-out.
- [ ] ETA Pill ("12 min" with marigold wash) permanently visible on Header, Cart, and Checkout.
- [ ] 5-tab bottom navigation with primary green wash pill indicator (`Home`, `Browse`, `Search`, `Cart`, `Orders`).
- [ ] Cart item count badge with tabular numeric font on the Cart navigation icon.
- [ ] Full offline cache support with auto-recovery on connection restore.
- [ ] 54dp bottom-anchored primary CTA on all checkout flows.
- [ ] Shimmer skeletons on initial catalog load (no dead circular spinners).
- [ ] 100% WCAG 2.2 AA compliant contrast on all light paper and dark charcoal surfaces.
