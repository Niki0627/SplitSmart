// lib/core/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum SplitType { equal, unequal, percentage }

enum ExpenseCategory { food, travel, movie, bills, groceries, utilities, other }

extension ExpenseCategoryExt on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food: return 'Food';
      case ExpenseCategory.travel: return 'Travel';
      case ExpenseCategory.movie: return 'Movie';
      case ExpenseCategory.bills: return 'Bills';
      case ExpenseCategory.groceries: return 'Groceries';
      case ExpenseCategory.utilities: return 'Utilities';
      case ExpenseCategory.other: return 'Other';
    }
  }
  String get icon {
    switch (this) {
      case ExpenseCategory.food: return 'restaurant';
      case ExpenseCategory.travel: return 'flight';
      case ExpenseCategory.movie: return 'movie';
      case ExpenseCategory.bills: return 'receipt_long';
      case ExpenseCategory.groceries: return 'local_grocery_store';
      case ExpenseCategory.utilities: return 'lightbulb';
      case ExpenseCategory.other: return 'more_horiz';
    }
  }
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String? upiId;
  final String currency;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.upiId,
    this.currency = 'INR',
  });

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'] ?? '',
    name: map['name'] ?? '',
    email: map['email'] ?? '',
    phone: map['phone'],
    photoUrl: map['photoUrl'],
    upiId: map['upiId'],
    currency: map['currency'] ?? 'INR',
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'upiId': upiId,
    'currency': currency,
  };

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }
}

class Group {
  final String id;
  final String name;
  final String icon;
  final List<String> memberIds;
  final String createdBy;
  final DateTime createdAt;
  double totalAmount;

  Group({
    required this.id, required this.name, required this.icon,
    required this.memberIds, required this.createdBy,
    required this.createdAt, this.totalAmount = 0,
  });

  factory Group.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id, name: d['name'] ?? '', icon: d['icon'] ?? 'group',
      memberIds: List<String>.from(d['memberIds'] ?? []),
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalAmount: (d['totalAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name, 'icon': icon, 'memberIds': memberIds,
    'createdBy': createdBy, 'createdAt': Timestamp.fromDate(createdAt),
    'totalAmount': totalAmount,
  };
}

class Expense {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String paidBy;
  final String paidByName;
  final SplitType splitType;
  final List<String> participants;
  final ExpenseCategory category;
  final DateTime date;
  final DateTime createdAt;

  Expense({
    required this.id, required this.groupId, required this.description,
    required this.amount, required this.paidBy, required this.paidByName,
    required this.splitType, required this.participants,
    required this.category, required this.date, required this.createdAt,
  });

  factory Expense.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id, groupId: d['groupId'] ?? '', description: d['description'] ?? '',
      amount: (d['amount'] ?? 0).toDouble(), paidBy: d['paidBy'] ?? '',
      paidByName: d['paidByName'] ?? '',
      splitType: SplitType.values.firstWhere(
        (e) => e.name == d['splitType'], orElse: () => SplitType.equal),
      participants: List<String>.from(d['participants'] ?? []),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == d['category'], orElse: () => ExpenseCategory.other),
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'groupId': groupId, 'description': description, 'amount': amount,
    'paidBy': paidBy, 'paidByName': paidByName, 'splitType': splitType.name,
    'participants': participants, 'category': category.name,
    'date': Timestamp.fromDate(date), 'createdAt': Timestamp.fromDate(createdAt),
  };
}

class Settlement {
  final String id;
  final String groupId;
  final String from;
  final String fromName;
  final String to;
  final String toName;
  final double amount;
  final bool settled;
  final DateTime createdAt;

  Settlement({
    required this.id, required this.groupId,
    required this.from, required this.fromName,
    required this.to, required this.toName,
    required this.amount, this.settled = false, required this.createdAt,
  });

  factory Settlement.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Settlement(
      id: doc.id, groupId: d['groupId'] ?? '',
      from: d['from'] ?? '', fromName: d['fromName'] ?? '',
      to: d['to'] ?? '', toName: d['toName'] ?? '',
      amount: (d['amount'] ?? 0).toDouble(), settled: d['settled'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class Reminder {
  final String id;
  final String userId;
  final String groupId;
  final String groupName;
  final String message;
  final DateTime dueDate;
  final bool isRead;

  Reminder({
    required this.id, required this.userId, required this.groupId,
    required this.groupName, required this.message,
    required this.dueDate, this.isRead = false,
  });

  factory Reminder.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Reminder(
      id: doc.id, userId: d['userId'] ?? '', groupId: d['groupId'] ?? '',
      groupName: d['groupName'] ?? '', message: d['message'] ?? '',
      dueDate: (d['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: d['isRead'] ?? false,
    );
  }
}
