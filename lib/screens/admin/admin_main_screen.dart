import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sks/core/constants/app_colors.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/core/localization/app_localizations.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/driver.dart';
import 'package:sks/models/parent.dart';
import 'package:sks/models/school.dart';
import 'package:sks/models/teacher.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/providers/admin_provider.dart';
import 'package:sks/providers/app_state_provider.dart';
import 'package:sks/screens/login/login_screen.dart';
import 'package:sks/screens/parent/map_picker_screen.dart';
import 'package:sks/services/admin_service.dart';
import 'package:sks/widgets/common/app_surface_card.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late final Future<void> _bootstrapFuture;
  AdminEntityType _peopleType = AdminEntityType.parent;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = context.read<AdminProvider>().bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final adminName =
        context.watch<AppStateProvider>().currentUser?.name ??
        context.tr(AppStrings.roleAdmin);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr(AppStrings.adminWorkspace)),
          actions: [
            IconButton(
              onPressed: () async {
                await context.read<AppStateProvider>().logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Schools'),
              Tab(text: 'People'),
              Tab(text: 'Students'),
              Tab(text: 'Fleet'),
              Tab(text: 'Trips'),
            ],
          ),
        ),
        body: FutureBuilder<void>(
          future: _bootstrapFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: AppSurfaceCard(
                    inner: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(adminName, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: provider.selectedSchoolId.isEmpty
                                    ? null
                                    : provider.selectedSchoolId,
                                decoration: const InputDecoration(
                                  labelText: 'Selected school',
                                ),
                                items: provider.schools
                                    .where((school) => !_showArchived || school.isArchived)
                                    .map((school) => DropdownMenuItem(value: school.id, child: Text(school.name)))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) provider.selectSchool(value);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilterChip(
                              label: const Text('Show archived'),
                              selected: _showArchived,
                              onSelected: (value) => setState(() => _showArchived = value),
                            ),
                          ],
                        ),
                        if (provider.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSchoolsTab(provider),
                      _buildPeopleTab(provider),
                      _buildStudentsTab(provider),
                      _buildFleetTab(provider),
                      _buildTripsTab(provider),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSchoolsTab(AdminProvider provider) {
    final schools = provider.schools
        .where((school) => _showArchived || !school.isArchived)
        .toList();
    return _buildEntityList<School>(
      title: 'Schools',
      items: schools,
      onCreate: () => _showSchoolSheet(),
      itemBuilder: (school) => _card(
        context,
        school.name,
        '${school.address}\n${school.lat.toStringAsFixed(4)}, ${school.lng.toStringAsFixed(4)}',
        school.isArchived,
        () => _showSchoolSheet(existing: school),
        () => _toggleSchoolArchive(school),
      ),
    );
  }

  Widget _buildPeopleTab(AdminProvider provider) {
    final List<Object> items = switch (_peopleType) {
      AdminEntityType.parent => provider.visibleParents.where((item) => _showArchived || !item.isArchived).cast<Object>().toList(),
      AdminEntityType.teacher => provider.visibleTeachers.where((item) => _showArchived || !item.isArchived).cast<Object>().toList(),
      AdminEntityType.driver => provider.drivers.where((item) => _showArchived || !item.isArchived).cast<Object>().toList(),
      _ => <Object>[],
    };
    return Column(
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(label: const Text('Parents'), selected: _peopleType == AdminEntityType.parent, onSelected: (_) => setState(() => _peopleType = AdminEntityType.parent)),
            ChoiceChip(label: const Text('Teachers'), selected: _peopleType == AdminEntityType.teacher, onSelected: (_) => setState(() => _peopleType = AdminEntityType.teacher)),
            ChoiceChip(label: const Text('Drivers'), selected: _peopleType == AdminEntityType.driver, onSelected: (_) => setState(() => _peopleType = AdminEntityType.driver)),
          ],
        ),
        Expanded(
          child: _buildEntityList<Object>(
            title: 'People',
            items: items,
            onCreate: () => _showUserSheet(_peopleType),
            itemBuilder: (item) {
              if (item is Parent) {
                return _card(
                  context,
                  item.name,
                  '${item.phone}\nSchools: ${item.schoolIds.join(', ')}',
                  item.isArchived,
                  () => _showUserSheet(_peopleType, existing: item),
                  () => _togglePersonArchive(item),
                );
              }
              if (item is Teacher) {
                return _card(
                  context,
                  item.name,
                  'School: ${provider.schoolById(item.schoolId)?.name ?? item.schoolId}',
                  item.isArchived,
                  () => _showUserSheet(_peopleType, existing: item),
                  () => _togglePersonArchive(item),
                );
              }
              final driver = item as Driver;
              final bus = provider.busById(driver.busId);
              return _card(
                context,
                driver.name,
                '${driver.phone}\n${driver.licenseNumber}\n${bus?.busNumber ?? 'No bus'}',
                driver.isArchived,
                () => _showUserSheet(_peopleType, existing: driver),
                () => _togglePersonArchive(driver),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsTab(AdminProvider provider) {
    final children = provider.visibleChildren
        .where((child) => _showArchived || !child.isArchived)
        .toList();
    return _buildEntityList<Child>(
      title: 'Students',
      items: children,
      onCreate: () => _showChildSheet(),
      itemBuilder: (child) {
        final trip = provider.tripById(child.tripId);
        return _card(
          context,
          child.name,
          '${provider.schoolById(child.schoolId)?.name ?? child.schoolId}\n${child.pickupLabel}\nTrip: ${trip?.id ?? 'Not assigned'}',
          child.isArchived,
          () => _showChildSheet(existing: child),
          () => _toggleChildArchive(child),
          extra: child.tripId == null
              ? null
              : TextButton(
                  onPressed: () => _removeFromTrip(child),
                  child: const Text('Remove from trip'),
                ),
        );
      },
    );
  }

  Widget _buildFleetTab(AdminProvider provider) {
    final buses = provider.buses.where((bus) => _showArchived || !bus.isArchived).toList();
    return _buildEntityList<Bus>(
      title: 'Fleet',
      items: buses,
      onCreate: () => _showBusSheet(),
      itemBuilder: (bus) {
        final driver = provider.drivers.where((item) => item.id == bus.driverId).firstOrNull;
        return _card(
          context,
          bus.busNumber,
          '${bus.licensePlate}\nDriver: ${driver?.name ?? 'No driver'}',
          bus.isArchived,
          () => _showBusSheet(existing: bus),
          () => _toggleBusArchive(bus),
        );
      },
    );
  }

  Widget _buildTripsTab(AdminProvider provider) {
    final trips = provider.visibleTrips.where((trip) => _showArchived || !trip.isArchived).toList();
    return _buildEntityList<Trip>(
      title: 'Trips',
      items: trips,
      onCreate: () => _showTripSheet(),
      itemBuilder: (trip) {
        final school = provider.schoolById(trip.schoolId);
        final bus = provider.busById(trip.busId);
        final children = provider.children
            .where((child) => trip.childIds.contains(child.id))
            .map((child) => child.name)
            .join(', ');
        return _card(
          context,
          '${school?.name ?? trip.schoolId} • ${bus?.busNumber ?? trip.busId}',
          '${trip.round.value} • ${trip.serviceDate.toIso8601String().split('T').first}\n${children.isEmpty ? 'No students' : children}',
          trip.isArchived,
          () => _showTripSheet(existing: trip),
          () => _toggleTripArchive(trip),
        );
      },
    );
  }

  Widget _buildEntityList<T>({
    required String title,
    required List<T> items,
    required VoidCallback onCreate,
    required Widget Function(T item) itemBuilder,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: items.map(itemBuilder).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _showSchoolSheet({School? existing}) async {
    final provider = context.read<AdminProvider>();
    final name = TextEditingController(text: existing?.name ?? '');
    final address = TextEditingController(text: existing?.address ?? '');
    final morningPickup = TextEditingController(text: existing?.morningPickup ?? '');
    final morningDropoff = TextEditingController(text: existing?.morningDropoff ?? '');
    final eveningPickup = TextEditingController(text: existing?.eveningPickup ?? '');
    final eveningDropoff = TextEditingController(text: existing?.eveningDropoff ?? '');
    PickupLocationResult? location = existing == null
        ? null
        : PickupLocationResult(lat: existing.lat, lng: existing.lng, label: existing.address);
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Create school' : 'Edit school'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
                OutlinedButton.icon(
                  onPressed: saving ? null : () async {
                    final picked = await Navigator.push<PickupLocationResult>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPickerScreen(
                          initialLat: location?.lat,
                          initialLng: location?.lng,
                        ),
                      ),
                    );
                    if (picked != null) {
                      setModalState(() {
                        location = picked;
                        if (address.text.trim().isEmpty) address.text = picked.label;
                      });
                    }
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: Text(location == null ? 'Pick location' : '${location!.lat.toStringAsFixed(4)}, ${location!.lng.toStringAsFixed(4)}'),
                ),
                TextField(controller: morningPickup, decoration: const InputDecoration(labelText: 'Morning pickup')),
                TextField(controller: morningDropoff, decoration: const InputDecoration(labelText: 'Morning dropoff')),
                TextField(controller: eveningPickup, decoration: const InputDecoration(labelText: 'Evening pickup')),
                TextField(controller: eveningDropoff, decoration: const InputDecoration(labelText: 'Evening dropoff')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: Text(context.tr(AppStrings.cancel))),
            ElevatedButton(
              onPressed: location == null || saving
                  ? null
                  : () async {
                      setModalState(() => saving = true);
                      final ok = await provider.saveSchool(
                        AdminSchoolInput(
                          id: existing?.id,
                          name: name.text.trim(),
                          address: address.text.trim(),
                          lat: location!.lat,
                          lng: location!.lng,
                          morningPickup: morningPickup.text.trim(),
                          morningDropoff: morningDropoff.text.trim(),
                          eveningPickup: eveningPickup.text.trim(),
                          eveningDropoff: eveningDropoff.text.trim(),
                        ),
                      );
                      if (!mounted) return;
                      if (ok && dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      } else if (dialogContext.mounted) {
                        setModalState(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(existing == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUserSheet(AdminEntityType type, {Object? existing}) async {
    final provider = context.read<AdminProvider>();
    final name = TextEditingController(
      text: existing is Parent
          ? existing.name
          : existing is Teacher
          ? existing.name
          : existing is Driver
          ? existing.name
          : '',
    );
    final phone = TextEditingController(
      text: existing is Parent ? existing.phone : existing is Driver ? existing.phone : '',
    );
    final email = TextEditingController();
    final password = TextEditingController();
    final license = TextEditingController(text: existing is Driver ? existing.licenseNumber : '');
    String selectedBusId = existing is Driver ? existing.busId : '';
    String selectedSchoolId = existing is Teacher ? existing.schoolId : provider.selectedSchoolId;
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Create ${type.value}' : 'Edit ${type.value}'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                if (existing == null) TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                if (type == AdminEntityType.parent || type == AdminEntityType.driver)
                  TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
                if (type == AdminEntityType.teacher)
                  DropdownButtonFormField<String>(
                    value: selectedSchoolId.isEmpty ? null : selectedSchoolId,
                    decoration: const InputDecoration(labelText: 'School'),
                    items: provider.schools.where((school) => !school.isArchived).map((school) => DropdownMenuItem(value: school.id, child: Text(school.name))).toList(),
                    onChanged: saving ? null : (value) => setModalState(() => selectedSchoolId = value ?? ''),
                  ),
                if (type == AdminEntityType.driver)
                  TextField(controller: license, decoration: const InputDecoration(labelText: 'License number')),
                if (type == AdminEntityType.driver)
                  DropdownButtonFormField<String>(
                    value: selectedBusId.isEmpty ? null : selectedBusId,
                    decoration: const InputDecoration(labelText: 'Assigned bus'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('No bus')),
                      ...provider.buses.where((bus) => !bus.isArchived).map((bus) => DropdownMenuItem(value: bus.id, child: Text(bus.busNumber))),
                    ],
                    onChanged: saving ? null : (value) => setModalState(() => selectedBusId = value ?? ''),
                  ),
                TextField(
                  controller: password,
                  decoration: InputDecoration(labelText: existing == null ? 'Initial password' : 'New password (optional)'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: Text(context.tr(AppStrings.cancel))),
            ElevatedButton(
              onPressed: saving ? null : () async {
                setModalState(() => saving = true);
                final input = AdminManagedUserInput(
                  type: type,
                  referenceId: existing is Parent ? existing.id : existing is Teacher ? existing.id : existing is Driver ? existing.id : null,
                  name: name.text.trim(),
                  email: email.text.trim(),
                  phone: phone.text.trim(),
                  licenseNumber: license.text.trim(),
                  password: password.text.trim().isEmpty ? null : password.text.trim(),
                  busId: selectedBusId,
                  schoolId: selectedSchoolId,
                );
                final ok = existing == null
                    ? await provider.createManagedUser(input)
                    : await provider.updateManagedUser(input);
                if (!mounted) return;
                if (ok && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                } else if (dialogContext.mounted) {
                  setModalState(() => saving = false);
                }
              },
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(existing == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChildSheet({Child? existing}) async {
    final provider = context.read<AdminProvider>();
    final name = TextEditingController(text: existing?.name ?? '');
    final grade = TextEditingController(text: existing?.gradeLevel ?? '');
    final emergencyName = TextEditingController(text: existing?.emergencyContactName ?? '');
    final emergencyPhone = TextEditingController(text: existing?.emergencyContactPhone ?? '');
    String selectedParentId = existing?.parentId ?? provider.parents.firstOrNull?.id ?? '';
    String selectedSchoolId = existing?.schoolId ?? provider.selectedSchoolId;
    PickupLocationResult? location = existing == null
        ? null
        : PickupLocationResult(
            lat: existing.pickupLat ?? 13.7563,
            lng: existing.pickupLng ?? 100.5018,
            label: existing.pickupLabel,
          );
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Create student' : 'Edit student'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedParentId.isEmpty ? null : selectedParentId,
                  decoration: const InputDecoration(labelText: 'Parent'),
                  items: provider.parents.where((parent) => !parent.isArchived).map((parent) => DropdownMenuItem(value: parent.id, child: Text(parent.name))).toList(),
                  onChanged: saving ? null : (value) => setModalState(() => selectedParentId = value ?? ''),
                ),
                DropdownButtonFormField<String>(
                  value: selectedSchoolId.isEmpty ? null : selectedSchoolId,
                  decoration: const InputDecoration(labelText: 'School'),
                  items: provider.schools.where((school) => !school.isArchived).map((school) => DropdownMenuItem(value: school.id, child: Text(school.name))).toList(),
                  onChanged: saving ? null : (value) => setModalState(() => selectedSchoolId = value ?? ''),
                ),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: grade, decoration: const InputDecoration(labelText: 'Grade')),
                TextField(controller: emergencyName, decoration: const InputDecoration(labelText: 'Emergency contact')),
                TextField(controller: emergencyPhone, decoration: const InputDecoration(labelText: 'Emergency phone')),
                OutlinedButton.icon(
                  onPressed: saving ? null : () async {
                    final picked = await Navigator.push<PickupLocationResult>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPickerScreen(
                          initialLat: location?.lat,
                          initialLng: location?.lng,
                        ),
                      ),
                    );
                    if (picked != null) setModalState(() => location = picked);
                  },
                  icon: const Icon(Icons.pin_drop_outlined),
                  label: Text(location?.label ?? 'Choose pickup location'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: Text(context.tr(AppStrings.cancel))),
            ElevatedButton(
              onPressed: location == null || saving
                  ? null
                  : () async {
                      setModalState(() => saving = true);
                      final school = provider.schoolById(selectedSchoolId);
                      final ok = await provider.saveChild(
                        AdminChildInput(
                          id: existing?.id,
                          name: name.text.trim(),
                          parentId: selectedParentId,
                          schoolId: selectedSchoolId,
                          homeAddress: location!.label,
                          pickupLabel: location!.label,
                          pickupLat: location!.lat,
                          pickupLng: location!.lng,
                          schoolName: school?.name ?? '',
                          gradeLevel: grade.text.trim(),
                          emergencyContactName: emergencyName.text.trim(),
                          emergencyContactPhone: emergencyPhone.text.trim(),
                          photoUrl: existing?.photoUrl ?? '',
                        ),
                      );
                      if (!mounted) return;
                      if (ok && dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      } else if (dialogContext.mounted) {
                        setModalState(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(existing == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBusSheet({Bus? existing}) async {
    final provider = context.read<AdminProvider>();
    final busNumber = TextEditingController(text: existing?.busNumber ?? '');
    final plate = TextEditingController(text: existing?.licensePlate ?? '');
    String selectedDriverId = existing?.driverId ?? '';
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Create bus' : 'Edit bus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: busNumber, decoration: const InputDecoration(labelText: 'Bus number')),
              TextField(controller: plate, decoration: const InputDecoration(labelText: 'License plate')),
              DropdownButtonFormField<String>(
                value: selectedDriverId.isEmpty ? null : selectedDriverId,
                decoration: const InputDecoration(labelText: 'Driver'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('No driver')),
                  ...provider.drivers.where((driver) => !driver.isArchived).map((driver) => DropdownMenuItem(value: driver.id, child: Text(driver.name))),
                ],
                onChanged: saving ? null : (value) => setModalState(() => selectedDriverId = value ?? ''),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: Text(context.tr(AppStrings.cancel))),
            ElevatedButton(
              onPressed: saving ? null : () async {
                setModalState(() => saving = true);
                final ok = await provider.saveBus(
                  AdminBusInput(
                    id: existing?.id,
                    busNumber: busNumber.text.trim(),
                    licensePlate: plate.text.trim(),
                    driverId: selectedDriverId,
                    schoolId: existing?.schoolId ?? '',
                    currentLat: existing?.currentLat ?? 0,
                    currentLng: existing?.currentLng ?? 0,
                  ),
                );
                if (!mounted) return;
                if (ok && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                } else if (dialogContext.mounted) {
                  setModalState(() => saving = false);
                }
              },
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(existing == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTripSheet({Trip? existing}) async {
    final provider = context.read<AdminProvider>();
    final isActive = existing?.status == TripStatus.active;
    String selectedSchoolId = existing?.schoolId ?? provider.selectedSchoolId;
    String selectedBusId = existing?.busId ?? provider.buses.firstOrNull?.id ?? '';
    TripRound round = existing?.round ?? TripRound.toSchool;
    DateTime serviceDate = existing?.serviceDate ?? DateTime.now();
    TimeOfDay selectedTime = existing?.scheduledStartAt == null
        ? TimeOfDay.now()
        : TimeOfDay.fromDateTime(existing!.scheduledStartAt!);
    final selectedChildIds = <String>{...?existing?.childIds};
    // Ordered list for stop sequence (preserves existing stop order if available)
    final orderedChildIds = <String>[
      if (existing?.stops.isNotEmpty == true)
        ...existing!.stops.map((s) => s.childId)
      else
        ...?existing?.childIds,
    ];
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final students = provider.children.where((child) => !child.isArchived && child.schoolId == selectedSchoolId).toList();
          final studentsById = {for (final c in students) c.id: c};

          // Keep orderedChildIds in sync with selectedChildIds
          void syncOrder() {
            orderedChildIds.removeWhere((id) => !selectedChildIds.contains(id));
            for (final id in selectedChildIds) {
              if (!orderedChildIds.contains(id)) orderedChildIds.add(id);
            }
          }

          syncOrder();

          return AlertDialog(
            title: Text(existing == null ? 'Create trip' : 'Edit trip'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isActive)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.statusAmber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Trip is active — cannot edit students or order.',
                          style: TextStyle(color: AppColors.statusAmber),
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      value: selectedSchoolId.isEmpty ? null : selectedSchoolId,
                      decoration: const InputDecoration(labelText: 'School'),
                      items: provider.schools.where((school) => !school.isArchived).map((school) => DropdownMenuItem(value: school.id, child: Text(school.name))).toList(),
                      onChanged: (saving || isActive) ? null : (value) {
                        setModalState(() {
                          selectedSchoolId = value ?? '';
                          selectedChildIds.clear();
                          orderedChildIds.clear();
                        });
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedBusId.isEmpty ? null : selectedBusId,
                      decoration: const InputDecoration(labelText: 'Bus'),
                      items: provider.buses.where((bus) => !bus.isArchived).map((bus) => DropdownMenuItem(value: bus.id, child: Text(bus.busNumber))).toList(),
                      onChanged: (saving || isActive) ? null : (value) => setModalState(() => selectedBusId = value ?? ''),
                    ),
                    DropdownButtonFormField<TripRound>(
                      value: round,
                      decoration: const InputDecoration(labelText: 'Round'),
                      items: const [
                        DropdownMenuItem(value: TripRound.toSchool, child: Text('To school')),
                        DropdownMenuItem(value: TripRound.toHome, child: Text('To home')),
                      ],
                      onChanged: (saving || isActive) ? null : (value) => setModalState(() => round = value ?? TripRound.toSchool),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Date: ${serviceDate.toIso8601String().split('T').first}'),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: saving ? null : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: serviceDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setModalState(() => serviceDate = picked);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Start time: ${selectedTime.format(context)}'),
                      trailing: const Icon(Icons.schedule_outlined),
                      onTap: saving ? null : () async {
                        final picked = await showTimePicker(context: context, initialTime: selectedTime);
                        if (picked != null) setModalState(() => selectedTime = picked);
                      },
                    ),
                    if (!isActive)
                      ...students.map(
                        (child) => CheckboxListTile(
                          dense: true,
                          value: selectedChildIds.contains(child.id),
                          title: Text(child.name),
                          subtitle: Text(child.pickupLabel),
                          onChanged: saving ? null : (value) {
                            setModalState(() {
                              if (value == true) {
                                selectedChildIds.add(child.id);
                              } else {
                                selectedChildIds.remove(child.id);
                              }
                              syncOrder();
                            });
                          },
                        ),
                      ),
                    // Reorderable pickup order
                    if (orderedChildIds.isNotEmpty && !isActive) ...[
                      const SizedBox(height: 16),
                      Text(
                        'จัดลำดับจุดรับ (ลากเพื่อจัดลำดับ)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: orderedChildIds.length * 56.0,
                        child: ReorderableListView.builder(
                          shrinkWrap: true,
                          itemCount: orderedChildIds.length,
                          onReorder: (oldIndex, newIndex) {
                            setModalState(() {
                              if (newIndex > oldIndex) newIndex--;
                              final item = orderedChildIds.removeAt(oldIndex);
                              orderedChildIds.insert(newIndex, item);
                            });
                          },
                          itemBuilder: (context, index) {
                            final childId = orderedChildIds[index];
                            final child = studentsById[childId];
                            return ListTile(
                              key: ValueKey(childId),
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              title: Text(child?.name ?? childId),
                              subtitle: Text(child?.pickupLabel ?? ''),
                              trailing: const Icon(Icons.drag_handle),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: Text(context.tr(AppStrings.cancel))),
              ElevatedButton(
                onPressed: saving ? null : () async {
                  setModalState(() => saving = true);
                  final scheduledStartAt = DateTime(
                    serviceDate.year,
                    serviceDate.month,
                    serviceDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  // Build stops from ordered list
                  final stops = <Map<String, dynamic>>[];
                  for (var i = 0; i < orderedChildIds.length; i++) {
                    final child = studentsById[orderedChildIds[i]];
                    if (child == null) continue;
                    stops.add({
                      'childId': child.id,
                      'sequence': i,
                      'lat': child.pickupLat ?? 0,
                      'lng': child.pickupLng ?? 0,
                      'pickupLabel': child.pickupLabel,
                      'childName': child.name,
                      'status': 'pending',
                      'arrivedAt': null,
                      'pickedUpAt': null,
                    });
                  }
                  final ok = await provider.saveTrip(
                    AdminTripInput(
                      id: existing?.id,
                      schoolId: selectedSchoolId,
                      busId: selectedBusId,
                      serviceDate: serviceDate,
                      round: round,
                      scheduledStartAt: scheduledStartAt,
                      childIds: orderedChildIds.toList(),
                      stops: stops,
                    ),
                  );
                  if (!mounted) return;
                  if (ok && dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  } else if (dialogContext.mounted) {
                    setModalState(() => saving = false);
                  }
                },
                child: saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(existing == null ? 'Create' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleSchoolArchive(School school) async {
    await context.read<AdminProvider>().setSchoolArchived(school.id, !school.isArchived);
  }

  Future<void> _togglePersonArchive(Object item) async {
    final provider = context.read<AdminProvider>();
    final type = item is Parent ? AdminEntityType.parent : item is Teacher ? AdminEntityType.teacher : AdminEntityType.driver;
    final id = item is Parent ? item.id : item is Teacher ? item.id : (item as Driver).id;
    final archived = item is Parent ? item.isArchived : item is Teacher ? item.isArchived : (item as Driver).isArchived;
    await provider.setManagedUserArchived(type: type, referenceId: id, archived: !archived);
  }

  Future<void> _toggleChildArchive(Child child) async {
    await context.read<AdminProvider>().setChildArchived(child.id, !child.isArchived);
  }

  Future<void> _toggleBusArchive(Bus bus) async {
    await context.read<AdminProvider>().setBusArchived(bus.id, !bus.isArchived);
  }

  Future<void> _toggleTripArchive(Trip trip) async {
    await context.read<AdminProvider>().setTripArchived(trip.id, !trip.isArchived);
  }

  Future<void> _removeFromTrip(Child child) async {
    await context.read<AdminProvider>().removeChildFromTrip(child.id);
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

Widget _card(
  BuildContext context,
  String title,
  String subtitle,
  bool archived,
  VoidCallback onEdit,
  VoidCallback onArchive, {
  Widget? extra,
}) {
  return AppSurfaceCard(
    inner: true,
    margin: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(subtitle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
            TextButton(onPressed: onArchive, child: Text(archived ? 'Restore' : 'Archive')),
            if (extra != null) extra,
          ],
        ),
      ],
    ),
  );
}
