import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/amende_controller.dart';
import '../models/amende.dart';
import 'qr_scanner_screen.dart';

/// Example screen to display user's fines
class UserAmendesScreen extends StatefulWidget {
  final String userId;

  const UserAmendesScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserAmendesScreen> createState() => _UserAmendesScreenState();
}

class _UserAmendesScreenState extends State<UserAmendesScreen> {
  late AmendeController _amendeController;

  @override
  void initState() {
    super.initState();
    _amendeController = AmendeController();
  }

  Future<Uint8List> _buildQrPngBytes(String data) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: false,
    );
    final image = await painter.toImage(300);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amendes'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Summary section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<int>(
                        future: _amendeController.getAmendesTotalCount(widget.userId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Text('Counting...');
                          return Text('Total fines: ${snapshot.data}');
                        },
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<double>(
                        future: _amendeController.getTotalAmount(widget.userId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Text('Calculating...');
                          return Text('Total amount: ${snapshot.data} DT');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // My Fines section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Text('My Fines', style: Theme.of(context).textTheme.titleMedium),
              ),
              StreamBuilder<List<Amende>>(
                stream: _amendeController.getUserAmendesStream(widget.userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No fines.'),
                    );
                  }

                  final amendes = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    itemCount: amendes.length,
                    itemBuilder: (context, index) {
                      final amende = amendes[index];
                      return _AmendeTile(
                        amende: amende,
                        onEdit: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (ctx) => EditAmendeScreen(amende: amende),
                          ));
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm delete'),
                              content: const Text('Are you sure you want to delete this fine?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await _amendeController.deleteAmende(amende.id);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fine deleted')));
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                            }
                          }
                        },
                        onTap: () {
                          final jsonStr = jsonEncode(amende.toJson());
                          showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(amende.getTypeLabel()),
                              content: FutureBuilder<Uint8List>(
                                future: _buildQrPngBytes(jsonStr),
                                builder: (ctx2, snap) {
                                  if (!snap.hasData) {
                                    return const SizedBox(
                                      height: 320,
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  return SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          color: Colors.white,
                                          child: Image.memory(snap.data!, width: 280, height: 280, fit: BoxFit.contain),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text('Scan to view details', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                        const SizedBox(height: 12),
                                        SelectableText(
                                          jsonStr,
                                          maxLines: 5,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 12),
              const Divider(),

              // Agent's created fines
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Text('Fines I Created', style: Theme.of(context).textTheme.titleMedium),
              ),
              StreamBuilder<List<Amende>>(
                stream: _amendeController.getAgentAmendesStream(widget.userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No fines created yet.'),
                    );
                  }

                  final items = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final amende = items[index];
                      return _AmendeTile(
                        amende: amende,
                        onEdit: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (ctx) => EditAmendeScreen(amende: amende),
                          ));
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm delete'),
                              content: const Text('Are you sure you want to delete this fine?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await _amendeController.deleteAmende(amende.id);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fine deleted')));
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                            }
                          }
                        },
                        onTap: () {
                          final jsonStr = jsonEncode(amende.toJson());
                          showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(amende.getTypeLabel()),
                              content: FutureBuilder<Uint8List>(
                                future: _buildQrPngBytes(jsonStr),
                                builder: (ctx2, snap) {
                                  if (!snap.hasData) {
                                    return const SizedBox(
                                      height: 320,
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  return SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          color: Colors.white,
                                          child: Image.memory(snap.data!, width: 280, height: 280, fit: BoxFit.contain),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text('Scan to view details', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                        const SizedBox(height: 12),
                                        SelectableText(
                                          jsonStr,
                                          maxLines: 5,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'scan_qr',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const QrScannerScreen(),
              ));
            },
            tooltip: 'Scan QR Code',
            backgroundColor: Colors.purple,
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'create_fine',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => CreateAmendeScreen(agentId: widget.userId),
              ));
            },
            tooltip: 'Create Fine',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

/// Individual fine tile widget
class _AmendeTile extends StatelessWidget {
  final Amende amende;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const _AmendeTile({
    required this.amende,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          amende.getTypeLabel(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          amende.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${amende.amount} DT',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit',
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example admin screen to create fines
class CreateAmendeScreen extends StatefulWidget {
  final String agentId;

  const CreateAmendeScreen({
    Key? key,
    required this.agentId,
  }) : super(key: key);

  @override
  State<CreateAmendeScreen> createState() => _CreateAmendeScreenState();
}

class _CreateAmendeScreenState extends State<CreateAmendeScreen> {
  late AmendeController _amendeController;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _userIdController;
  late TextEditingController _locationController;
  late TextEditingController _amountController;
  late TextEditingController _photoUrlController;

  AmendeType _selectedType = AmendeType.speeding;

  @override
  void initState() {
    super.initState();
    _amendeController = AmendeController();
    _userIdController = TextEditingController();
    _locationController = TextEditingController();
    _amountController = TextEditingController();
    _photoUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _locationController.dispose();
    _amountController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Fine'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID or Phone',
                hintText: 'Enter violator\'s user ID',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'User ID is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Where did the violation occur?',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Location is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AmendeType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Violation Type',
              ),
              items: AmendeType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(_getTypeLabel(type)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Fine Amount (DT)',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Amount is required';
                }
                if (double.tryParse(value!) == null) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _photoUrlController,
              decoration: const InputDecoration(
                labelText: 'Photo URL (optional)',
                hintText: 'https://example.com/photo.jpg',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Create Fine'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await _amendeController.createAmende(
          userId: _userIdController.text,
          agentId: widget.agentId,
          location: _locationController.text,
          type: _selectedType,
          amount: double.parse(_amountController.text),
          photoUrl: _photoUrlController.text.isNotEmpty
              ? _photoUrlController.text
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fine created successfully')),
          );
          _userIdController.clear();
          _locationController.clear();
          _amountController.clear();
          _photoUrlController.clear();
          setState(() => _selectedType = AmendeType.speeding);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  String _getTypeLabel(AmendeType type) {
    switch (type) {
      case AmendeType.speeding:
        return 'Speeding';
      case AmendeType.parking:
        return 'Parking Violation';
      case AmendeType.redLight:
        return 'Red Light';
      case AmendeType.seatBelt:
        return 'Seat Belt';
      case AmendeType.phoneUse:
        return 'Phone Use';
      case AmendeType.documentaryOffense:
        return 'Documentary Offense';
      case AmendeType.other:
        return 'Other';
    }
  }
}

/// Screen showing fines created by an agent
class AgentAmendesScreen extends StatefulWidget {
  final String agentId;

  const AgentAmendesScreen({
    Key? key,
    required this.agentId,
  }) : super(key: key);

  @override
  State<AgentAmendesScreen> createState() => _AgentAmendesScreenState();
}

class _AgentAmendesScreenState extends State<AgentAmendesScreen> {
  late AmendeController _amendeController;

  @override
  void initState() {
    super.initState();
    _amendeController = AmendeController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fines I Created'),
      ),
      body: StreamBuilder<List<Amende>>(
        stream: _amendeController.getAgentAmendesStream(widget.agentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.blue[300]),
                  const SizedBox(height: 16),
                  const Text('No fines created yet', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          final amendes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: amendes.length,
            itemBuilder: (context, index) {
              final a = amendes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(a.getTypeLabel()),
                  subtitle: Text(a.location),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${a.amount} DT', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit',
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => EditAmendeScreen(amende: a),
                          ));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm delete'),
                              content: const Text('Are you sure you want to delete this fine?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await _amendeController.deleteAmende(a.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fine deleted')));
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Screen to edit an existing Amende
class EditAmendeScreen extends StatefulWidget {
  final Amende amende;

  const EditAmendeScreen({
    Key? key,
    required this.amende,
  }) : super(key: key);

  @override
  State<EditAmendeScreen> createState() => _EditAmendeScreenState();
}

class _EditAmendeScreenState extends State<EditAmendeScreen> {
  late AmendeController _amendeController;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _userIdController;
  late TextEditingController _locationController;
  late TextEditingController _amountController;
  late TextEditingController _photoUrlController;
  late AmendeType _selectedType;

  @override
  void initState() {
    super.initState();
    _amendeController = AmendeController();
    _userIdController = TextEditingController(text: widget.amende.userId);
    _locationController = TextEditingController(text: widget.amende.location);
    _amountController = TextEditingController(text: widget.amende.amount.toString());
    _photoUrlController = TextEditingController(text: widget.amende.photoUrl ?? '');
    _selectedType = widget.amende.type;
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _locationController.dispose();
    _amountController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Fine')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _userIdController,
              decoration: const InputDecoration(labelText: 'User ID'),
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AmendeType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Violation Type'),
              items: AmendeType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(_getTypeLabelForEdit(t))))
                  .toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedType = v); },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (DT)'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || double.tryParse(v) == null) ? 'Invalid amount' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _photoUrlController,
              decoration: const InputDecoration(labelText: 'Photo URL (optional)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Padding(padding: EdgeInsets.all(12), child: Text('Save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final data = {
      'userId': _userIdController.text,
      'location': _locationController.text,
      'type': _selectedType.toString().split('.').last,
      'amount': double.parse(_amountController.text),
      'photoUrl': _photoUrlController.text.isNotEmpty ? _photoUrlController.text : null,
    };

    try {
      await _amendeController.updateAmende(widget.amende.id, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fine updated')));
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => AgentAmendesScreen(agentId: widget.amende.agentId),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  String _getTypeLabelForEdit(AmendeType type) {
    switch (type) {
      case AmendeType.speeding:
        return 'Speeding';
      case AmendeType.parking:
        return 'Parking Violation';
      case AmendeType.redLight:
        return 'Red Light';
      case AmendeType.seatBelt:
        return 'Seat Belt';
      case AmendeType.phoneUse:
        return 'Phone Use';
      case AmendeType.documentaryOffense:
        return 'Documentary Offense';
      case AmendeType.other:
        return 'Other';
    }
  }
}
