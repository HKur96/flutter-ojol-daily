import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hanya ambil angka, buang semua karakter non-digit
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Ubah string menjadi integer lalu format dengan pemisah ribuan
    final int parsedValue = int.parse(cleanText);
    final formatter = NumberFormat('#,###', 'id_ID');
    final String formattedText = formatter.format(parsedValue);

    // Kembalikan nilai baru beserta posisi kursor di akhir teks
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}