// lib/core/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'models.dart';

// ─── Friendly error messages from Firebase Auth codes ─────────────────────────
String _friendlyAuthError(dynamic e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'credential-already-in-use':
        return 'This credential is already associated with another account.';
      case 'popup-closed-by-user':
        return 'Sign-in was cancelled.';
      case 'cancelled-popup-request':
        return 'Sign-in was cancelled.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
  final msg = e.toString();
  if (msg.contains('network')) return 'Network error. Check your connection.';
  if (msg.contains('cancelled') || msg.contains('canceled')) return 'Sign-in was cancelled.';
  return 'Something went wrong. Please try again.';
}

// ─── FirebaseService ───────────────────────────────────────────────────────────
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Web Client ID from Firebase console (needed for Android OAuth token exchange)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '501819933249-elrcu2gbcp82l02g616sejsb45cc0lp1.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;
  FirebaseFirestore get db => _db;

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _ensureUserDoc(cred.user!);
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _friendlyAuthError(e);
    } catch (e) {
      throw _friendlyAuthError(e);
    }
  }

  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
    String name, {
    String? phone,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user!.updateDisplayName(name.trim());
      await _ensureUserDoc(cred.user!, name: name.trim(), phone: phone?.trim());
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _friendlyAuthError(e);
    } catch (e) {
      throw _friendlyAuthError(e);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: use popup flow
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        final cred = await _auth.signInWithPopup(provider);
        await _ensureUserDoc(cred.user!);
        return cred;
      } else {
        // Android/iOS: native Google Sign-In flow
        // First try to sign out to re-trigger the account picker
        await _googleSignIn.signOut();
        final account = await _googleSignIn.signIn();
        if (account == null) return null; // User cancelled

        final googleAuth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final cred = await _auth.signInWithCredential(credential);
        await _ensureUserDoc(cred.user!);
        return cred;
      }
    } on FirebaseAuthException catch (e) {
      throw _friendlyAuthError(e);
    } catch (e) {
      throw _friendlyAuthError(e);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _friendlyAuthError(e);
    }
  }

  Future<void> _ensureUserDoc(User user, {String? name, String? phone}) async {
    final doc = _db.collection('users').doc(user.uid);
    final snap = await doc.get();
    if (!snap.exists) {
      final email = user.email ?? '';
      final normalizedPhone = _normalizePhone(phone);
      
      String derivedName = 'User';
      if (name != null && name.trim().isNotEmpty) {
        derivedName = name.trim();
      } else if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        derivedName = user.displayName!.trim();
      } else if (email.isNotEmpty) {
        derivedName = email.split('@').first;
      }

      final data = <String, dynamic>{
        'uid': user.uid,
        'name': derivedName,
        'email': email,
        'emailLower': email.toLowerCase(),
        'photoUrl': user.photoURL,
        'currency': 'INR',
        'createdAt': FieldValue.serverTimestamp(),
      };
      // Only store phone if non-empty so queries don't match blank fields
      if (normalizedPhone.isNotEmpty) data['phone'] = normalizedPhone;
      await doc.set(data);
    } else {
      // Patch existing docs that are missing emailLower
      final existing = snap.data()!;
      if (!existing.containsKey('emailLower')) {
        final email = (existing['email'] as String? ?? '');
        await doc.update({'emailLower': email.toLowerCase()});
      }
    }
  }

  /// Normalise a phone number: strip spaces, dashes, parentheses
  String _normalizePhone(String? phone) {
    if (phone == null) return '';
    return phone.trim().replaceAll(RegExp(r'[\s\-().]'), '');
  }

  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? upiId,
    String? currency,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null && name.isNotEmpty) {
      updates['name'] = name;
    }
    if (phone != null) {
      final norm = _normalizePhone(phone);
      if (norm.isNotEmpty) {
        updates['phone'] = norm;
      }
    }
    if (upiId != null) {
      updates['upiId'] = upiId.trim();
    }
    if (currency != null) {
      updates['currency'] = currency;
    }
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
    if (name != null && name.isNotEmpty) {
      await _auth.currentUser?.updateDisplayName(name);
    }
  }

  // ── Groups ──────────────────────────────────────────────────────────────────

  Future<String> createGroup(
    String name,
    String icon,
    List<String> memberIds,
  ) async {
    final uid = currentUser!.uid;
    final all = [...{uid, ...memberIds}];
    final ref = await _db.collection('groups').add({
      'name': name,
      'icon': icon,
      'memberIds': all,
      'createdBy': uid,
      'totalAmount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deleteGroup(String groupId) async {
    await _db.collection('groups').doc(groupId).delete();
  }

  Future<void> addMemberToGroup(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  // ── Expenses ────────────────────────────────────────────────────────────────

  Future<void> addExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidBy,
    required String paidByName,
    required SplitType splitType,
    required List<String> participants,
    required ExpenseCategory category,
    required DateTime date,
  }) async {
    await _db.collection('expenses').add({
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'paidByName': paidByName,
      'splitType': splitType.name,
      'participants': participants,
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('groups').doc(groupId).update({
      'totalAmount': FieldValue.increment(amount),
    });
  }

  Future<void> deleteExpense(
    String expenseId,
    String groupId,
    double amount,
  ) async {
    await _db.collection('expenses').doc(expenseId).delete();
    await _db.collection('groups').doc(groupId).update({
      'totalAmount': FieldValue.increment(-amount),
    });
  }

  // ── Balances ────────────────────────────────────────────────────────────────

  Map<String, Map<String, double>> calculateBalances(
    List<Expense> expenses,
    List<Settlement> settlements,
    List<String> memberIds,
  ) {
    final Map<String, Map<String, double>> debts = {};
    for (final m in memberIds) {
      debts[m] = {};
      for (final other in memberIds) {
        if (m != other) {
          debts[m]![other] = 0.0;
        }
      }
    }
    for (final exp in expenses) {
      if (exp.participants.isEmpty) continue;
      final share = exp.amount / exp.participants.length;
      for (final p in exp.participants) {
        if (p == exp.paidBy) continue;
        if (debts[p] != null && debts[p]![exp.paidBy] != null) {
          debts[p]![exp.paidBy] = debts[p]![exp.paidBy]! + share;
        }
      }
    }
    for (final setl in settlements) {
      final from = setl.from;
      final to = setl.to;
      final amt = setl.amount;
      if (debts[from] != null && debts[from]![to] != null) {
        debts[from]![to] = debts[from]![to]! - amt;
      }
    }
    // Resolve negative debts
    for (final a in memberIds) {
      for (final b in memberIds) {
        if (a == b) continue;
        final ab = debts[a]?[b] ?? 0.0;
        if (ab < 0) {
          debts[b] ??= {};
          debts[b]![a] = (debts[b]![a] ?? 0.0) - ab;
          debts[a]![b] = 0.0;
        }
      }
    }
    // Simplify mutual debts
    for (final a in memberIds) {
      for (final b in memberIds) {
        if (a == b) continue;
        final ab = debts[a]?[b] ?? 0.0;
        final ba = debts[b]?[a] ?? 0.0;
        if (ab > 0 && ba > 0) {
          if (ab > ba) {
            debts[a]![b] = ab - ba;
            debts[b]![a] = 0.0;
          } else {
            debts[b]![a] = ba - ab;
            debts[a]![b] = 0.0;
          }
        }
      }
    }
    return debts;
  }

  double userNetBalance(List<Expense> expenses, List<Settlement> settlements, String uid) {
    double balance = 0.0;
    for (final exp in expenses) {
      if (exp.participants.isEmpty) continue;
      final share = exp.amount / exp.participants.length;
      if (exp.paidBy == uid) {
        final others = exp.participants.where((p) => p != uid).length;
        balance += others * share;
      } else if (exp.participants.contains(uid)) {
        balance -= share;
      }
    }
    for (final setl in settlements) {
      if (setl.from == uid) {
        balance += setl.amount;
      } else if (setl.to == uid) {
        balance -= setl.amount;
      }
    }
    return balance;
  }

  // ── Settlements ─────────────────────────────────────────────────────────────

  Future<void> settleUp(
    String groupId,
    String from,
    String fromName,
    String to,
    String toName,
    double amount,
  ) async {
    await _db.collection('settlements').add({
      'groupId': groupId,
      'from': from,
      'fromName': fromName,
      'to': to,
      'toName': toName,
      'amount': amount,
      'settled': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Reminders ───────────────────────────────────────────────────────────────

  Future<void> addReminder({
    required String userId,
    required String groupId,
    required String groupName,
    required String message,
    required DateTime dueDate,
  }) async {
    await _db.collection('reminders').add({
      'userId': userId,
      'groupId': groupId,
      'groupName': groupName,
      'message': message,
      'dueDate': Timestamp.fromDate(dueDate),
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markReminderRead(String reminderId) async {
    await _db
        .collection('reminders')
        .doc(reminderId)
        .update({'isRead': true});
  }

  // ── User lookup ─────────────────────────────────────────────────────────────

  /// Search by exact email (case-insensitive via emailLower field).
  /// Falls back to querying the `email` field directly for old user docs.
  Future<AppUser?> findUserByEmail(String email) async {
    final lower = email.trim().toLowerCase();
    if (lower.isEmpty) return null;

    // Primary: query emailLower (new docs)
    final snap1 = await _db
        .collection('users')
        .where('emailLower', isEqualTo: lower)
        .limit(1)
        .get();
    if (snap1.docs.isNotEmpty) {
      return AppUser.fromMap({...snap1.docs.first.data(), 'uid': snap1.docs.first.id});
    }

    // Fallback: query email field directly (old docs before emailLower was added)
    final snap2 = await _db
        .collection('users')
        .where('email', isEqualTo: lower)
        .limit(1)
        .get();
    if (snap2.docs.isNotEmpty) {
      return AppUser.fromMap({...snap2.docs.first.data(), 'uid': snap2.docs.first.id});
    }

    // Last resort: original case (in case stored as-is e.g. 'John@Gmail.com')
    final snap3 = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (snap3.docs.isEmpty) return null;
    return AppUser.fromMap({...snap3.docs.first.data(), 'uid': snap3.docs.first.id});
  }

  /// Search by phone number. Normalizes input and tries multiple formats.
  Future<AppUser?> findUserByPhone(String phone) async {
    final normalised = _normalizePhone(phone);
    if (normalised.isEmpty) return null;

    // Try the number as-is
    AppUser? result = await _findByPhone(normalised);
    if (result != null) return result;

    // 10-digit Indian number → try with +91
    if (normalised.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(normalised)) {
      result = await _findByPhone('+91$normalised');
      if (result != null) return result;
      result = await _findByPhone('91$normalised');
      if (result != null) return result;
    }

    // +91XXXXXXXXXX → try bare 10 digits
    if (normalised.startsWith('+91') && normalised.length == 13) {
      result = await _findByPhone(normalised.substring(3));
      if (result != null) return result;
      result = await _findByPhone(normalised.substring(1)); // 91XXXXXXXXXX
    }
    return result;
  }

  Future<AppUser?> _findByPhone(String phone) async {
    if (phone.isEmpty) return null;
    final snap = await _db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return AppUser.fromMap({...snap.docs.first.data(), 'uid': snap.docs.first.id});
  }

  /// Main entry point: search by email OR phone, auto-detected by input.
  Future<AppUser?> findUserByEmailOrPhone(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;
    if (q.contains('@')) return findUserByEmail(q);
    // Pure digits / phone-like string
    return findUserByPhone(q);
  }

  // Get all members of a group as AppUser objects
  Future<List<AppUser>> getGroupMembers(List<String> memberIds) async {
    if (memberIds.isEmpty) return [];
    final futures = memberIds.map((id) => _db.collection('users').doc(id).get());
    final docs = await Future.wait(futures);
    return docs.where((d) => d.exists).map((d) => AppUser.fromMap({...d.data()!, 'uid': d.id})).toList();
  }

  Future<void> updateGroup(String groupId, {String? name, String? icon}) async {
    final updates = <String, dynamic>{};
    if (name != null && name.isNotEmpty) updates['name'] = name;
    if (icon != null) updates['icon'] = icon;
    if (updates.isNotEmpty) {
      await _db.collection('groups').doc(groupId).update(updates);
    }
  }

  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
  }

  Future<Group?> getGroup(String groupId) async {
    final doc = await _db.collection('groups').doc(groupId).get();
    if (!doc.exists) return null;
    return Group.fromDoc(doc);
  }
}

final firebaseService = FirebaseService();
