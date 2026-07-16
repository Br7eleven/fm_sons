/// Converts a number to English words (Indian numbering system).
/// 1000 → "One Thousand", 1542 → "One Thousand Five Hundred and Forty Two"
String numberToWords(int n) {
  if (n < 0) return "Negative ${numberToWords(-n)}";
  if (n <= 20) {
    return [
      "",
      "One",
      "Two",
      "Three",
      "Four",
      "Five",
      "Six",
      "Seven",
      "Eight",
      "Nine",
      "Ten",
      "Eleven",
      "Twelve",
      "Thirteen",
      "Fourteen",
      "Fifteen",
      "Sixteen",
      "Seventeen",
      "Eighteen",
      "Nineteen",
      "Twenty",
    ][n];
  }
  if (n < 100) {
    return [
      "",
      "",
      "Twenty",
      "Thirty",
      "Forty",
      "Fifty",
      "Sixty",
      "Seventy",
      "Eighty",
      "Ninety",
    ][n ~/ 10] + (n % 10 != 0 ? " ${numberToWords(n % 10)}" : "");
  }
  if (n < 1000) {
    return "${numberToWords(n ~/ 100)} Hundred${n % 100 != 0 ? " and ${numberToWords(n % 100)}" : ""}";
  }
  if (n < 100000) {
    return "${numberToWords(n ~/ 1000)} Thousand${n % 1000 != 0 ? " ${numberToWords(n % 1000)}" : ""}";
  }
  if (n < 10000000) {
    return "${numberToWords(n ~/ 100000)} Lakh${n % 100000 != 0 ? " ${numberToWords(n % 100000)}" : ""}";
  }
  return n.toString();
}
