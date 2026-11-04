import React, { createContext, useContext, useState, useEffect } from 'react';
import {
  ScreenType,
  Product,
  CartItem,
  Address,
  Coupon,
  Order,
  AppNotification,
} from '../types';
import {
  PRODUCTS,
  CATEGORIES,
  MOCK_ADDRESSES,
  ACTIVE_COUPONS,
  MOCK_ORDERS,
  MOCK_NOTIFICATIONS,
} from '../data/mockData';

interface AppContextType {
  screen: ScreenType;
  navigate: (screen: ScreenType, params?: { slug?: string; category?: string; orderId?: string }) => void;
  goBack: () => void;
  selectedProductSlug: string;
  selectedCategory: string | null;
  selectedOrderId: string;
  searchQuery: string;
  setSearchQuery: (q: string) => void;

  // Cart
  cart: CartItem[];
  addToCart: (product: Product, delta?: number) => void;
  updateQuantity: (productId: string, quantity: number) => void;
  removeFromCart: (productId: string) => void;
  clearCart: () => void;
  cartCount: number;
  cartSubtotal: number;
  cartDiscount: number;
  deliveryFee: number;
  riderTip: number;
  setRiderTip: (tip: number) => void;
  deliveryInstructions: string[];
  toggleDeliveryInstruction: (instruction: string) => void;
  substitutionPreference: 'call' | 'best_match' | 'refund';
  setSubstitutionPreference: (pref: 'call' | 'best_match' | 'refund') => void;
  cartTotal: number;

  // Wishlist
  wishlist: string[];
  toggleWishlist: (productId: string) => void;
  isWishlisted: (productId: string) => boolean;

  // Addresses
  addresses: Address[];
  selectedAddress: Address;
  setSelectedAddress: (addr: Address) => void;
  addAddress: (addr: Omit<Address, 'id'>) => void;
  isGpsModalOpen: boolean;
  setIsGpsModalOpen: (open: boolean) => void;
  updateLocationFromGps: (loc: { area: string; street: string; pincode: string }) => void;

  // Orders
  orders: Order[];
  activeOrder: Order | null;
  placeOrder: (paymentMethod: string, slotText: string, tip?: number, instructions?: string[]) => Order;
  cancelOrder: (orderId: string, reason?: string) => void;
  reorderPastOrder: (orderId: string) => void;
  submitOrderReview: (orderId: string, review: { rating: number; tags: string[]; text: string }) => void;
  submitDriverRating: (orderId: string, rating: number) => void;

  // Coupons
  coupons: Coupon[];
  appliedCoupon: Coupon | null;
  applyCoupon: (code: string) => { success: boolean; message: string };
  removeCoupon: () => void;

  // Notifications
  notifications: AppNotification[];
  unreadNotifsCount: number;
  markNotifAsRead: (id: string) => void;
  markAllNotifsAsRead: () => void;
  isNotifSheetOpen: boolean;
  setIsNotifSheetOpen: (open: boolean) => void;
  activePushBanner: AppNotification | null;
  dismissPushBanner: () => void;
  simulateIncomingNotification: () => void;

  // Theme & Mockup Viewport
  isDark: boolean;
  toggleDarkMode: () => void;
  viewportMode: 'mobile-fullscreen' | 'figma-mockup';
  setViewportMode: (mode: 'mobile-fullscreen' | 'figma-mockup') => void;

  // Exception Simulation states
  isOffline: boolean;
  setIsOffline: (val: boolean) => void;
  isServerError: boolean;
  setIsServerError: (val: boolean) => void;
  triggerException: (type: 'offline' | '500' | '404') => void;

  // User Auth
  user: { name: string; phone: string; email: string } | null;
  setUser: (u: { name: string; phone: string; email: string } | null) => void;
  login: (email: string) => void;
  logout: () => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [screen, setScreen] = useState<ScreenType>('home');
  const [screenHistory, setScreenHistory] = useState<ScreenType[]>(['home']);
  const [selectedProductSlug, setSelectedProductSlug] = useState<string>('avocado-hass');
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [selectedOrderId, setSelectedOrderId] = useState<string>('EG-9281');
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Cart initialized with 2 fresh market staples
  const [cart, setCart] = useState<CartItem[]>([
    { product: PRODUCTS[0], quantity: 1 },
    { product: PRODUCTS[1], quantity: 2 },
  ]);
  const [riderTip, setRiderTip] = useState<number>(20);
  const [deliveryInstructions, setDeliveryInstructions] = useState<string[]>(['leave_door']);
  const [substitutionPreference, setSubstitutionPreference] = useState<'call' | 'best_match' | 'refund'>('call');

