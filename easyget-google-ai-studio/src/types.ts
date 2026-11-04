export type ScreenType =
  | 'splash'
  | 'login'
  | 'register'
  | 'otp_verify'
  | 'home'
  | 'browse'
  | 'search'
  | 'pdp'
  | 'cart'
  | 'checkout'
  | 'orders'
  | 'track'
  | 'account'
  | 'addresses'
  | 'notifications'
  | 'offline_error'
  | 'server_error'
  | 'not_found';

export interface Product {
  id: string;
  slug: string;
  name: string;
  category: string;
  weight: string;
  price: number;
  mrp: number;
  savingsText?: string;
  rating: number;
  reviewCount: number;
  inStock: boolean;
  stockQty: number;
  isVeg: boolean;
  image: string;
  gallery: string[];
  description: string;
  story: string;
  origin: string;
  shelfLife: string;
  dietaryTags?: ('Organic' | 'Gluten-Free' | 'Vegan' | 'Keto' | 'Chemical-Free')[];
  nutrition: { label: string; value: string }[];
}

export interface Category {
  id: string;
  name: string;
  iconName: string;
  image: string;
  itemCount: number;
}

export interface CartItem {
  product: Product;
  quantity: number;
}

export interface Address {
  id: string;
  type: 'Home' | 'Work' | 'Other';
  label: string;
  street: string;
  area: string;
  city: string;
  pincode: string;
  phone: string;
  isDefault: boolean;
  coordinates?: { lat: number; lng: number };
}

export interface Coupon {
  code: string;
  title: string;
  discountAmount: number;
  minOrder: number;
  description: string;
  expiry: string;
}

export interface OrderEvent {
  status: string;
  time: string;
  description: string;
  completed: boolean;
  current: boolean;
}

export interface Order {
  id: string;
  date: string;
  status: 'In Transit' | 'Delivered' | 'Cancelled';
  etaMinutes?: number;
  items: CartItem[];
  subtotal: number;
  discount: number;
  deliveryFee: number;
  riderTip?: number;
  deliveryInstructions?: string[];
  total: number;
  address: Address;
  paymentMethod: string;
  events: OrderEvent[];
  driverName?: string;
  driverPhone?: string;
  driverVehicle?: string;
  driverRating?: number;
  productReview?: { rating: number; tags: string[]; text: string };
}

export interface AppNotification {
  id: string;
  title: string;
  body: string;
  timestamp: string;
  type: 'order' | 'promo' | 'system';
  read: boolean;
  actionScreen?: ScreenType;
}
