import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showExceptionSnackbar({required String title, required String message}) =>
    Get.snackbar(title, message,
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);

void showSnackbar({required String title, required String message}) =>
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
