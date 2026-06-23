import 'invoice_item.dart';

class ReceiptData {
  final String orderNumber;
  final String storeName;
  final String storeAddress;
  final DateTime invoiceDate;
  final List<InvoiceItem> items;
  final double deliveryFee;
  final String customerAddress;
  final String branchAddress;
  final String paymentMethod;
  final String notes;
  final String customerName;
  final String carNumber;

  ReceiptData({
    required this.orderNumber,
    required this.storeName,
    required this.storeAddress,
    required this.invoiceDate,
    required this.items,
    this.deliveryFee = 600.0,
    required this.customerAddress,
    required this.branchAddress,
    required this.paymentMethod,
    required this.notes,
    required this.customerName,
    required this.carNumber,
  });
}
