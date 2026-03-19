import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/school.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/providers/parent_provider.dart';
import 'package:sks/screens/parent/map_picker_screen.dart';
import 'package:sks/services/reference_data_service.dart';
import 'package:sks/widgets/common/app_surface_card.dart';
import 'package:sks/widgets/common/local_image_provider.dart';
import 'package:uuid/uuid.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  late final Future<List<School>> _schoolsFuture;
  String _selectedSchoolId = '';
  PickupLocationResult? _selectedLocation;
  XFile? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _schoolsFuture = context.read<IReferenceDataService>().getSchools();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<PickupLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: _selectedLocation?.lat,
          initialLng: _selectedLocation?.lng,
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedLocation = result);
    }
  }

  Future<void> _pickPhoto() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );

    if (photo == null || !mounted) {
      return;
    }

    setState(() => _selectedPhoto = photo);
  }

  void _removePhoto() {
    setState(() => _selectedPhoto = null);
  }

  bool _hasRequiredFields() {
    return _nameController.text.trim().isNotEmpty &&
        _selectedSchoolId.isNotEmpty &&
        _gradeController.text.trim().isNotEmpty &&
        _emergencyContactNameController.text.trim().isNotEmpty &&
        _emergencyContactPhoneController.text.trim().isNotEmpty &&
        _selectedLocation != null;
  }

  Future<void> _handleSave(List<School> schools) async {
    if (!_hasRequiredFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(AppStrings.requiredCompleteForm))),
      );
      return;
    }

    final emergencyPhone = _emergencyContactPhoneController.text.trim();
    if (emergencyPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(AppStrings.invalidPhone))),
      );
      return;
    }

    final appState = context.read<AppStateProvider>();
    final parentProvider = context.read<ParentProvider>();
    final id = const Uuid().v4();
    final school = schools
        .where((item) => item.id == _selectedSchoolId)
        .firstOrNull;

    final newChild = Child(
      id: id,
      name: _nameController.text.trim(),
      parentId: appState.currentUser!.referenceId,
      tripId: null,
      busId: null,
      schoolId: _selectedSchoolId,
      homeAddress: _selectedLocation!.label,
      pickupLabel: _selectedLocation!.label,
      pickupLat: _selectedLocation!.lat,
      pickupLng: _selectedLocation!.lng,
      qrCodeValue: 'SKS-CHILD-$id',
      photoUrl: '',
      schoolName: school?.name ?? '',
      gradeLevel: _gradeController.text.trim(),
      emergencyContactName: _emergencyContactNameController.text.trim(),
      emergencyContactPhone: emergencyPhone,
      assignmentStatus: ChildAssignmentStatus.pending,
    );

    await parentProvider.addChild(newChild, photo: _selectedPhoto);
    if (!mounted) {
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(AppStrings.childAddedSuccess))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(AppStrings.addChild))),
      body: FutureBuilder<List<School>>(
        future: _schoolsFuture,
        builder: (context, snapshot) {
          final schools = snapshot.data ?? const <School>[];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AppSurfaceCard(
              inner: true,
              borderRadius: BorderRadius.circular(28),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoSection(),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: context.tr(AppStrings.childName),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSchoolId.isEmpty ? null : _selectedSchoolId,
                    decoration: InputDecoration(
                      labelText: context.tr(AppStrings.schoolName),
                    ),
                    items: schools
                        .map(
                          (school) => DropdownMenuItem(
                            value: school.id,
                            child: Text(school.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedSchoolId = value ?? '');
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _gradeController,
                    decoration: InputDecoration(
                      labelText: context.tr(AppStrings.gradeLevel),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emergencyContactNameController,
                    decoration: InputDecoration(
                      labelText: context.tr(AppStrings.emergencyContactName),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emergencyContactPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: context.tr(AppStrings.emergencyContactPhone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr(AppStrings.pickupLocation),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: _pickLocation,
                    child: Ink(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFF2E4DE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_outlined, color: Color(0xFF6B7280)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedLocation?.label ??
                                  context.tr(AppStrings.pickupLocationHint),
                              style: TextStyle(
                                color: _selectedLocation == null
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF111827),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(AppStrings.pendingAssignmentHint),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: snapshot.connectionState == ConnectionState.done
                          ? () => _handleSave(schools)
                          : null,
                      child: Text(context.tr(AppStrings.save)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoSection() {
    final provider = imageProviderFromPath(_selectedPhoto?.path ?? '');

    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      borderRadius: BorderRadius.circular(24),
      color: Colors.white.withValues(alpha: 0.72),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceSoft,
              border: Border.all(color: const Color(0xFFF2E4DE)),
            ),
            clipBehavior: Clip.antiAlias,
            child: provider == null
                ? const Icon(
                    Icons.image_outlined,
                    size: 32,
                    color: AppColors.textSecondary,
                  )
                : Image(
                    image: provider,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      size: 32,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(AppStrings.childPhoto),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(
                    _selectedPhoto == null
                        ? AppStrings.photoHelperEmpty
                        : AppStrings.photoHelperFilled,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        context.tr(
                          _selectedPhoto == null
                              ? AppStrings.selectPhoto
                              : AppStrings.changePhoto,
                        ),
                      ),
                    ),
                    if (_selectedPhoto != null)
                      TextButton.icon(
                        onPressed: _removePhoto,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(context.tr(AppStrings.removePhoto)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
