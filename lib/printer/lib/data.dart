import '../models/invoice_item.dart';
import '../models/receipt_data.dart';

final List<InvoiceItem> items = [
  InvoiceItem(
    name: "برجر الدجاج صغير",
    quantity: 1,
    price: 1800.0,
    option: "ابيض كلاسيك",
  ),
  InvoiceItem(
    name: "برجر الدجاج صغير",
    quantity: 1,
    price: 1800.0,
    option: "اسمر بالشوفان",
  ),
  InvoiceItem(
    name: "برجر الدجاج صغير",
    quantity: 1,
    price: 1800.0,
    option: "اسمر بالشوفان",
    additions: ["كوكتيل بالخيار المخلل والبصل المقطع - ثومية كلاسيك"],
  ),
  InvoiceItem(
    name: "برجر الدجاج صغير",
    quantity: 1,
    price: 1800.0,
    option: "اسمر بالشوفان",
    additions: ["كوكتيل - رانش"],
  ),
  InvoiceItem(
    name: "الاسم",
    quantity: 1,
    price: 5000.0,
    option: "صغير",
    contains: [
      SubItem(name: "ايس سبانش لاتية", quantity: 1),
      SubItem(name: "فرنش فرايز", quantity: 2),
      SubItem(name: "توست مرتاديلا لحم", quantity: 5),
      SubItem(name: "توست موزاريلا بالطماطم بالبيستو الايطالي", quantity: 2),
      SubItem(name: "وجبة برجر الدجاج صغير", quantity: 2),
    ],
  ),
  InvoiceItem(
    name: "ايس سبانش لاتية",
    quantity: 1,
    price: 1700.0,
    option: "مفرد",
  ),
  InvoiceItem(
    name: "ايس سبانش لاتية",
    quantity: 1,
    price: 1700.0,
    option: "مفرد",
  ),
];

final ReceiptData dummyReceipt = ReceiptData(
  orderNumber: "93160",
  storeName: "مطعم يوتيرن - U-turn - فرع حدة",
  storeAddress: "شارع حدة بالقرب من شركة صافر للنفط",
  invoiceDate: DateTime.now(),
  items: items,
  deliveryFee: 600.0,
  customerAddress: "شارع إيران مكتب تكنوكيز",
  branchAddress: "شارع إيران عمارة بنك اليمن والكويت الدور الخامس",
  paymentMethod: "الدفع عند الاستلام",
  notes: "لا يوجد ملاحظات",
  customerName: "عبدالرحمن طلبات تجريبية-تست",
  carNumber: "1",
);
