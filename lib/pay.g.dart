// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pay.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final int typeId = 0;

  @override
  Order read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Order()
      ..orderId = fields[0] as String
      ..amount = fields[1] as String
      ..clientNotes = fields[2] as String
      ..qrCodeUrl = fields[3] as String
      ..invoiceImageUrl = fields[4] as String
      ..transactionImageUrl = fields[5] as String
      ..utrNumber = fields[6] as String
      ..status = fields[7] as String
      ..timestamp = fields[8] as DateTime;
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.orderId)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.clientNotes)
      ..writeByte(3)
      ..write(obj.qrCodeUrl)
      ..writeByte(4)
      ..write(obj.invoiceImageUrl)
      ..writeByte(5)
      ..write(obj.transactionImageUrl)
      ..writeByte(6)
      ..write(obj.utrNumber)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 1;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      id: fields[0] as int,
      merchantName: fields[1] as String,
      upiId: fields[2] as String,
      currency: fields[3] as String,
      color: fields[4] as int,
      createShortcut: fields[5] as bool,
      archived: fields[6] as bool,
      archiveDate: fields[7] as DateTime?,
      productIds: (fields[8] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.merchantName)
      ..writeByte(2)
      ..write(obj.upiId)
      ..writeByte(3)
      ..write(obj.currency)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.createShortcut)
      ..writeByte(6)
      ..write(obj.archived)
      ..writeByte(7)
      ..write(obj.archiveDate)
      ..writeByte(8)
      ..write(obj.productIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 2;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as int,
      name: fields[1] as String,
      price: fields[2] as double,
      description: fields[3] as String,
      imageUrl: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
