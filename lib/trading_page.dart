import 'package:flutter/material.dart';

class TradingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(
                              left: 4,
                              right: 16,
                              top: 60,
                              bottom: 30),
          child: Text("Inventory and Cases", textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 22 + 6,
                                      letterSpacing: 1.2,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                    )),
      ),
      backgroundColor: Color.fromARGB(255, 0, 0, 0),
      ),
      body: Column(
        children: [
          // Chest Options
          Container(
            padding: EdgeInsets.symmetric(vertical: 36, horizontal: 8),
            child: Text(
              "Available Chests",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          // Chests Grid
          Expanded(
            flex: 2,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
              itemCount: 4,
              itemBuilder: (context, index) {
                return ChestCard(chestNumber: index);
              },
            ),
          ),
          // Chat Room Section
        ],
      ),
    );
  }
}

class ChestCard extends StatelessWidget {
  final int chestNumber;

  ChestCard({required this.chestNumber});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      child: InkWell(
        onTap: () {
          // Handle chest purchase
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/Pixel_Chest_Pack/chest_$chestNumber.png', // Use the chest image based on chest number
              height: 100,
              width: 100,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 8),
            Text(
              "Chest $chestNumber",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              "Buy Now",
              style: TextStyle(color: Colors.greenAccent, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
