# 07 Local Delivery
**Name:** Mahmud Mostofa Al Maruf  
**Student ID:** 22101132  
**Course:** CSE489 - Android App Development  
**Platform:** Flutter + Firebase (Firestore, Auth, FCM)
---

## 📋 Table of Contents
- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [How to Run](#-how-to-run)
- [Project Structure](#-project-structure)
- [Milestone 1: Schema & Wireframes](#-milestone-1-database-schema--wireframes)
- [Milestone 2: Core Implementation](#-milestone-2-core-implementation)
- [Milestone 3: Advanced Features](#-milestone-3-advanced-features)
- [Technical Challenges Solved](#-technical-challenges-solved)

---

## 🚀 Project Overview
**07 Local Delivery** is a hyperlocal delivery platform built with Flutter and Firebase, enabling real-time order management between three user types:
| Panel | Features |
|-------|----------|
| **Customer App** | Browse shops, add to cart, place orders, track rider live on map |
| **Rider App** | Go online, accept orders, status progression (Accept → Pickup → Deliver), GPS tracking |
| **Admin Dashboard** | View all orders, manage shop listings, analytics with charts |

---

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Screens    │────▶│  Providers   │────▶│  Services   │
│   (UI/View)  │◀────│ (State/Logic)│◀────│ (Firebase)  │
└─────────────┘     └──────────────┘     └─────────────┘
                           │
                    ┌──────┴──────┐
                    │   Models    │
                    │ (Data Layer)│
                    └─────────────┘
```

**Pattern:** Service-Provider Architecture  
**State Management:** Provider (ChangeNotifier)  
**Database:** Cloud Firestore (NoSQL)  
**Authentication:** Firebase Phone Auth + Email/Password  
**Maps:** OpenStreetMap via `flutter_map`  
**Push Notifications:** Firebase Cloud Messaging (FCM)

---

## ⚡ How to Run

### Prerequisites
- Flutter SDK 3.2+
- Android Studio / VS Code
- Firebase project configured

### Steps
```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/CSE489_Project.git
cd "CSE489_Project/07 Local Delivery"

# 2. Install dependencies
flutter pub get

# 3. Run on Android device/emulator
flutter run

# 4. Run Admin Dashboard on Chrome
flutter run -d chrome
```

### Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Phone Authentication** and **Email/Password** in Authentication
3. Create a **Cloud Firestore** database
4. Run `flutterfire configure` to generate `firebase_options.dart`
5. Add test phone number in Firebase Console → Authentication → Phone → Testing

### Test Credentials
| Type | Value |
|------|-------|
| Phone | `+8801797837210` |
| OTP | `123456` |

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point, Firebase init, MultiProvider
├── firebase_options.dart              # Auto-generated Firebase config
│
├── config/
│   ├── app_router.dart                # Named routes & navigation map
│   ├── app_theme.dart                 # Colors, fonts, global ThemeData
│   └── demo_data.dart                 # Hardcoded seed data for demos
│
├── models/
│   ├── user_model.dart                # User profile (customer/rider/admin)
│   ├── shop_model.dart                # Shop info (name, rating, category)
│   ├── product_model.dart             # Product data (price, unit, image)
│   ├── cart_item_model.dart           # Cart item with quantity logic
│   └── order_model.dart              # Full order with status tracking
│
├── services/
│   ├── auth_service.dart              # Firebase Auth (Phone OTP + Email)
│   ├── shop_service.dart              # Firestore shop queries
│   ├── product_service.dart           # Firestore product sub-collection
│   ├── order_service.dart             # Atomic batch writes, order streams
│   ├── location_service.dart          # GPS tracking with Geolocator
│   └── notification_service.dart      # FCM token management
│
├── providers/
│   ├── auth_provider.dart             # Auth state + error handling
│   ├── shop_provider.dart             # Shop list caching
│   ├── product_provider.dart          # Category filtering
│   ├── cart_provider.dart             # Cart logic + single-vendor rule
│   ├── order_provider.dart            # Order placement flow
│   └── rider_provider.dart            # Rider workflow + Firestore streams
│
├── screens/
│   ├── splash_screen.dart             # Role-based routing on launch
│   ├── auth/
│   │   ├── login_screen.dart          # Phone/Email dual login
│   │   ├── otp_screen.dart            # 6-digit OTP verification
│   │   └── profile_setup_screen.dart  # New user onboarding
│   ├── customer/
│   │   ├── home_screen.dart           # Shop listings dashboard
│   │   ├── shop_detail_screen.dart    # Product grid per shop
│   │   ├── cart_screen.dart           # Cart management
│   │   ├── checkout_screen.dart       # Address + payment confirmation
│   │   ├── order_confirmation_screen.dart
│   │   ├── order_history_screen.dart  # Past orders list
│   │   └── order_tracking_screen.dart # Live GPS map tracking
│   ├── rider/
│   │   └── rider_home_screen.dart     # Online toggle + order workflow
│   └── admin/
│       └── admin_dashboard.dart       # Web dashboard with analytics
│
├── widgets/
│   ├── shop_card.dart                 # Reusable shop tile
│   ├── product_card.dart              # Product tile with add-to-cart
│   ├── cart_item_tile.dart            # Cart item with +/- buttons
│   └── category_card.dart             # Category filter chip
│
└── utils/
    └── seeder.dart                    # Auto-seed Firestore with demo data
```

---

## 📊 Milestone 1: Database Schema & Wireframes

### Firestore Schema
![Schema](docs/schema.png)

### UI Wireframes
| Customer App | Rider App | Admin Dashboard |
|:---:|:---:|:---:|
| ![Customer](docs/wireframe_customer_1.png) | ![Rider](docs/wireframe_rider.png) | ![Admin](docs/wireframe_admin.png) |

---

## 🚀 Milestone 2: Core Implementation

### 1. Firebase Integration
- **Phone Auth** with OTP (Firebase Testing Numbers for demos)
- **Firestore** with `users`, `shops`, `orders` collections
- **Provider** architecture for state management

### 2. Customer Ecosystem
- Real-time shop/product fetching from Firestore
- **Single-Vendor Cart** restriction logic
- **Atomic Batch Writes** for order submission (`batch.commit()`)

### 3. Role-Based Routing
- Dynamic navigation based on `user.role` (customer → home, rider → riderHome, admin → dashboard)

---

## 🔥 Milestone 3: Advanced Features

### 1. Rider Order Workflow (Real-time)
- **Firestore Streams** replace all mock data
- Rider goes Online → `streamPendingOrders()` → Accept → Pickup → Deliver
- Status progression: `pending → accepted → picked_up → delivered`
- Each status change updates Firestore in real-time

### 2. GPS Live Tracking
- **Geolocator** package for continuous GPS positioning
- Rider location pushed to `users/{id}.liveLocation` every 10 seconds
- Customer views live rider marker on **OpenStreetMap** (`flutter_map`)
- `StreamBuilder` listens to rider's GeoPoint for real-time updates

### 3. Admin Web Dashboard
- Responsive side-navigation layout (works on desktop and mobile)
- **Analytics Panel:** Total Sales, Commission, PieChart (fl_chart)
- **Orders Panel:** Real-time order list with status badges
- **Shops Panel:** Active/Inactive toggle for shop management

### 4. Push Notifications (FCM)
- Firebase Cloud Notifications integration
- Local Push Notifications via `flutter_local_notifications`
- Foreground & background message handlers
- Status-specific notification text (Accepted, Picked Up, Delivered)

### 5. Secondary Email Login
- **Phone + Email** dual authentication
- Toggle UI on login screen between Phone OTP and Email/Password
- Register/Sign-in modes with validation
- Cost-optimized: Email auth is free on Firebase (no SMS charges)

---

## 🧩 Technical Challenges Solved

| Challenge | Solution |
|-----------|----------|
| Firestore composite index errors | Local Dart-side sorting instead of combined `where` + `orderBy` |
| Partial order writes on network failure | Atomic `WriteBatch` ensures all-or-nothing |
| OTP costs for testing | Firebase Testing Numbers (zero SMS cost) |
| Windows-Android build crashes | Disabled `kotlin.incremental` caching |
| Multi-vendor cart conflicts | Single-vendor cart rule with reset prompt |
| Real-time rider tracking | Geolocator + Firestore GeoPoint + StreamBuilder |
| Admin on different platforms | Flutter Web support (`flutter run -d chrome`) |

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Phone + Email authentication |
| `cloud_firestore` | NoSQL database |
| `flutter_local_notifications` | Push notifications |
| `provider` | State management |
| `flutter_map` | OpenStreetMap widget |
| `latlong2` | Lat/Lng coordinates |
| `geolocator` | GPS location |
| `fl_chart` | Analytics charts |
| `google_fonts` | Custom typography |
| `pinput` | OTP input UI |
| `intl` | Date formatting |
| `uuid` | Unique ID generation |
| `url_launcher` | Open dialer for Rider/Customer calls |
| `image_picker` | Update User Profile Avatar |

---

*Built with ❤️ using Flutter & Firebase*
