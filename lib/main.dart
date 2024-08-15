import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon Card App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
      routes: {
        '/home': (context) => PokemonListScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/pokemon.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

class PokemonListScreen extends StatefulWidget {
  @override
  _PokemonListScreenState createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  late Future<List<PokemonCard>> futurePokemonCards;

  @override
  void initState() {
    super.initState();
    futurePokemonCards = fetchRandomPokemonCards().then((cards) {
      Future.delayed(Duration(seconds: 2), () {
        final winner = determineWinner(cards[0], cards[1]);
        _showWinnerPopup(winner);
      });
      return cards;
    });
  }

  Future<void> _showWinnerPopup(Winner winner) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          title: Text(
            'Winner!',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                winner.card.largeImageUrl,
                width: 200,
                height: 300,
              ),
              SizedBox(height: 10),
              Text(
                winner.message,
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the popup
                  _loadNewCards(); // Load new cards after closing the popup
                },
                child: Text(
                  'Battle Again',
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black, backgroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadNewCards() async {
    setState(() {
      futurePokemonCards = fetchRandomPokemonCards().then((cards) {
        Future.delayed(Duration(seconds: 2), () {
          final winner = determineWinner(cards[0], cards[1]);
          _showWinnerPopup(winner);
        });
        return cards;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(title: Text('Pokémon Cards Battle')),
      body: FutureBuilder<List<PokemonCard>>(
        future: futurePokemonCards,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final cards = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(20),
                    itemCount: 2,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return Card(
                        color: Colors.black,
                        margin: EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Image.network(
                              card.imageUrl,
                              width: 150, // Adjusted width
                              height: 150, // Adjusted height
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                card.name,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'HP: ${card.hp}',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

// Fetch two random Pokémon cards
Future<List<PokemonCard>> fetchRandomPokemonCards() async {
  final response = await http.get(
    Uri.parse('https://api.pokemontcg.io/v2/cards'),
    headers: {
      'X-Api-Key': '8fd01176-1fbb-4c4b-895e-8022a0101e78',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = json.decode(response.body)['data'];
    final random = Random();
    final card1 = PokemonCard.fromJson(jsonData[random.nextInt(jsonData.length)]);
    final card2 = PokemonCard.fromJson(jsonData[random.nextInt(jsonData.length)]);
    return [card1, card2];
  } else {
    throw Exception('Failed to load Pokémon cards');
  }
}

// Determine the winner based on HP
Winner determineWinner(PokemonCard card1, PokemonCard card2) {
  int hp1 = int.tryParse(card1.hp) ?? 0;
  int hp2 = int.tryParse(card2.hp) ?? 0;

  if (hp1 > hp2) {
    return Winner(message: '${card1.name} wins with ${card1.hp} HP!', card: card1);
  } else if (hp1 < hp2) {
    return Winner(message: '${card2.name} wins with ${card2.hp} HP!', card: card2);
  } else {
    return Winner(message: "It's a tie with both having ${card1.hp} HP!", card: card1);
  }
}

class Winner {
  final String message;
  final PokemonCard card;

  Winner({required this.message, required this.card});
}

class PokemonCard {
  final String name;
  final String imageUrl;
  final String largeImageUrl;
  final String hp;

  PokemonCard({
    required this.name,
    required this.imageUrl,
    required this.largeImageUrl,
    required this.hp,
  });

  factory PokemonCard.fromJson(Map<String, dynamic> json) {
    return PokemonCard(
      name: json['name'],
      imageUrl: json['images']['small'],
      largeImageUrl: json['images']['large'],
      hp: json['hp'] ?? '0',
    );
  }
}
