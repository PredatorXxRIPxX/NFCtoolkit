import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:nfctoolkit/components/usemodelSheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceCard extends StatefulWidget {
  final String name;
  final String nfcNumber;
  final IconData? icon;

  const DeviceCard(this.name, this.nfcNumber, this.icon, {super.key});

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  late Future<SharedPreferences> _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = SharedPreferences.getInstance();
  }

  void useTag(String name, String nfcNumber) async {
    await showModalBottomSheet(
      context: context, // Use the current context
      builder: (BuildContext context) {
        return UseModelSheet(name, nfcNumber);
      },
    );
  }

  Future<void> deleteTag(String name, String nfcNumber) async {
    final prefs = await _prefs;
    List<String> devices = prefs.getStringList('Devices') ?? [];

    devices.removeWhere((device) {
      final Map<String, dynamic> deviceMap = jsonDecode(device);
      return deviceMap['DeviceName'] == name && deviceMap['NFC'] == nfcNumber;
    });

    await prefs.setStringList('Devices', devices);
    setState(() {}); 

    print('Deleting tag: $name, $nfcNumber');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: SwipeActionCell(
        key: ObjectKey(widget),
        trailingActions: [
          SwipeAction(
            onTap: (CompletionHandler handler) async {
              useTag(widget.name, widget.nfcNumber);
              handler(false); 
            },
            color: Colors.green,
            icon: const Icon(Icons.wrap_text_outlined, color: Colors.white),
          ),
          SwipeAction(
            onTap: (CompletionHandler handler) async {
              await deleteTag(widget.name, widget.nfcNumber);
              handler(true); // No need to await handler
            },
            color: Colors.red,
            icon: const Icon(Icons.delete, color: Colors.white),
          ),
        ],
        child: Card(
          child: ListTile(
            leading: Icon(
              widget.icon ?? Icons.nfc_outlined,
              color: Colors.deepPurple,
              size: 50,
            ),
            title: Text(
              widget.name,
              style: const TextStyle(color: Colors.grey, fontSize: 20),
            ),
            subtitle: const Text("Tag saved in storage"),
          ),
        ),
      ),
    );
  }
}
