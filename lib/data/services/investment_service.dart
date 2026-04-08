import 'api_service.dart';
import '../models/finance_models.dart';

class InvestmentService {
  final ApiService _api = ApiService();

  Future<List<Investment>> getPortfolio() async {
    final response = await _api.get('investments');
    final List<dynamic> data = _api.handleResponse(response);
    return data.map((json) => Investment.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> trade({
    required String assetId,
    required String assetName,
    required String category,
    required double quantity,
    required double price,
    required String side,
  }) async {
    final response = await _api.post('investments/trade', {
      'assetId': assetId,
      'assetName': assetName,
      'category': category,
      'quantity': quantity,
      'price': (price * 100).toInt(), // convert to paise
      'side': side,
    });
    return _api.handleResponse(response);
  }
}
