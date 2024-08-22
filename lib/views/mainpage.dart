import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfctoolkit/components/devicecard.dart';
import 'package:nfctoolkit/components/modelsheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  NfcManager nfcManager = NfcManager.instance;
  bool isAvailable = false;

  Future<void> _checkPermissions() async {
    var response = await Permission.storage.request();
    if (response.isGranted) {
      print('Storage permission granted');
    } else {
      print('Storage permission denied');
    }
  }

  Future<void> _checkNfc() async {
    bool nfcAvailable = await nfcManager.isAvailable();
    setState(() {
      isAvailable = nfcAvailable;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _checkNfc();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'NFC Toolkit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (!isAvailable) {
            return const Center(
              child: Text(
                'NFC is not available. Try enabling it through settings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 20),
              ),
            );
          }

          return const UserInterface();
        },
      ),
    );
  }
}

class UserInterface extends StatefulWidget {
  const UserInterface({super.key});

  @override
  State<UserInterface> createState() => _UserInterfaceState();
}

class _UserInterfaceState extends State<UserInterface> {
  late Future<SharedPreferences> prefsFuture;
  List<Map<String, dynamic>> jsonDevices = [];

  @override
  void initState() {
    super.initState();
    prefsFuture = SharedPreferences.getInstance();
  }

  Future<void> _refreshDevices() async {
    final prefs = await SharedPreferences.getInstance();
    var devices = prefs.getStringList('Devices') ?? [];
    jsonDevices = [];

    for (var deviceJson in devices) {
      try {
        jsonDevices.add(jsonDecode(deviceJson));
      } catch (e) {
        print('Error parsing JSON: $e');
      }
    }

    setState(() {});
  }

  void _handleDeviceAdded(String tagName, String tagData) async {
    await _refreshDevices();
  }

  void _showModelSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return CustomModelSheet(onDeviceAdded: _handleDeviceAdded);
      },
    );

    if (result != null) {
      _handleDeviceAdded(result['tagName']!, result['tagData']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<SharedPreferences>(
        future: prefsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'An error has occurred',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final prefs = snapshot.data;
          var devices = prefs?.getStringList('Devices') ?? [];
          jsonDevices = [];

          for (var deviceJson in devices) {
            try {
              jsonDevices.add(jsonDecode(deviceJson));
            } catch (e) {
              print('Error parsing JSON: $e');
            }
          }

          return RefreshIndicator(
            onRefresh: _refreshDevices,
            child: ListView.builder(
              itemCount: jsonDevices.length,
              itemBuilder: (context, index) {
                var device = jsonDevices[index];
                return DeviceCard(
                  device['DeviceName'] ?? 'Unknown Device',
                  device['NFC'] ?? 'No NFC Number',
                  Icons.nfc_outlined,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 7.0,
        onPressed: () => _showModelSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}