  const [wishlist, setWishlist] = useState<string[]>(['prod-1', 'prod-3']);
  const [addresses, setAddresses] = useState<Address[]>(MOCK_ADDRESSES);
  const [selectedAddress, setSelectedAddress] = useState<Address>(MOCK_ADDRESSES[0]);
  const [isGpsModalOpen, setIsGpsModalOpen] = useState(false);
  const [orders, setOrders] = useState<Order[]>(MOCK_ORDERS);
  const [coupons] = useState<Coupon[]>(ACTIVE_COUPONS);
  const [appliedCoupon, setAppliedCoupon] = useState<Coupon | null>(ACTIVE_COUPONS[0]);

  // Notifications
  const [notifications, setNotifications] = useState<AppNotification[]>(MOCK_NOTIFICATIONS);
  const [isNotifSheetOpen, setIsNotifSheetOpen] = useState(false);
  const [activePushBanner, setActivePushBanner] = useState<AppNotification | null>(null);

  // Appearance & MNC Frame
  const [isDark, setIsDark] = useState<boolean>(false);
  const [viewportMode, setViewportMode] = useState<'mobile-fullscreen' | 'figma-mockup'>('figma-mockup');

  // Exceptions & Testing states
  const [isOffline, setIsOffline] = useState(false);
  const [isServerError, setIsServerError] = useState(false);

  // User
  const [user, setUser] = useState<{ name: string; phone: string; email: string } | null>({
    name: 'Ananya Sharma',
    phone: '+91 98450 12890',
    email: 'ananya.sharma@example.com',
  });

  // Apply dark mode class to root
  useEffect(() => {
    if (isDark) {
      document.documentElement.classList.add('dark');
      document.documentElement.setAttribute('data-theme', 'dark');
    } else {
      document.documentElement.classList.remove('dark');
      document.documentElement.setAttribute('data-theme', 'light');
    }
  }, [isDark]);

  const toggleDarkMode = () => setIsDark(prev => !prev);

  const navigate = (
    nextScreen: ScreenType,
    params?: { slug?: string; category?: string; orderId?: string }
  ) => {
    if (params?.slug) setSelectedProductSlug(params.slug);
    if (params?.category !== undefined) setSelectedCategory(params.category);
    if (params?.orderId) setSelectedOrderId(params.orderId);

    setScreenHistory(prev => [...prev, nextScreen]);
    setScreen(nextScreen);
    window.scrollTo({ top: 0, behavior: 'instant' as ScrollBehavior });
  };

  const goBack = () => {
    if (screenHistory.length > 1) {
      const newHistory = [...screenHistory];
      newHistory.pop();
      const prev = newHistory[newHistory.length - 1];
      setScreenHistory(newHistory);
      setScreen(prev);
    } else {
      setScreen('home');
    }
  };

  // Cart operations
  const addToCart = (product: Product, delta = 1) => {
    setCart(prev => {
      const idx = prev.findIndex(item => item.product.id === product.id);
      if (idx > -1) {
        const newQty = prev[idx].quantity + delta;
        if (newQty <= 0) {
          return prev.filter(item => item.product.id !== product.id);
        }
        const updated = [...prev];
        updated[idx] = { ...updated[idx], quantity: Math.min(newQty, product.stockQty) };
        return updated;
      } else {
        if (delta > 0) {
          return [...prev, { product, quantity: Math.min(delta, product.stockQty) }];
        }
        return prev;
      }
    });
  };

  const updateQuantity = (productId: string, quantity: number) => {
    setCart(prev => {
      if (quantity <= 0) {
        return prev.filter(item => item.product.id !== productId);
      }
      return prev.map(item =>
        item.product.id === productId
          ? { ...item, quantity: Math.min(quantity, item.product.stockQty) }
          : item
      );
    });
  };

  const removeFromCart = (productId: string) => {
    setCart(prev => prev.filter(item => item.product.id !== productId));
  };

  const clearCart = () => setCart([]);

  const cartCount = cart.reduce((acc, item) => acc + item.quantity, 0);
  const cartSubtotal = cart.reduce((acc, item) => acc + item.product.price * item.quantity, 0);
  const cartDiscount = appliedCoupon && cartSubtotal >= appliedCoupon.minOrder
    ? appliedCoupon.discountAmount
    : 0;
  const deliveryFee = cartSubtotal >= 300 || cartSubtotal === 0 ? 0 : 25;
  const cartTotal = Math.max(0, cartSubtotal - cartDiscount + deliveryFee + riderTip);

  const toggleDeliveryInstruction = (inst: string) => {
    setDeliveryInstructions(prev =>
      prev.includes(inst) ? prev.filter(i => i !== inst) : [...prev, inst]
    );
  };

  // Wishlist
  const toggleWishlist = (productId: string) => {
    setWishlist(prev =>
      prev.includes(productId) ? prev.filter(id => id !== productId) : [...prev, productId]
    );
  };
  const isWishlisted = (productId: string) => wishlist.includes(productId);

