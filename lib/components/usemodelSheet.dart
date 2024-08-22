import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class UseModelSheet extends StatefulWidget {
  final String deviceName;
  final String nfcNumber;

  const UseModelSheet(this.deviceName, this.nfcNumber, {super.key});

  @override
  State<UseModelSheet> createState() => _UseModelSheetState();
}

class _UseModelSheetState extends State<UseModelSheet> {
  @override
  void initState() {
    super.initState();
    useTag();
  }

  Future<void> useTag() async {
    var available = await FlutterNfcKit.nfcAvailability;

    if (available == NFCAvailability.available) {
      var tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 10));

      if (tag.ndefWritable == true&&tag.ndefAvailable == true) {
        await FlutterNfcKit.writeNDEFRecords(
          [ndef.UriRecord.fromString(widget.nfcNumber)],
        );
        print("Record written: ${widget.nfcNumber}");
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('NFC Not Writable'),
              content: const Text('This NFC tag is not writable.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('NFC Not Available'),
            content: const Text('This device does not support NFC.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "I'm using device ${widget.deviceName}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Lottie.asset(
            'assets/nfcScan.json',
            width: 200,
            height: 200,
          ),
        ],
      ),
    );
  }
}
