# 07 Local Delivery
**Name:** Mahmud Mostofa Al Maruf  
**Course:** CSE489 - Android App Development  
**Milestone 1:** Database Schema & UI Wireframes

---

## 📊 1. Database Schema (Firestore)
The system uses a structured NoSQL database schema designed for real-time order tracking, hyperlocal shop discovery, and detailed commission management.

![Schema](docs/schema.png)

---

## 🎨 2. UI Wireframes
Detailed layouts for Customer, Rider, and Admin interfaces showcasing the end-to-end user journey.

### A. Customer Application
Focuses on ease of ordering, category-based shop browsing (Grocery, Pharmacy, etc.), and live GPS tracking on a map.
![Customer UI 1](docs/wireframe_customer_1.png)
![Customer UI 2](docs/wireframe_customer_2.png)

### B. Delivery Partner (Rider) App
Designed for quick order acceptance, real-time navigation updates, and transparent earnings tracking.
![Rider UI](docs/wireframe_rider.png)

### C. Admin Web Dashboard
A comprehensive panel for onboarding vendors, setting commission rates, and monitoring daily sales analytics.
![Admin UI](docs/wireframe_admin.png)

---

## 🛠️ Project Scope & Key Features
- **OTP Auth:** Mobile number login via Firebase Authentication.
- **Hyperlocal Shop Discovery:** Fetching shops based on user coordinates.
- **Real-time Tracking:** Live GPS synchronization between Rider and Customer.
- **Order Management:** Support for both standard shopping and **Parcel Pickup** services.
- **Admin Control:** Role-based access for managing the entire delivery ecosystem.

---

## 🚀 Next Steps (Milestone 2)
- Implementation of Firebase Auth and Firestore Connection.
- Home screen UI development with real-time data fetching.
- Basic Cart and Order placement logic.
