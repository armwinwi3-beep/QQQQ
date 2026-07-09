class OrderModel {
  final String id;
  final String foodName;
  final String status; // 'pending', 'ready', 'completed'

  OrderModel({required this.id, required this.foodName, required this.status});

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    return OrderModel(
      id: id,
      foodName: data['food_name'] ?? 'Unknown',
      status: data['status'] ?? 'pending',
    );
  }
}
