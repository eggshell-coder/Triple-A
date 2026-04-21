# Triple A API Documentation

Base URL: `http://localhost:3000/api`

All responses follow this format:
```json
{
  "success": true | false,
  "message": "Human readable message",
  "data": { ... } | [ ... ]
}
```

---

## Authentication

### POST /auth/login
Login as admin.

**Request:**
```json
{ "email": "admin@example.com", "password": "yourpassword" }
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "user": { "id": "uuid", "full_name": "Admin", "email": "...", "role": "admin" }
  }
}
```

Protected routes require header:
```
Authorization: Bearer <token>
```

---

## Products

### GET /products
List all active products. Supports query params:
- `search` – text search on name
- `category_id` – filter by category UUID
- `min_price`, `max_price` – price range
- `page`, `limit` – pagination

**Response:**
```json
{
  "success": true,
  "data": [ { "id": "...", "name": "Classic Tee", "price": 890, "stock": 50, ... } ],
  "pagination": { "total": 20, "page": 1, "limit": 20, "totalPages": 1 }
}
```

### GET /products/:id
Get single product by UUID.

### GET /products/admin/all ✅
All products including inactive (admin only).

### POST /products ✅
Create a new product.

**Request:**
```json
{
  "name": "Heritage Tee",
  "description": "Premium cotton tee",
  "price": 890,
  "stock": 50,
  "size": "S, M, L, XL",
  "color": "White",
  "image_url": "https://...",
  "category_id": "uuid"
}
```

### PUT /products/:id ✅
Update existing product. Same body as POST, plus:
```json
{ "is_active": true }
```

### DELETE /products/:id ✅
Soft-delete (sets `is_active = false`). Product data is preserved.

---

## Categories

### GET /categories
List all categories.

**Response:**
```json
{ "success": true, "data": [ { "id": "uuid", "name": "T-Shirts" } ] }
```

### POST /categories ✅
```json
{ "name": "New Category" }
```

---

## Orders

### POST /orders
Place a customer order (public endpoint).

**Request:**
```json
{
  "customer": {
    "full_name": "Rahim Uddin",
    "phone": "01700123456",
    "address": "123 Dhanmondi, Dhaka",
    "email": "rahim@example.com"
  },
  "items": [
    { "product_id": "uuid", "quantity": 2 }
  ],
  "note": "Please call before delivery"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Order placed successfully! We will contact you shortly.",
  "data": { "order_id": "uuid", "total_amount": 1780, "status": "pending" }
}
```

**Validation:**
- Stock is checked before placing order
- Insufficient stock returns 400 with message

### GET /orders ✅
List all orders (admin).
- `?status=pending|processing|completed|cancelled` – filter
- `?page=1&limit=20` – pagination

**Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "total_amount": 1780,
      "status": "pending",
      "created_at": "2025-01-15T10:30:00Z",
      "customers": { "full_name": "Rahim", "phone": "..." }
    }
  ]
}
```

### GET /orders/:id ✅
Full order detail including customer info and all items.

### PATCH /orders/:id/status ✅
Update order status.

**Request:**
```json
{ "status": "processing" }
```

Valid statuses: `pending`, `processing`, `completed`, `cancelled`

---

## Dashboard

### GET /dashboard/stats ✅
Returns key business metrics.

**Response:**
```json
{
  "data": {
    "total_products": 12,
    "total_orders": 45,
    "pending_orders": 8,
    "processing_orders": 3,
    "completed_orders": 30,
    "cancelled_orders": 4,
    "total_revenue": 54200.00,
    "recent_orders": [ ... ]
  }
}
```

---

## Image Upload

### POST /upload ✅
Upload a product image to Supabase Storage.

**Request:** `multipart/form-data` with field `image` (JPEG/PNG/WebP, max 5MB)

**Response:**
```json
{
  "success": true,
  "data": {
    "url": "https://your-project.supabase.co/storage/v1/object/public/product-images/products/...",
    "path": "products/filename.jpg"
  }
}
```

---

## Error Responses

| Status | Meaning |
|--------|---------|
| 400 | Bad request / validation failed |
| 401 | Not authenticated |
| 403 | Forbidden (not admin) |
| 404 | Resource not found |
| 422 | Validation errors (field-level) |
| 429 | Rate limit exceeded |
| 500 | Internal server error |

**Validation Error (422):**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "field": "email", "message": "Valid email required" }
  ]
}
```
