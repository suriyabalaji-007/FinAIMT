import 'api_service.dart';
import '../models/finance_models.dart';

class FinanceService {
  final ApiService _api = ApiService();

  Future<List<Loan>> getLoans() async {
    final response = await _api.get('finance/loans');
    final List<dynamic> data = _api.handleResponse(response);
    return data.map((json) => Loan.fromJson(json)).toList();
  }

  Future<void> payEMI(String loanId) async {
    final response = await _api.post('finance/pay-emi', {'loanId': loanId});
    _api.handleResponse(response);
  }

  Future<List<dynamic>> getMetrics() async {
    final response = await _api.get('finance/metrics');
    return _api.handleResponse(response);
  }

  Future<Map<String, dynamic>> transferFunds(String receiverId, double amount, String pin) async {
    final response = await _api.post('transfer', {
      'receiverId': receiverId,
      'amount': (amount * 100).toInt(), // convert to paise
      'transactionPin': pin,
    });
    return _api.handleResponse(response);
  }
}
