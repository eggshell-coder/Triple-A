# Triple A – Online Clothing Buy Website
## Project Plan & Architecture

---

## 1. Project Overview

**Business:** Triple A – Local Clothing Store  
**Goal:** Replace manual WhatsApp/social-media orders with a full-stack digital platform  
**Academic Context:** Information System Analysis & Design  

---

## 2. Design System (from Stitch)

| Token | Value |
|-------|-------|
| Primary | `#112619` (deep forest green) |
| Secondary | `#af2b3e` (burgundy) |
| Tertiary | `#735c00` (gold) |
| Surface | `#faf9f5` (warm white) |
| Font Display | Newsreader (serif) |
| Font Body | Manrope (sans-serif) |

**Design Philosophy:** "The Modern Heirloom" – editorial heritage aesthetic, extreme whitespace, no hard borders, glassmorphic nav.

---

## 3. Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter Web |
| Backend | Node.js + Express.js |
| Database | Supabase PostgreSQL |
| Auth | Supabase Auth |
| Storage | Supabase Storage |
| API | REST (JSON) |

---

## 4. Improvements Over Basic Spec

1. **Cart persistence** via localStorage on Flutter Web  
2. **Image lazy loading** with placeholder shimmer  
3. **Debounced search** (300ms) to reduce API calls  
4. **Order status timeline** visual component in admin  
5. **Stock guard** – auto-disable Add to Cart when stock = 0  
6. **Responsive breakpoints** – mobile (< 600), tablet (600–1024), desktop (> 1024)  
7. **Input sanitization** on backend with `express-validator`  
8. **Rate limiting** on API endpoints  
9. **Helmet.js** for HTTP security headers  
10. **Row Level Security (RLS)** on Supabase tables  
11. **Optimistic UI updates** in admin for faster perceived performance  
12. **Soft delete** on products (`is_active = false`) instead of hard delete  

---

## 5. Database Schema

```sql
-- See /sql/schema.sql for full script
admins → products → order_items → orders → customers
         categories ↗
```

---

## 6. API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /api/auth/login | ❌ | Admin login |
| GET | /api/products | ❌ | List active products |
| GET | /api/products/:id | ❌ | Product detail |
| POST | /api/products | ✅ | Create product |
| PUT | /api/products/:id | ✅ | Update product |
| DELETE | /api/products/:id | ✅ | Soft delete |
| GET | /api/categories | ❌ | List categories |
| POST | /api/categories | ✅ | Create category |
| POST | /api/orders | ❌ | Customer places order |
| GET | /api/orders | ✅ | List all orders |
| GET | /api/orders/:id | ✅ | Order detail |
| PATCH | /api/orders/:id/status | ✅ | Update status |
| GET | /api/dashboard/stats | ✅ | Dashboard numbers |
| POST | /api/upload | ✅ | Upload image to Supabase |

---

## 7. Flutter Screens

### Customer
- `HomeScreen` – Hero, featured products, brand story
- `ProductListScreen` – Grid with search & filter
- `ProductDetailScreen` – Full detail + Add to Cart
- `CartScreen` – Cart items, quantity control, total
- `CheckoutScreen` – Customer info form + Order
- `OrderConfirmScreen` – Success message

### Admin
- `AdminLoginScreen` – Secure login
- `AdminDashboardScreen` – Stats cards + recent orders
- `ProductManagementScreen` – Table + CRUD modals
- `OrderManagementScreen` – Orders table + status update
- `ProductFormScreen` – Add/Edit product with image upload

---

## 8. Setup Steps

1. Clone repo
2. Set up Supabase project → run `sql/schema.sql`
3. Configure `backend/.env`
4. `cd backend && npm install && npm run dev`
5. Configure `frontend/lib/config/api_config.dart`
6. `cd frontend && flutter pub get && flutter run -d chrome`

---

## 9. Testing Checklist

- [ ] Customer can browse products
- [ ] Customer can add to cart & checkout
- [ ] Order appears in admin panel
- [ ] Admin can update order status
- [ ] Admin can add/edit/delete product
- [ ] Admin login blocks wrong credentials
- [ ] Search filters products correctly
- [ ] Out-of-stock product is disabled
