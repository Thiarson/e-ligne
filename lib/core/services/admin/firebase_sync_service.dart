import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ligne/core/constants/db_fields.dart';
import 'package:ligne/utils/helpers/db_manager.dart';
import 'package:ligne/core/errors/sync_exception.dart';
import 'package:sqflite/sqflite.dart';

class FirebaseSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Sync all local data to Firebase
  Future<void> syncLocalToFirebase() async {
    if (!isAuthenticated) {
      throw const SyncException('User not authenticated');
    }

    final userId = _auth.currentUser!.uid;
    final db = DatabaseManager.getDatabaseOrThrow();
    final batch = _firestore.batch();

    try {
      // Sync cars
      final cars = await db.query(carTable);
      for (final car in cars) {
        batch.set(
          _firestore.collection('users').doc(userId).collection('cars').doc(car[carIdColumn].toString()),
          {
            'registration': car[carRegistrationColumn],
            'lastSynced': FieldValue.serverTimestamp(),
          },
        );
      }

      // Sync expenses
      final expenses = await db.query(expenseTable);
      for (final expense in expenses) {
        batch.set(
          _firestore.collection('users').doc(userId).collection('expenses').doc(expense[expenseIdColum].toString()),
          {
            'carId': expense[expenseCarIdColumn],
            'description': expense[expenseDescriptionColumn],
            'amount': expense[expenseAmountColumn],
            'source': expense[expenseSourceColumn],
            'date': expense[expenseDateColumn],
            'lastSynced': FieldValue.serverTimestamp(),
          },
        );
      }

      // Sync incomes
      final incomes = await db.query(incomeTable);
      for (final income in incomes) {
        batch.set(
          _firestore.collection('users').doc(userId).collection('incomes').doc(income[incomeIdColumn].toString()),
          {
            'carId': income[incomeCarIdColumn],
            'description': income[incomeDescriptionColumn],
            'amount': income[incomeAmountColumn],
            'source': income[incomeSourceColumn],
            'date': income[incomeDateColumn],
            'lastSynced': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
    } catch (e) {
      throw SyncException('Failed to sync data to Firebase: ${e.toString()}');
    }
  }

  // Sync data from Firebase to local
  Future<void> syncFirebaseToLocal() async {
    if (!isAuthenticated) {
      throw const SyncException('User not authenticated');
    }

    final userId = _auth.currentUser!.uid;
    final db = DatabaseManager.getDatabaseOrThrow();

    try {
      // Sync cars
      final carsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cars')
          .get();

      for (final doc in carsSnapshot.docs) {
        await db.insert(
          carTable,
          {
            carIdColumn: int.parse(doc.id),
            carRegistrationColumn: doc.data()['registration'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Sync expenses
      final expensesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .get();

      for (final doc in expensesSnapshot.docs) {
        await db.insert(
          expenseTable,
          {
            expenseIdColum: int.parse(doc.id),
            expenseCarIdColumn: doc.data()['carId'],
            expenseDescriptionColumn: doc.data()['description'],
            expenseAmountColumn: doc.data()['amount'],
            expenseSourceColumn: doc.data()['source'],
            expenseDateColumn: doc.data()['date'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Sync incomes
      final incomesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('incomes')
          .get();

      for (final doc in incomesSnapshot.docs) {
        await db.insert(
          incomeTable,
          {
            incomeIdColumn: int.parse(doc.id),
            incomeCarIdColumn: doc.data()['carId'],
            incomeDescriptionColumn: doc.data()['description'],
            incomeAmountColumn: doc.data()['amount'],
            incomeSourceColumn: doc.data()['source'],
            incomeDateColumn: doc.data()['date'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      throw SyncException('Failed to sync data from Firebase: ${e.toString()}');
    }
  }

  // Full synchronization (two-way sync)
  Future<void> syncData() async {
    if (!isAuthenticated) {
      throw const SyncException('User not authenticated');
    }

    try {
      // First sync local changes to Firebase
      await syncLocalToFirebase();
      
      // Then get any updates from Firebase
      await syncFirebaseToLocal();
    } catch (e) {
      rethrow;
    }
  }
}
