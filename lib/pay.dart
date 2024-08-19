import 'package:hive/hive.dart';

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
class Settings extends HiveObject {
  @HiveField(0)
  late String merchantName;

  @HiveField(1)
  late String upiId;

  @HiveField(2)
  late String currency;

  Settings({required this.merchantName, required this.upiId, required this.currency});
}
