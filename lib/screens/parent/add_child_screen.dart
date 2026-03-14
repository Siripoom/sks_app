import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/models/child.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:uuid/uuid.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedBusId;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _selectedBusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    final appState = context.read<AppStateProvider>();
    final parentProvider = context.read<ParentProvider>();

    final newChild = Child(
      id: const Uuid().v4(),
      name: _nameController.text,
      parentId: appState.currentUser!.referenceId,
      busId: _selectedBusId!,
      homeAddress: _addressController.text,
    );

    parentProvider.addChild(newChild).then((_) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เพิ่มลูกสำเร็จ')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addChild)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: AppStrings.childName),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: AppStrings.homeAddress),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedBusId,
              items: MockData.buses
                  .map(
                    (bus) => DropdownMenuItem(
                      value: bus.id,
                      child: Text(bus.busNumber),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBusId = value;
                });
              },
              decoration: InputDecoration(labelText: AppStrings.selectBus),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSave,
                child: const Text(AppStrings.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
