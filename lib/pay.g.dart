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
      merchantName: fields[0] as String,
      upiId: fields[1] as String,
      currency: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.merchantName)
      ..writeByte(1)
      ..write(obj.upiId)
      ..writeByte(2)
      ..write(obj.currency);
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
