enum OrderedItemKind { folder, recording }

/// One row of a folder's list, in the position the user chose.
class OrderedItem {
  final String id;
  final OrderedItemKind kind;

  const OrderedItem({required this.id, required this.kind});
}
