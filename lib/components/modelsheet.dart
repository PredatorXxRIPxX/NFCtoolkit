import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomModelSheet extends StatefulWidget {
  final void Function(String tagName, String tagData)? onDeviceAdded;

  const CustomModelSheet({super.key, this.onDeviceAdded});

  @override
  State<CustomModelSheet> createState() => _CustomModelSheetState();
}

class _CustomModelSheetState extends State<CustomModelSheet> {
  NfcManager nfcManager = NfcManager.instance;
  String? tagData;

  Future<void> saveDataToStorage(String tagName, String tagData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> values = prefs.getStringList("Devices") ?? [];
    String newDeviceJson = jsonEncode({'DeviceName': tagName, 'NFC': tagData});
    values.add(newDeviceJson);
    await prefs.setStringList("Devices", values);

    if (widget.onDeviceAdded != null) {
      widget.onDeviceAdded!(tagName, tagData);
    }

    Navigator.of(context).pop(); // Close the sheet
    Navigator.of(context).pop(tagData); // Pass data back to previous screen
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> readingNfc() async {
    await nfcManager.startSession(
      onDiscovered: (NfcTag tag) async {
        setState(() {
          tagData = tag.data.toString(); // Ensure this matches your tag data structure
        });

        await nfcManager.stopSession(alertMessage: 'NFC tag read successfully');

        if (tagData != null) {
          _showTagDataDialog();
        }
      },
    );
  }

  void getNameOfTag(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String tagName = '';
        return AlertDialog(
          title: const Text('Name of NFC Tag'),
          content: TextField(
            onChanged: (value) {
              tagName = value;
            },
            decoration: const InputDecoration(
              hintText: 'Enter name of NFC tag',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                if (tagName.isNotEmpty && tagData != null) {
                  saveDataToStorage(tagName, tagData!);
                } else {
                  _showSnackBar('Please enter a tag name.');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showTagDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('NFC Tag Data'),
          content: Text(tagData ?? 'No data found'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(tagData); // Pass data back to previous screen
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                getNameOfTag(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    readingNfc();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Adjust height for bottom sheet
        children: [
          const SizedBox(height: 20),
          const Text(
            'Please place your NFC tag behind your phone',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 21, color: Colors.black, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Lottie.asset('assets/nfcScan.json', height: 200, width: 200),
          const SizedBox(height: 20),
          const Text(
            "We are reading your NFC tag...",
            style: TextStyle(
                fontSize: 21, color: Colors.black, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
