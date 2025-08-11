import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:RAS/services/panier/panier_local.dart';
import 'package:RAS/services/souhaits/souhaits_local.dart';
import 'dart:async';

class NotificationService with ChangeNotifier {
  final PanierLocal _panierLocal = PanierLocal();
  final SouhaitsLocal _souhaitsLocal = SouhaitsLocal();
  
  int _cartCount = 0;
  int _wishlistCount = 0;
  int _pendingOrdersCount = 0;
  
  StreamSubscription<int>? _cartSubscription;
  StreamSubscription<int>? _wishlistSubscription;
  StreamSubscription<QuerySnapshot>? _ordersSubscription;
  
  int get cartCount => _cartCount;
  int get wishlistCount => _wishlistCount;
  int get pendingOrdersCount => _pendingOrdersCount;
  
  NotificationService() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _panierLocal.init();
    await _souhaitsLocal.init();
    
    // Listen to cart changes
    _cartSubscription = _panierLocal.cartCountStream.listen((count) {
      _cartCount = count;
      notifyListeners();
    });
    
    // Listen to wishlist changes
    _wishlistSubscription = _souhaitsLocal.wishlistCountStream.listen((count) {
      _wishlistCount = count;
      notifyListeners();
    });
    
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _updatePendingOrdersListener();
    });
    
    // Initialize orders listener
    _updatePendingOrdersListener();
  }
  
  void _updatePendingOrdersListener() {
    // Cancel previous subscription if exists
    _ordersSubscription?.cancel();
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _ordersSubscription = FirebaseFirestore.instance
          .collection('Commandes')
          .where('utilisateur.idUtilisateur', isEqualTo: user.uid)
          .where('statutPaiement', whereIn: ['Attente', 'En attente'])
          .snapshots()
          .listen((snapshot) {
            if (_pendingOrdersCount != snapshot.size) {
              _pendingOrdersCount = snapshot.size;
              notifyListeners();
            }
          });
    } else {
      if (_pendingOrdersCount != 0) {
        _pendingOrdersCount = 0;
        notifyListeners();
      }
    }
  }
  
  // Public methods to manually refresh counts
  Future<void> refreshCartCount() async {
    final totalItems = await _panierLocal.getTotalItems();
    if (_cartCount != totalItems) {
      _cartCount = totalItems;
      notifyListeners();
    }
  }
  
  Future<void> refreshWishlistCount() async {
    final wishlistItems = await _souhaitsLocal.getSouhaits();
    if (_wishlistCount != wishlistItems.length) {
      _wishlistCount = wishlistItems.length;
      notifyListeners();
    }
  }
  
  Future<void> refreshPendingOrdersCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final query = await FirebaseFirestore.instance
          .collection('Commandes')
          .where('utilisateur.idUtilisateur', isEqualTo: user.uid)
          .where('statutPaiement', whereIn: ['Attente', 'En attente'])
          .get();
      
      if (_pendingOrdersCount != query.size) {
        _pendingOrdersCount = query.size;
        notifyListeners();
      }
    } else {
      if (_pendingOrdersCount != 0) {
        _pendingOrdersCount = 0;
        notifyListeners();
      }
    }
  }
  
  Future<void> refreshAllCounts() async {
    await refreshCartCount();
    await refreshWishlistCount();
    await refreshPendingOrdersCount();
  }
  
  @override
  void dispose() {
    _cartSubscription?.cancel();
    _wishlistSubscription?.cancel();
    _ordersSubscription?.cancel();
    super.dispose();
  }
}