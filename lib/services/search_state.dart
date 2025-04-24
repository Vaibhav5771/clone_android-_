import 'package:flutter/material.dart';

class SearchState extends ChangeNotifier {
  // Placeholder for search-related state
  String _query = '';

  String get query => _query;

  void setQuery(String newQuery) {
    _query = newQuery;
    notifyListeners();
  }

  void clearQuery() {
    _query = '';
    notifyListeners();
  }
}