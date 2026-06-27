import 'invoice_item.dart';

class ReceiptData {
  final String orderNumber;
  final String storeName;
  final String storeAddress;
  final DateTime invoiceDate;
  final List<InvoiceItem> items;
  final double deliveryFee;
  final String currency;
  final String? logo;

  ReceiptData({
    required this.orderNumber,
    required this.storeName,
    required this.storeAddress,
    required this.invoiceDate,
    required this.items,
    required this.deliveryFee,
    this.currency = 'ر.ي',
    this.logo,
  });
}