  // Address
  const addAddress = (newAddr: Omit<Address, 'id'>) => {
    const created: Address = {
      ...newAddr,
      id: `addr-${Date.now()}`,
    };
    setAddresses(prev => [...prev, created]);
    setSelectedAddress(created);
  };

  const updateLocationFromGps = (loc: { area: string; street: string; pincode: string }) => {
    const updated: Address = {
      id: `addr-gps-${Date.now()}`,
      type: 'Home',
      label: 'Current GPS Location',
      street: loc.street,
      area: loc.area,
      city: 'Bengaluru',
      pincode: loc.pincode,
      phone: user?.phone || '+91 98450 12890',
      isDefault: true,
      coordinates: { lat: 12.9141, lng: 77.6411 },
    };
    setAddresses(prev => [updated, ...prev]);
    setSelectedAddress(updated);
    setIsGpsModalOpen(false);
    triggerPushToast({
      id: `loc-${Date.now()}`,
      title: 'GPS Location Updated',
      body: `Delivery pinned to ${loc.area} (12 min reach).`,
      timestamp: 'Just now',
      type: 'system',
      read: false,
    });
  };

  // Orders
  const activeOrder = orders.find(o => o.status === 'In Transit') || null;

  const placeOrder = (
    paymentMethod: string,
    slotText: string,
    tip = riderTip,
    instructions = deliveryInstructions
  ): Order => {
    const newOrder: Order = {
      id: `EG-${Math.floor(1000 + Math.random() * 9000)}`,
      date: `Today, ${new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`,
      status: 'In Transit',
      etaMinutes: 12,
      driverName: 'Ravi Kumar',
      driverPhone: '+91 91234 56789',
      driverVehicle: 'KA 01 EK 8812 (Ather 450X)',
      items: [...cart],
      subtotal: cartSubtotal,
      discount: cartDiscount,
      deliveryFee: deliveryFee,
      riderTip: tip,
      deliveryInstructions: instructions,
      total: cartTotal,
      address: selectedAddress,
      paymentMethod,
      events: [
        {
          status: 'Order Placed',
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          description: `Confirmed for slot: ${slotText}`,
          completed: true,
          current: false,
        },
        {
          status: 'Packed with Care',
          time: 'Est. in 3 mins',
          description: 'Dark store crew picking farm items',
          completed: true,
          current: true,
        },
        {
          status: 'Out for Delivery',
          time: 'Est. in 7 mins',
          description: 'Ravi Kumar dispatching on electric scooter',
          completed: false,
          current: false,
        },
        {
          status: 'Delivered',
          time: 'Est. in 12 mins',
          description: 'Contactless handover',
          completed: false,
          current: false,
        },
      ],
    };

    setOrders(prev => [newOrder, ...prev]);
    setSelectedOrderId(newOrder.id);
    clearCart();

    // Trigger notification
    triggerPushToast({
      id: `order-placed-${Date.now()}`,
      title: `Order #${newOrder.id} confirmed!`,
      body: `Delivery in 12 mins to ${selectedAddress.label}.`,
      timestamp: 'Just now',
      type: 'order',
      read: false,
      actionScreen: 'track',
    });

    return newOrder;
  };

  const cancelOrder = (orderId: string, reason?: string) => {
    setOrders(prev =>
      prev.map(o => (o.id === orderId ? { ...o, status: 'Cancelled' as const } : o))
    );
    triggerPushToast({
      id: `cancel-${Date.now()}`,
      title: `Order #${orderId} cancelled`,
      body: `100% refund of ₹${orders.find(o => o.id === orderId)?.total || 0} initiated to original source.`,
      timestamp: 'Just now',
      type: 'order',
      read: false,
    });
  };

  const reorderPastOrder = (orderId: string) => {
    const target = orders.find(o => o.id === orderId);
    if (!target) return;
    setCart(target.items.map(item => ({ ...item })));
    navigate('cart');
    triggerPushToast({
      id: `reorder-${Date.now()}`,
      title: 'Items added to basket!',
      body: `${target.items.length} items from Order #${target.id} added.`,
      timestamp: 'Just now',
      type: 'order',
      read: false,
      actionScreen: 'cart',
    });
  };

  const submitOrderReview = (orderId: string, review: { rating: number; tags: string[]; text: string }) => {
    setOrders(prev =>
      prev.map(o => (o.id === orderId ? { ...o, productReview: review } : o))
    );
    triggerPushToast({
      id: `review-${Date.now()}`,
      title: 'Thank you for your feedback! ⭐',
      body: 'Your farm produce review helps our local growers.',
      timestamp: 'Just now',
      type: 'promo',
      read: false,
    });
  };

