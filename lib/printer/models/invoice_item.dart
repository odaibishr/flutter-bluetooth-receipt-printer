class InvoiceItem {
  final String name;
  final int quantity;
  final double price;
  final String? option;
  final List<String>? additions;
  final List<SubItem>? contains;

  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.option,
    this.additions,
    this.contains,
  });
}

class SubItem {
  final String name;
  final int quantity;

  SubItem({required this.name, required this.quantity});
}
