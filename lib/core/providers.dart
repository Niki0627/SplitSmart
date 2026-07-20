import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

// Firebase instances
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Current user profile from Firestore
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final user = auth.currentUser;
  if (user == null) return Stream.value(null);
  return firestore.collection('users').doc(user.uid).snapshots().map(
    (doc) => doc.exists ? AppUser.fromMap({...doc.data()!, 'uid': doc.id}) : null,
  );
});

// Groups stream for current user
final groupsProvider = StreamProvider<List<Group>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final user = auth.currentUser;
  if (user == null) return Stream.value([]);
  return firestore
      .collection('groups')
      .where('memberIds', arrayContains: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Group.fromDoc).toList());
});

// Expenses for a specific group
final groupExpensesProvider = StreamProvider.family<List<Expense>, String>((ref, groupId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('expenses')
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map((s) {
        final list = s.docs.map(Expense.fromDoc).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
      });
});

// All expenses for the current user (across groups)
final allExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final user = auth.currentUser;
  if (user == null) return Stream.value([]);
  return firestore
      .collection('expenses')
      .where('participants', arrayContains: user.uid)
      .snapshots()
      .map((s) {
        final list = s.docs.map(Expense.fromDoc).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
      });
});

// Reminders for current user
final remindersProvider = StreamProvider<List<Reminder>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final user = auth.currentUser;
  if (user == null) return Stream.value([]);
  return firestore
      .collection('reminders')
      .where('userId', isEqualTo: user.uid)
      .orderBy('dueDate')
      .snapshots()
      .map((s) => s.docs.map(Reminder.fromDoc).toList());
});

// Group members
final groupMembersProvider = FutureProvider.family<List<AppUser>, List<String>>((ref, memberIds) async {
  if (memberIds.isEmpty) return [];
  final firestore = ref.watch(firestoreProvider);
  final futures = memberIds.map((id) => firestore.collection('users').doc(id).get());
  final docs = await Future.wait(futures);
  return docs.where((d) => d.exists).map((d) => AppUser.fromMap({...d.data()!, 'uid': d.id})).toList();
});

// Theme mode provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// Currency providers
final currencyProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user?.currency ?? 'INR';
});

final currencySymbolProvider = Provider<String>((ref) {
  final currency = ref.watch(currencyProvider);
  switch (currency) {
    case 'USD':
      return r'$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'INR':
    default:
      return '₹';
  }
});

// Settlements for a specific group
final groupSettlementsProvider = StreamProvider.family<List<Settlement>, String>((ref, groupId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('settlements')
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map((s) => s.docs.map(Settlement.fromDoc).toList());
});

// All settlements involving current user (across groups)
final allSettlementsProvider = StreamProvider<List<Settlement>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final user = auth.currentUser;
  if (user == null) return Stream.value([]);
  return firestore
      .collection('settlements')
      .snapshots()
      .map((s) {
        final list = s.docs.map(Settlement.fromDoc).toList();
        return list.where((setl) => setl.from == user.uid || setl.to == user.uid).toList();
      });
});

