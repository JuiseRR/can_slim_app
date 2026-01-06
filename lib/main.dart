import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CanSlimApp());
}

class CanSlimApp extends StatelessWidget {
  const CanSlimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScanScreen(),
    );
  }
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const String BASE_URL =
      "https://can-slim-backend.fly.dev";

  String region = "USA";
  bool loading = true;
  bool marketOk = false;
  List<dynamic> stocks = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      loading = true;
    });

    try {
      final url = Uri.parse("$BASE_URL/scan?region=$region");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        setState(() {
          marketOk = decoded['market_ok'] ?? false;
          stocks = decoded['data'] ?? [];
        });
      } else {
        setState(() {
          marketOk = false;
          stocks = [];
        });
      }
    } catch (e) {
      setState(() {
        marketOk = false;
        stocks = [];
      });
      debugPrint("fetchData error: $e");
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CAN SLIM Scanner"),
        actions: [
          DropdownButton<String>(
            value: region,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: "USA", child: Text("USA")),
              DropdownMenuItem(value: "EU", child: Text("EU")),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  region = value;
                });
                fetchData();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: marketOk ? Colors.green[700] : Colors.red[700],
            padding: const EdgeInsets.all(8),
            child: Text(
              marketOk ? "MARKET: ON" : "MARKET: OFF",
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : !marketOk
                    ? const Center(
                        child: Text(
                          "Market is OFF\nNo scans today",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : stocks.isEmpty
                        ? const Center(child: Text("No candidates"))
                        : ListView.builder(
                            itemCount: stocks.length,
                            itemBuilder: (context, index) {
                              final s = stocks[index];
                              return ListTile(
                                title: Text(s['ticker']),
                                subtitle: Text("RS: ${s['rs']}"),
                                trailing: CircleAvatar(
                                  child: Text(s['score'].toString()),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
