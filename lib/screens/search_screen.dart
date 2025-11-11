import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'announcement_list_screen.dart'; 

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _originCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  DateTime _departureDateTime = DateTime.now();
  int _seats = 1;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departureDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departureDateTime),
    );
    setState(() {
      _departureDateTime = time == null
          ? date
          : DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Besoin de covoiturage?')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('où vas-tu?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _inputField('Origine', _originCtrl, CupertinoIcons.location),
            const SizedBox(height: 16),
            _inputField('Destination', _destinationCtrl, CupertinoIcons.location_fill),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(CupertinoIcons.calendar),
              title: const Text('Quand?'),
              subtitle: Text(
                  '${_departureDateTime.day}/${_departureDateTime.month}/${_departureDateTime.year}  ${_departureDateTime.hour}:${_departureDateTime.minute.toString().padLeft(2, '0')}'),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(CupertinoIcons.person_2_fill),
                const SizedBox(width: 12),
                const Text('Nombre de sièges nécessaires?'),
                const Spacer(),
                DropdownButton<int>(
                  value: _seats,
                  items: List.generate(8, (i) => i + 1)
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                      .toList(),
                  onChanged: (v) => setState(() => _seats = v!),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AnnouncementListScreen(
                            isPassenger: true,
                            origin: _originCtrl.text.trim(),
                            destination: _destinationCtrl.text.trim(),
                            departureDateTime: _departureDateTime,
                            seats: _seats,
                            from: _originCtrl.text.trim(),
                            to: _destinationCtrl.text.trim(),
                            when: _departureDateTime,
                          ))),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Rechercher', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String hint, TextEditingController ctrl, IconData icon) =>
      TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}