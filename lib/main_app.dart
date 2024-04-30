import 'package:flutter/material.dart';
import 'package:hmi_networking/hmi_networking.dart';
import 'package:plc_signals_adjustment/presentation/signals/signals_page.dart';
///
class MainApp extends StatelessWidget {
  final JdsService _jdsService;
  final DsClient _dsClient;
  ///
  const MainApp({
    super.key,
    required JdsService jdsService,
    required DsClient dsClient,
  }) : 
    _dsClient = dsClient,
    _jdsService = jdsService;
  //
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignalsPage(
        jdsService: _jdsService,
        dsClient: _dsClient,
      ),
      theme: ThemeData.dark(),
    );
  }
}