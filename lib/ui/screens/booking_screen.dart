import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mershed/core/models/hotel.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/services/booking_service.dart';
import 'package:mershed/ui/widgets/custom_button.dart';
import 'package:provider/provider.dart';


class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _destinationController = TextEditingController();
  List<Hotel> _hotels = [];

  Future<void> _searchHotels() async {
    final hotels = await BookingService().getHotels(_destinationController.text);
    setState(() {
      _hotels = hotels;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MershadAuthProvider>(context); // Updated to MershadAuthProvider

    return Scaffold(
      appBar: AppBar(title: const Text('Book a Hotel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(labelText: 'Destination'),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Search Hotels',
              onPressed: _searchHotels,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _hotels.length,
                itemBuilder: (context, index) {
                  final hotel = _hotels[index];
                  return ListTile(
                    title: Text(hotel.name),
                    subtitle: Text('${hotel.location} - ${hotel.pricePerNight} SAR/night'),
                    trailing: CustomButton(
                      text: 'Book',
                      onPressed: () async {
                        bool success = await BookingService().bookHotel(hotel.id, authProvider.user!.id);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Hotel booked!')),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}