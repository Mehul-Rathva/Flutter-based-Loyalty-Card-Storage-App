import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(
    ChangeNotifierProvider<LoyaltyCardData>(
      create: (context) => LoyaltyCardData(),
      builder: (context, child) => const MyApp(),
    ),
  );
}

class LoyaltyCard {
  String name;
  String cardNumber;
  String barcodeData;
  DateTime? expiryDate;
  String imageUrl;

  LoyaltyCard({
    required this.name,
    required this.cardNumber,
    required this.barcodeData,
    this.expiryDate,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'cardNumber': cardNumber,
        'barcodeData': barcodeData,
        'expiryDate': expiryDate?.toIso8601String(),
        'imageUrl': imageUrl,
      };

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) => LoyaltyCard(
        name: json['name'] as String,
        cardNumber: json['cardNumber'] as String,
        barcodeData: json['barcodeData'] as String,
        expiryDate: json['expiryDate'] != null
            ? DateTime.tryParse(json['expiryDate'] as String)
            : null,
        imageUrl: json['imageUrl'] as String,
      );
}

class LoyaltyCardData extends ChangeNotifier {
  List<LoyaltyCard> _cards = [];

  List<LoyaltyCard> get cards => _cards;

  LoyaltyCardData() {
    _loadCards();
  }

  Future<void> addCard(LoyaltyCard card) async {
    _cards.add(card);
    await _saveCards();
    notifyListeners();
  }

  Future<void> removeCard(LoyaltyCard card) async {
    _cards.remove(card);
    await _saveCards();
    notifyListeners();
  }

  Future<void> _saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    final cardList = _cards.map((card) => card.toJson()).toList();
    prefs.setString('loyaltyCards', json.encode(cardList));
  }

  Future<void> _loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final cardString = prefs.getString('loyaltyCards');
    if (cardString != null) {
      final List<dynamic> cardList = json.decode(cardString) as List<dynamic>;
      _cards = cardList.map<LoyaltyCard>((cardJson) => LoyaltyCard.fromJson(cardJson as Map<String, dynamic>)).toList();
      notifyListeners();
    }
  }
}

class SharedPreferences {
  static getInstance() {}
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loyalty Card Storage',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoyaltyCardList(),
    );
  }
}

class LoyaltyCardList extends StatelessWidget {
  const LoyaltyCardList({Key? key});

  @override
  Widget build(BuildContext context) {
    final cardData = Provider.of<LoyaltyCardData>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Cards'),
      ),
      body: cardData.cards.isEmpty
          ? const Center(child: Text('No loyalty cards added yet.'))
          : ListView.builder(
              itemCount: cardData.cards.length,
              itemBuilder: (context, index) {
                final card = cardData.cards[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Image.network(
                          card.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                            return const Icon(Icons.error);
                          },
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(card.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Card Number: ${card.cardNumber}'),
                              if (card.expiryDate != null)
                                Text('Expires: ${card.expiryDate!.toString().split(' ')[0]}'),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () {
                            cardData.removeCard(card);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddLoyaltyCard()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddLoyaltyCard extends StatefulWidget {
  const AddLoyaltyCard({Key? key});

  @override
  _AddLoyaltyCardState createState() => _AddLoyaltyCardState();
}

class _AddLoyaltyCardState extends State<AddLoyaltyCard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _barcodeDataController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _expiryDateController.text = _selectedDate.toString().split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardData = Provider.of<LoyaltyCardData>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Loyalty Card'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Card Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the card name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(labelText: 'Card Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the card number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _barcodeDataController,
                decoration: const InputDecoration(labelText: 'Barcode Data'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the barcode data';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _expiryDateController,
                decoration: const InputDecoration(
                    labelText: 'Expiry Date', hintText: 'YYYY-MM-DD'),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the image URL';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final newCard = LoyaltyCard(
                        name: _nameController.text,
                        cardNumber: _cardNumberController.text,
                        barcodeData: _barcodeDataController.text,
                        expiryDate: _selectedDate,
                        imageUrl: _imageUrlController.text,
                      );
                      cardData.addCard(newCard);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add Card'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cardNumberController.dispose();
    _barcodeDataController.dispose();
    _expiryDateController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
}