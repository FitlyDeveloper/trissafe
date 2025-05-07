import 'package:flutter/material.dart';

class DialogHelper {
  static Future<void> showStandardDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            if (cancelText != null)
              TextButton(
                child: Text(cancelText),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onCancel != null) onCancel();
                },
              ),
            TextButton(
              child: Text(confirmText ?? 'OK'),
              onPressed: () {
                Navigator.of(context).pop();
                if (onConfirm != null) onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> showLoadingDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
} 