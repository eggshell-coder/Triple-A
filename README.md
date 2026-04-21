# Triple A – Online Clothing Buy Website

> A full-stack e-commerce platform for Triple A local clothing business.  
> **Academic Project** | Information System Analysis and Design  
> **Tech Stack:** Flutter Web · Node.js · Express.js · Supabase PostgreSQL

---

## 🗂️ Project Structure

```
triple-a/
├── backend/                   Node.js + Express REST API
│   └── src/
│       ├── config/            Supabase client
│       ├── controllers/       Business logic (auth, products, orders, dashboard, upload)
│       ├── middleware/        Auth guard, validation, error handler
│       └── routes/            API route definitions
├── frontend/                  Flutter Web app
│   └── lib/
│       ├── config/            Theme, router, API config
│       ├── models/            Data classes (Product, Order, CartItem…)
│       ├── providers/         Riverpod state (cart, auth)
│       ├── screens/
│       │   ├── customer/      Home, Product List, Detail, Cart, Checkout, Confirm
│       │   └── admin/         Login, Dashboard, Products, Orders
│       ├── services/          HTTP API service layer
│       └── widgets/           Shared UI components, Admin sidebar
├── sql/
│   └── schema.sql             Full PostgreSQL schema + seed data
└── docs/
    └── API.md                 Complete API documentation
```

---

## ⚙️ Prerequisites

| Tool | Version |
|------|---------|
| Node.js | ≥ 18.x |
| Flutter | ≥ 3.19 |
| Supabase account | Free tier works |

---

## 🚀 Setup Guide

### Step 1 – Supabase Setup

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Navigate to **SQL Editor** and paste the contents of `sql/schema.sql`
3. Click **Run** – this creates all tables, indexes, RLS policies, and sample data
4. Create a Storage bucket:
   - Go to **Storage → New Bucket**
   - Name: `product-images`
   - Toggle **Public bucket** ON
5. Create an admin user:
   - Go to **Authentication → Users → Invite user**
   - Enter your admin email and password
6. Add the admin to the `admins` table:
   ```sql
   INSERT INTO admins (full_name, email, role)
   VALUES ('Your Name', 'admin@example.com', 'admin');
   ```
7. Copy your **Project URL** and **service_role secret key** from:  
   Settings → API → Project URL + service_role key

---

### Step 2 – Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env
```

Edit `.env`:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-role-key
PORT=3000
NODE_ENV=development
CORS_ORIGIN=http://localhost:5000
```

```bash
# Start development server
npm run dev

# Server runs at http://localhost:3000
# Health check: http://localhost:3000/health
```

---

### Step 3 – Flutter Frontend Setup

```bash
cd frontend

# Install Flutter dependencies
flutter pub get
```

Edit `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

```bash
# Run in Chrome (Flutter Web)
flutter run -d chrome

# Or build for web production
flutter build web
```

---

## 🧪 Testing the Core Flows

### Customer Flow
1. Open `http://localhost:5000` (Flutter dev server)
2. Browse products on the homepage
3. Click a product → view details
4. Click **Add to Cart**
5. Go to Cart → review items
6. Click **Proceed to Checkout**
7. Fill in name, phone, address
8. Click **Place Order**
9. Order confirmation screen appears with order ID

### Admin Flow
1. Go to `http://localhost:5000/#/admin/login`
2. Log in with your Supabase admin credentials
3. **Dashboard** – view stats, recent orders
4. **Products** – click **Add Product**, fill form, save
5. **Orders** – click status badge to update order status
6. Click **View** on any order to see full details

---

## 📡 API Endpoints Summary

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| GET | `/health` | ❌ | API health check |
| POST | `/api/auth/login` | ❌ | Admin login |
| GET | `/api/products` | ❌ | List products (search/filter) |
| GET | `/api/products/:id` | ❌ | Product detail |
| GET | `/api/products/admin/all` | ✅ | All products (admin) |
| POST | `/api/products` | ✅ | Create product |
| PUT | `/api/products/:id` | ✅ | Update product |
| DELETE | `/api/products/:id` | ✅ | Soft delete product |
| GET | `/api/categories` | ❌ | List categories |
| POST | `/api/categories` | ✅ | Create category |
| POST | `/api/orders` | ❌ | Place order |
| GET | `/api/orders` | ✅ | List orders |
| GET | `/api/orders/:id` | ✅ | Order detail |
| PATCH | `/api/orders/:id/status` | ✅ | Update order status |
| GET | `/api/dashboard/stats` | ✅ | Dashboard stats |
| POST | `/api/upload` | ✅ | Upload product image |

---

## 🎨 Design System

Based on the **Editorial Heritage** design from Stitch.

| Token | Value | Use |
|-------|-------|-----|
| Primary | `#112619` | Buttons, nav, headers |
| Secondary | `#AF2B3E` | Accents, errors, status |
| Tertiary | `#735C00` | Gold tags, highlights |
| Surface | `#FAF9F5` | Page background |
| Font Display | Newsreader | Headlines, product names |
| Font Body | Manrope | All UI text |

---

## 📦 Dependencies

### Backend
- `express` – Web framework
- `@supabase/supabase-js` – Database + Auth + Storage
- `helmet` – HTTP security headers
- `cors` – Cross-origin resource sharing
- `express-rate-limit` – Rate limiting
- `express-validator` – Input validation
- `multer` – File upload handling
- `morgan` – HTTP request logging

### Flutter
- `flutter_riverpod` – State management
- `go_router` – Declarative navigation
- `http` – REST API calls
- `google_fonts` – Newsreader + Manrope fonts
- `cached_network_image` – Image caching
- `shimmer` – Loading placeholders
- `badges` – Cart count badge
- `intl` – Date and number formatting

---

## 👨‍💻 Author

**Triple A Clothing Business**  
Information System Analysis and Design – Academic Project  
