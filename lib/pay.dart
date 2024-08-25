import 'package:hive/hive.dart';
// For getting application documents directory

part 'pay.g.dart';

@HiveType(typeId: 0)
class Order extends HiveObject {
  @HiveField(0)
  late String orderId;

  @HiveField(1)
  late String amount;

  @HiveField(2)
  late String clientNotes;

  @HiveField(3)
  late String qrCodeUrl;

  @HiveField(4)
  late String invoiceImageUrl;

  @HiveField(5)
  late String transactionImageUrl;

  @HiveField(6)
  late String utrNumber;

  @HiveField(7)
  late String status;

  @HiveField(8)
  late DateTime timestamp;
}

@HiveType(typeId: 1)
class Accounts extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  late String merchantName;

  @HiveField(2)
  late String upiId;

  @HiveField(3)
  late String currency;

  @HiveField(4)
  late int color;

  @HiveField(5)
  late bool createShortcut;

  @HiveField(6)
  late bool archived; // New field to indicate if the account is archived

  @HiveField(7)
  DateTime?
      archiveDate; // New field to store the date when the account was archived

  @HiveField(8)
  late List<int> productIds; // List of product IDs

  Accounts({
    required this.id,
    required this.merchantName,
    required this.upiId,
    required this.currency,
    required this.color,
    this.createShortcut = false,
    this.archived = false,
    this.archiveDate,
    required this.productIds,
  });
}

@HiveType(typeId: 2)
class Product extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double price;

  @HiveField(3)
  late String description;

  @HiveField(4)
  late String imageUrl;

  @HiveField(5)
  bool archived = false; // New field

  @HiveField(6)
  DateTime? archiveDate; // New field

  @HiveField(7)
  bool createShortcut = false; // New field

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.archived = false, // Default value
    this.archiveDate,
    this.createShortcut = false, // Default value
  });
}