  const submitDriverRating = (orderId: string, rating: number) => {
    setOrders(prev =>
      prev.map(o => (o.id === orderId ? { ...o, driverRating: rating } : o))
    );
    triggerPushToast({
      id: `driver-rate-${Date.now()}`,
      title: `Rated Ravi Kumar ${rating}★! 🛵`,
      body: 'Your rating directly supports our electric delivery partners.',
      timestamp: 'Just now',
      type: 'system',
      read: false,
    });
  };

  // Coupons
  const applyCoupon = (code: string) => {
    const found = coupons.find(c => c.code.toUpperCase() === code.toUpperCase());
    if (!found) {
      return { success: false, message: 'Invalid coupon code.' };
    }
    if (cartSubtotal < found.minOrder) {
      return {
        success: false,
        message: `Min order value of ₹${found.minOrder} required for this coupon.`,
      };
    }
    setAppliedCoupon(found);
    return { success: true, message: `Coupon ${found.code} applied! Saved ₹${found.discountAmount}` };
  };

  const removeCoupon = () => setAppliedCoupon(null);

  // Notifications
  const unreadNotifsCount = notifications.filter(n => !n.read).length;

  const markNotifAsRead = (id: string) => {
    setNotifications(prev => prev.map(n => (n.id === id ? { ...n, read: true } : n)));
  };

  const markAllNotifsAsRead = () => {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })));
  };

  const triggerPushToast = (notif: AppNotification) => {
    setNotifications(prev => [notif, ...prev]);
    setActivePushBanner(notif);
    setTimeout(() => {
      setActivePushBanner(prev => (prev?.id === notif.id ? null : prev));
    }, 5500);
  };

  const dismissPushBanner = () => setActivePushBanner(null);

  const simulateIncomingNotification = () => {
    const freshNotifs: Omit<AppNotification, 'id' | 'timestamp' | 'read'>[] = [
      {
        title: 'Fresh Harvest Alert 🥑',
        body: 'Alphonso Mangoes & Hass Avocados restocked from Palani Hills.',
        type: 'promo',
        actionScreen: 'home',
      },
      {
        title: 'Driver is 3 mins away 🛵',
        body: 'Ravi Kumar is turning into your apartment lane.',
        type: 'order',
        actionScreen: 'track',
      },
      {
        title: 'Flash ₹40 Voucher Available 🌿',
        body: 'Use code MORNING10 on organic milk and bakery items.',
        type: 'promo',
        actionScreen: 'cart',
      },
    ];

    const pick = freshNotifs[Math.floor(Math.random() * freshNotifs.length)];
    const notif: AppNotification = {
      ...pick,
      id: `notif-${Date.now()}`,
      timestamp: 'Just now',
      read: false,
    };
    triggerPushToast(notif);
  };

  // Exception simulation triggers
  const triggerException = (type: 'offline' | '500' | '404') => {
    if (type === 'offline') {
      setIsOffline(true);
      setScreen('offline_error');
    } else if (type === '500') {
      setIsServerError(true);
      setScreen('server_error');
    } else if (type === '404') {
      setScreen('not_found');
    }
  };

  const login = (email: string) => {
    setUser({
      name: 'Ananya Sharma',
      phone: '+91 98450 12890',
      email: email || 'ananya.sharma@example.com',
    });
    navigate('home');
  };

  const logout = () => {
    setUser(null);
    navigate('login');
  };

  return (
    <AppContext.Provider
      value={{
        screen,
        navigate,
        goBack,
        selectedProductSlug,
        selectedCategory,
        selectedOrderId,
        searchQuery,
        setSearchQuery,
        cart,
        addToCart,
        updateQuantity,
        removeFromCart,
        clearCart,
        cartCount,
        cartSubtotal,
        cartDiscount,
        deliveryFee,
        riderTip,
        setRiderTip,
        deliveryInstructions,
        toggleDeliveryInstruction,
        substitutionPreference,
        setSubstitutionPreference,
        cartTotal,
        wishlist,
        toggleWishlist,
        isWishlisted,
        addresses,
        selectedAddress,
        setSelectedAddress,
        addAddress,
        isGpsModalOpen,
        setIsGpsModalOpen,
        updateLocationFromGps,
        orders,
        activeOrder,
        placeOrder,
        cancelOrder,
        reorderPastOrder,
        submitOrderReview,
        submitDriverRating,
        coupons,
        appliedCoupon,
        applyCoupon,
        removeCoupon,
        notifications,
        unreadNotifsCount,
        markNotifAsRead,
        markAllNotifsAsRead,
        isNotifSheetOpen,
        setIsNotifSheetOpen,
        activePushBanner,
        dismissPushBanner,
        simulateIncomingNotification,
        isDark,
        toggleDarkMode,
        viewportMode,
        setViewportMode,
        isOffline,
        setIsOffline,
        isServerError,
        setIsServerError,
        triggerException,
        user,
        setUser,
        login,
        logout,
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within an AppProvider');
  return context;
};
