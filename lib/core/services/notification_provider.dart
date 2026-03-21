import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

// Provider that holds live incoming notifications
final notificationProvider =
    NotifierProvider<NotificationNotifier, List<PaymentNotification>>(
        NotificationNotifier.new);

class PaymentNotification {
  final String senderName;
  final int amount; // in paise
  final String transactionId;
  final DateTime time;

  PaymentNotification({
    required this.senderName,
    required this.amount,
    required this.transactionId,
    required this.time,
  });
}

class NotificationNotifier extends Notifier<List<PaymentNotification>> {
  io.Socket? _socket;

  @override
  List<PaymentNotification> build() => [];

  void connect(String userId) {
    _socket = io.io('http://10.0.2.2:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('join', userId);
    });

    _socket!.on('notification', (data) {
      if (data['type'] == 'PAYMENT_RECEIVED') {
        final notification = PaymentNotification(
          senderName: data['senderName'] ?? 'Someone',
          amount: data['amount'] ?? 0,
          transactionId: data['transactionId'] ?? '',
          time: DateTime.now(),
        );
        state = [notification, ...state];
      }
    });
  }

  void disconnect() {
    _socket?.disconnect();
  }
}

// Overlay widget to show incoming payment toast
class PaymentNotificationOverlay extends ConsumerWidget {
  const PaymentNotificationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    if (notifications.isEmpty) return const SizedBox.shrink();

    final latest = notifications.first;
    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade800,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.green.withValues(alpha: 0.4), blurRadius: 12)
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${(latest.amount / 100).toStringAsFixed(2)} received!',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    Text(
                      'From ${latest.senderName}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
