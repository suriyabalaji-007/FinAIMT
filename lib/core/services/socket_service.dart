import 'dart:io';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/data/providers/investment_provider.dart';
import 'package:fin_aimt/data/providers/loans_provider.dart';
import 'package:fin_aimt/data/providers/metrics_provider.dart';

final socketServiceProvider = Provider((ref) => SocketService(ref));

class SocketService {
  final Ref ref;
  late IO.Socket socket;

  SocketService(this.ref);

  void connect(String userId) {
    final baseUrl = Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to socket server');
      socket.emit('join', userId);
    });

    socket.on('notification', (data) {
      print('New Notification: $data');
    });

    socket.on('price_update', (data) {
      // Data is Map<String, int> representing assetId to price in paise
      ref.read(priceUpdatesProvider.notifier).updatePrices(Map<String, int>.from(data));
    });

    socket.on('portfolio_update', (data) {
      ref.read(userPortfolioProvider.notifier).updatePortfolio(List<Map<String, dynamic>>.from(data));
    });

    socket.on('loans_update', (data) {
      ref.read(loansProvider.notifier).updateLoans(List<Map<String, dynamic>>.from(data));
    });

    socket.on('finance_update', (data) {
      ref.read(metricsProvider.notifier).updateFromSocket(Map<String, dynamic>.from(data));
    });

    socket.onDisconnect((_) => print('Disconnected from socket server'));
  }

  void disconnect() {
    socket.disconnect();
  }
}
