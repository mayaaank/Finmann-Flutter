import '../constants/app_constants.dart';
import '../../data/models/transaction_model.dart';

class NlpResult {
  final double? amount;
  final TransactionType type;
  final String? category;
  final String? description;
  final DateTime date;

  const NlpResult({
    this.amount,
    required this.type,
    this.category,
    this.description,
    required this.date,
  });
}

class NlpParser {
  static final _amountRe = RegExp(r'(?:rs\.?|₹|inr)?\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false);

  static final _incomeWords = ['received','got','earned','income','salary','allowance','paid me','credited'];
  static final _expenseWords = ['spent','paid','bought','purchased','used','withdrew','expense'];

  static final _categoryKeywords = <String, List<String>>{
    'Food & Dining': ['food','eat','dinner','lunch','breakfast','mess','canteen','restaurant','swiggy','zomato','chai','coffee','snack','pizza'],
    'Transport': ['uber','ola','auto','bus','metro','train','petrol','fuel','cab','rickshaw','transport','travel'],
    'Tuition & Fees': ['fees','tuition','college','university','semester','exam','admission'],
    'Books & Stationery': ['book','stationery','pen','pencil','notebook','amazon','flipkart','novel','textbook'],
    'Entertainment': ['movie','netflix','prime','spotify','game','outing','party','concert','show'],
    'Subscriptions': ['subscription','monthly','yearly','plan','recharge','sim','internet','wifi'],
    'Health': ['medicine','doctor','pharmacy','hospital','gym','medical','health','chemist'],
    'Shopping': ['shopping','clothes','shirt','shoes','bag','mall','myntra','fashion'],
    'Utilities': ['electricity','water','gas','internet','bill','recharge','utility'],
    'Allowance': ['allowance','pocket money','parents','home'],
  };

  static NlpResult? parse(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.isEmpty) return null;

    // Amount
    final amtMatch = _amountRe.firstMatch(lower);
    final amount = amtMatch != null ? double.tryParse(amtMatch.group(1)!) : null;

    // Type
    TransactionType type = TransactionType.expense;
    for (final w in _incomeWords) {
      if (lower.contains(w)) { type = TransactionType.income; break; }
    }

    // Category
    String? category;
    int bestScore = 0;
    _categoryKeywords.forEach((cat, keywords) {
      int score = 0;
      for (final kw in keywords) {
        if (lower.contains(kw)) score++;
      }
      if (score > bestScore) { bestScore = score; category = cat; }
    });

    // Date — simple "yesterday" / "today"
    DateTime date = DateTime.now();
    if (lower.contains('yesterday')) {
      date = DateTime.now().subtract(const Duration(days: 1));
    }

    // Description: strip amount + type words → clean phrase
    var desc = input.replaceAll(RegExp(r'(?:rs\.?|₹|inr)?\s*\d+(?:\.\d{1,2})?', caseSensitive: false), '').trim();
    for (final w in [..._incomeWords, ..._expenseWords, 'on', 'for', 'at', 'in', 'the', 'a', 'an']) {
      desc = desc.replaceAll(RegExp('\\b$w\\b', caseSensitive: false), '').trim();
    }
    desc = desc.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (desc.isEmpty) desc = category ?? 'Transaction';

    return NlpResult(
      amount: amount,
      type: type,
      category: category,
      description: desc,
      date: date,
    );
  }
}
