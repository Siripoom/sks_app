import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
import 'package:sks/widgets/common/account_deletion_tile.dart';

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
              tooltip: 'Account settings',
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text(context.tr(AppStrings.accountSettings)),
                        ),
                        const AccountDeletionTile(),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.manage_accounts_outlined),
            ),
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
                        Text(
                          adminName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
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
                                    .where(
                                      (school) =>
                                          !_showArchived || school.isArchived,
                                    )
                                    .map(
                                      (school) => DropdownMenuItem(
                                        value: school.id,
                                        child: Text(school.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    provider.selectSchool(value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilterChip(
                              label: const Text('Show archived'),
                              selected: _showArchived,
                              onSelected: (value) =>
                                  setState(() => _showArchived = value),
                            ),
                          ],
                        ),
                        if (provider.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            provider.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
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
      itemBuilder: (school) {
        final used = provider.activeBusCountForSchool(school.id);
        final remaining = school.busLimit == null
            ? null
            : school.busLimit! - used;
        final capacity = school.busLimit == null
            ? '$used buses • Not set (unlimited)'
            : remaining! >= 0
            ? '$used / ${school.busLimit} buses • $remaining slots left'
            : '$used / ${school.busLimit} buses • ${-remaining} over limit';
        return _card(
          context,
          school.name,
          '${school.address}\n${school.lat.toStringAsFixed(4)}, ${school.lng.toStringAsFixed(4)}\n$capacity',
          school.isArchived,
          () => _showSchoolSheet(existing: school),
          () => _toggleSchoolArchive(school),
        );
      },
    );
  }

  Widget _buildPeopleTab(AdminProvider provider) {
    final List<Object> items = switch (_peopleType) {
      AdminEntityType.parent =>
        provider.visibleParents
            .where((item) => _showArchived || !item.isArchived)
            .cast<Object>()
            .toList(),
      AdminEntityType.teacher =>
        provider.visibleTeachers
            .where((item) => _showArchived || !item.isArchived)
            .cast<Object>()
            .toList(),
      AdminEntityType.driver =>
        provider.drivers
            .where((item) => _showArchived || !item.isArchived)
            .cast<Object>()
            .toList(),
      _ => <Object>[],
    };
    return Column(
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Parents'),
              selected: _peopleType == AdminEntityType.parent,
              onSelected: (_) =>
                  setState(() => _peopleType = AdminEntityType.parent),
            ),
            ChoiceChip(
              label: const Text('Teachers'),
              selected: _peopleType == AdminEntityType.teacher,
              onSelected: (_) =>
                  setState(() => _peopleType = AdminEntityType.teacher),
            ),
            ChoiceChip(
              label: const Text('Drivers'),
              selected: _peopleType == AdminEntityType.driver,
              onSelected: (_) =>
                  setState(() => _peopleType = AdminEntityType.driver),
            ),
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
    final buses = provider.buses
        .where((bus) => _showArchived || !bus.isArchived)
        .toList();
    return _buildEntityList<Bus>(
      title: 'Fleet',
      items: buses,
      onCreate: () => _showBusSheet(),
      itemBuilder: (bus) {
        final driver = provider.drivers
            .where((item) => item.id == bus.driverId)
            .firstOrNull;
        final school = provider.schoolById(bus.schoolId);
        return _card(
          context,
          bus.busNumber,
          '${bus.licensePlate}\nSchool: ${school?.name ?? 'No school'}\nDriver: ${driver?.name ?? 'No driver'}',
          bus.isArchived,
          () => _showBusSheet(existing: bus),
          () => _toggleBusArchive(bus),
        );
      },
    );
  }

  Widget _buildTripsTab(AdminProvider provider) {
    final trips = provider.visibleTrips
        .where((trip) => _showArchived || !trip.isArchived)
        .toList();
    return _buildEntityList<Trip>(
      title: 'Trips',
      items: trips,
      onCreate: () => _showTripSheet(),
      itemBuilder: (trip) {
        final schoolNames = trip.effectiveSchoolIds
            .map((id) => provider.schoolById(id)?.name ?? id)
            .join(', ');
        final bus = provider.busById(trip.busId);
        final children = provider.children
            .where((child) => trip.childIds.contains(child.id))
            .map((child) => child.name)
            .join(', ');
        return _card(
          context,
          '${schoolNames.isEmpty ? 'No school' : schoolNames} • ${bus?.busNumber ?? trip.busId}',
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
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
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
    final morningPickup = TextEditingController(
      text: existing?.morningPickup ?? '',
    );
    final morningDropoff = TextEditingController(
      text: existing?.morningDropoff ?? '',
    );
    final eveningPickup = TextEditingController(
      text: existing?.eveningPickup ?? '',
    );
    final eveningDropoff = TextEditingController(
      text: existing?.eveningDropoff ?? '',
    );
    final busLimit = TextEditingController(
      text: existing?.busLimit?.toString() ?? '',
    );
    String? busLimitError;
    PickupLocationResult? location = existing == null
        ? null
        : PickupLocationResult(
            lat: existing.lat,
            lng: existing.lng,
            label: existing.address,
          );
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Create school' : 'Edit school'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: address,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: busLimit,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Bus limit',
                    helperText:
                        '${provider.activeBusCountForSchool(existing?.id ?? '')} active buses currently',
                    errorText: busLimitError,
                  ),
                  onChanged: (_) {
                    if (busLimitError != null) {
                      setModalState(() => busLimitError = null);
                    }
                  },
                ),
                OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          final picked =
                              await Navigator.push<PickupLocationResult>(
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
                              if (address.text.trim().isEmpty) {
                                address.text = picked.label;
                              }
                            });
                          }
                        },
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    location == null
                        ? 'Pick location'
                        : '${location!.lat.toStringAsFixed(4)}, ${location!.lng.toStringAsFixed(4)}',
                  ),
                ),
                TextField(
                  controller: morningPickup,
                  decoration: const InputDecoration(
                    labelText: 'Morning pickup',
                  ),
                ),
                TextField(
                  controller: morningDropoff,
                  decoration: const InputDecoration(
                    labelText: 'Morning dropoff',
                  ),
                ),
                TextField(
                  controller: eveningPickup,
                  decoration: const InputDecoration(
                    labelText: 'Evening pickup',
                  ),
                ),
                TextField(
                  controller: eveningDropoff,
                  decoration: const InputDecoration(
                    labelText: 'Evening dropoff',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: Text(context.tr(AppStrings.cancel)),
            ),
            ElevatedButton(
              onPressed: location == null || saving
                  ? null
                  : () async {
                      final parsedBusLimit = int.tryParse(busLimit.text.trim());
                      final activeBusCount = provider.activeBusCountForSchool(
                        existing?.id ?? '',
                      );
                      if (parsedBusLimit == null ||
                          parsedBusLimit < activeBusCount) {
                        setModalState(() {
                          busLimitError = parsedBusLimit == null
                              ? 'Enter a non-negative whole number.'
                              : 'Limit cannot be lower than $activeBusCount active buses.';
                        });
                        return;
                      }
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
                          busLimit: parsedBusLimit,
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
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
      text: existing is Parent
          ? existing.phone
          : existing is Driver
          ? existing.phone
          : '',
    );
    final email = TextEditingController();
    final password = TextEditingController();
    final license = TextEditingController(
      text: existing is Driver ? existing.licenseNumber : '',
    );
    String selectedBusId = existing is Driver ? existing.busId : '';
    String selectedSchoolId = existing is Teacher
        ? existing.schoolId
        : provider.selectedSchoolId;
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(
            existing == null ? 'Create ${type.value}' : 'Edit ${type.value}',
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                if (existing == null)
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                if (type == AdminEntityType.parent ||
                    type == AdminEntityType.driver)
                  TextField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                if (type == AdminEntityType.teacher)
                  DropdownButtonFormField<String>(
                    value: selectedSchoolId.isEmpty ? null : selectedSchoolId,
                    decoration: const InputDecoration(labelText: 'School'),
                    items: provider.schools
                        .where((school) => !school.isArchived)
                        .map(
                          (school) => DropdownMenuItem(
                            value: school.id,
                            child: Text(school.name),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (value) => setModalState(
                            () => selectedSchoolId = value ?? '',
                          ),
                  ),
                if (type == AdminEntityType.driver)
                  TextField(
                    controller: license,
                    decoration: const InputDecoration(
                      labelText: 'License number',
                    ),
                  ),
                if (type == AdminEntityType.driver)
                  DropdownButtonFormField<String>(
                    value: selectedBusId.isEmpty ? null : selectedBusId,
                    decoration: const InputDecoration(
                      labelText: 'Assigned bus',
                    ),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('No bus')),
                      ...provider.buses
                          .where((bus) => !bus.isArchived)
                          .map(
                            (bus) => DropdownMenuItem(
                              value: bus.id,
                              child: Text(bus.busNumber),
                            ),
                          ),
                    ],
                    onChanged: saving
                        ? null
                        : (value) =>
                              setModalState(() => selectedBusId = value ?? ''),
                  ),
                TextField(
                  controller: password,
                  decoration: InputDecoration(
                    labelText: existing == null
                        ? 'Initial password'
                        : 'New password (optional)',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: Text(context.tr(AppStrings.cancel)),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setModalState(() => saving = true);
                      final input = AdminManagedUserInput(
                        type: type,
                        referenceId: existing is Parent
                            ? existing.id
                            : existing is Teacher
                            ? existing.id
                            : existing is Driver
                            ? existing.id
                            : null,
                        name: name.text.trim(),
                        email: email.text.trim(),
                        phone: phone.text.trim(),
                        licenseNumber: license.text.trim(),
                        password: password.text.trim().isEmpty
                            ? null
                            : password.text.trim(),
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
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
    final emergencyName = TextEditingController(
      text: existing?.emergencyContactName ?? '',
    );
    final emergencyPhone = TextEditingController(
      text: existing?.emergencyContactPhone ?? '',
    );
    String selectedParentId =
        existing?.parentId ?? provider.parents.firstOrNull?.id ?? '';
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
                  items: provider.parents
                      .where((parent) => !parent.isArchived)
                      .map(
                        (parent) => DropdownMenuItem(
                          value: parent.id,
                          child: Text(parent.name),
                        ),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (value) =>
                            setModalState(() => selectedParentId = value ?? ''),
                ),
                DropdownButtonFormField<String>(
                  value: selectedSchoolId.isEmpty ? null : selectedSchoolId,
                  decoration: const InputDecoration(labelText: 'School'),
                  items: provider.schools
                      .where((school) => !school.isArchived)
                      .map(
                        (school) => DropdownMenuItem(
                          value: school.id,
                          child: Text(school.name),
                        ),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (value) =>
                            setModalState(() => selectedSchoolId = value ?? ''),
                ),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: grade,
                  decoration: const InputDecoration(labelText: 'Grade'),
                ),
                TextField(
                  controller: emergencyName,
                  decoration: const InputDecoration(
                    labelText: 'Emergency contact',
                  ),
                ),
                TextField(
                  controller: emergencyPhone,
                  decoration: const InputDecoration(
                    labelText: 'Emergency phone',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          final picked =
                              await Navigator.push<PickupLocationResult>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MapPickerScreen(
                                    initialLat: location?.lat,
                                    initialLng: location?.lng,
                                  ),
                                ),
                              );
                          if (picked != null) {
                            setModalState(() => location = picked);
                          }
                        },
                  icon: const Icon(Icons.pin_drop_outlined),
                  label: Text(location?.label ?? 'Choose pickup location'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: Text(context.tr(AppStrings.cancel)),
            ),
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
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
    final activeSchools = provider.schools
        .where((school) => !school.isArchived)
        .toList();
    final existingSchoolIsActive = activeSchools.any(
      (school) => school.id == existing?.schoolId,
    );
    final selectedFilterIsActive = activeSchools.any(
      (school) => school.id == provider.selectedSchoolId,
    );
    String selectedSchoolId = existingSchoolIsActive
        ? existing!.schoolId
        : selectedFilterIsActive
        ? provider.selectedSchoolId
        : '';
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Create bus' : 'Edit bus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: busNumber,
                decoration: const InputDecoration(labelText: 'Bus number'),
              ),
              TextField(
                controller: plate,
                decoration: const InputDecoration(labelText: 'License plate'),
              ),
              DropdownButtonFormField<String>(
                initialValue: selectedSchoolId.isEmpty
                    ? null
                    : selectedSchoolId,
                decoration: const InputDecoration(labelText: 'School'),
                items: activeSchools.map((school) {
                  final used = provider.activeBusCountForSchool(school.id);
                  final capacity = school.busLimit == null
                      ? '$used buses — unlimited'
                      : '$used/${school.busLimit} buses';
                  return DropdownMenuItem(
                    value: school.id,
                    enabled: provider.schoolCanAcceptBus(
                      school,
                      currentBus: existing,
                    ),
                    child: Text('${school.name} — $capacity'),
                  );
                }).toList(),
                onChanged: saving
                    ? null
                    : (value) =>
                          setModalState(() => selectedSchoolId = value ?? ''),
              ),
              DropdownButtonFormField<String>(
                value: selectedDriverId.isEmpty ? null : selectedDriverId,
                decoration: const InputDecoration(labelText: 'Driver'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('No driver')),
                  ...provider.drivers
                      .where((driver) => !driver.isArchived)
                      .map(
                        (driver) => DropdownMenuItem(
                          value: driver.id,
                          child: Text(driver.name),
                        ),
                      ),
                ],
                onChanged: saving
                    ? null
                    : (value) =>
                          setModalState(() => selectedDriverId = value ?? ''),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: Text(context.tr(AppStrings.cancel)),
            ),
            ElevatedButton(
              onPressed: saving || selectedSchoolId.isEmpty
                  ? null
                  : () async {
                      setModalState(() => saving = true);
                      final ok = await provider.saveBus(
                        AdminBusInput(
                          id: existing?.id,
                          busNumber: busNumber.text.trim(),
                          licensePlate: plate.text.trim(),
                          driverId: selectedDriverId,
                          schoolId: selectedSchoolId,
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
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
    String selectedBusId =
        existing?.busId ?? provider.buses.firstOrNull?.id ?? '';
    TripRound round = existing?.round ?? TripRound.toSchool;
    DateTime serviceDate = existing?.serviceDate ?? DateTime.now();
    TimeOfDay selectedTime = existing?.scheduledStartAt == null
        ? TimeOfDay.now()
        : TimeOfDay.fromDateTime(existing!.scheduledStartAt!);
    final selectedChildIds = <String>{...?existing?.childIds};
    Map<String, dynamic>? origin = existing?.origin == null
        ? null
        : Map<String, dynamic>.from(existing!.origin!);
    Map<String, dynamic>? routePlan = existing?.routePlan == null
        ? null
        : {
            ...existing!.routePlan!,
            'stops': existing.stops.map((stop) => stop.toMap()).toList(),
          };
    Timer? routeTimer;
    var routeRequest = 0;
    var calculating = false;
    String? routeError;
    final searchController = TextEditingController();
    var searchQuery = '';
    bool saving = false;

    bool hasCoordinates(dynamic lat, dynamic lng) {
      final parsedLat = double.tryParse('$lat');
      final parsedLng = double.tryParse('$lng');
      return parsedLat != null &&
          parsedLng != null &&
          parsedLat >= -90 &&
          parsedLat <= 90 &&
          parsedLng >= -180 &&
          parsedLng <= 180 &&
          !(parsedLat == 0 && parsedLng == 0);
    }

    Map<String, dynamic>? defaultOrigin(String busId) {
      final bus = provider.busById(busId);
      if (bus == null) return null;
      if (hasCoordinates(bus.currentLat, bus.currentLng)) {
        return {
          'lat': bus.currentLat,
          'lng': bus.currentLng,
          'label': 'Bus ${bus.busNumber} current location',
        };
      }
      final school = provider.schoolById(bus.schoolId);
      if (school != null && hasCoordinates(school.lat, school.lng)) {
        return {'lat': school.lat, 'lng': school.lng, 'label': school.name};
      }
      return null;
    }

    origin ??= defaultOrigin(selectedBusId);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final students =
              provider.children.where((child) {
                if (child.isArchived) return false;
                if (searchQuery.isEmpty) return true;
                final school = provider.schoolById(child.schoolId);
                return '${child.name} ${school?.name ?? ''}'
                    .toLowerCase()
                    .contains(searchQuery);
              }).toList()..sort((a, b) {
                final schoolA = provider.schoolById(a.schoolId)?.name ?? '';
                final schoolB = provider.schoolById(b.schoolId)?.name ?? '';
                final schoolCompare = schoolA.compareTo(schoolB);
                return schoolCompare != 0
                    ? schoolCompare
                    : a.name.compareTo(b.name);
              });

          DateTime scheduledStart() => DateTime(
            serviceDate.year,
            serviceDate.month,
            serviceDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );

          Future<void> calculateRoute({bool manual = false}) async {
            final currentOrigin = origin;
            if (selectedBusId.isEmpty ||
                selectedChildIds.isEmpty ||
                currentOrigin == null ||
                !hasCoordinates(currentOrigin['lat'], currentOrigin['lng'])) {
              setModalState(() {
                routePlan = null;
                routeError = null;
              });
              return;
            }
            final request = ++routeRequest;
            setModalState(() {
              calculating = true;
              routeError = null;
            });
            final result = await provider.calculateTripRoute(
              tripId: existing?.id,
              busId: selectedBusId,
              serviceDate: serviceDate,
              round: round,
              scheduledStartAt: scheduledStart(),
              childIds: selectedChildIds.toList(),
              origin: currentOrigin,
              manual: manual,
            );
            if (!dialogContext.mounted || request != routeRequest) return;
            setModalState(() {
              calculating = false;
              if (result == null) {
                routePlan = null;
                routeError =
                    provider.errorMessage ?? 'Route calculation failed.';
              } else {
                routePlan = Map<String, dynamic>.from(
                  result['routePlan'] as Map,
                );
                if (result['origin'] is Map) {
                  origin = Map<String, dynamic>.from(result['origin'] as Map);
                }
              }
            });
          }

          void scheduleRoute() {
            routeRequest++;
            routeTimer?.cancel();
            setModalState(() {
              routePlan = null;
              routeError = null;
            });
            routeTimer = Timer(
              const Duration(milliseconds: 800),
              calculateRoute,
            );
          }

          void moveStop(int index, int offset) {
            final plan = routePlan;
            if (plan == null || plan['stops'] is! List) return;
            final stops = List<Map<String, dynamic>>.from(
              (plan['stops'] as List).map(
                (stop) => Map<String, dynamic>.from(stop as Map),
              ),
            );
            final target = index + offset;
            if (target < 0 ||
                target >= stops.length ||
                stops[target]['type'] != stops[index]['type']) {
              return;
            }
            final moved = stops.removeAt(index);
            stops.insert(target, moved);
            for (var i = 0; i < stops.length; i++) {
              stops[i]['sequence'] = i;
            }
            setModalState(() {
              routePlan = {
                ...plan,
                'provider': 'manual',
                'distanceMeters': null,
                'durationSeconds': null,
                'polylines': <String>[],
                'stops': stops,
              };
            });
          }

          final routeStops = routePlan?['stops'] is List
              ? List<Map<String, dynamic>>.from(
                  (routePlan!['stops'] as List).map(
                    (stop) => Map<String, dynamic>.from(stop as Map),
                  ),
                )
              : <Map<String, dynamic>>[];
          final studentWidgets = <Widget>[];
          String? previousSchoolId;
          for (final child in students) {
            final school = provider.schoolById(child.schoolId);
            if (child.schoolId != previousSchoolId) {
              studentWidgets.add(
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: AppColors.surfaceDark,
                  child: Text(
                    school?.name ?? 'School unavailable',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              );
              previousSchoolId = child.schoolId;
            }
            final conflict = provider.trips
                .where(
                  (trip) =>
                      trip.id != existing?.id &&
                      trip.isOpen &&
                      trip.round == round &&
                      trip.serviceDate.year == serviceDate.year &&
                      trip.serviceDate.month == serviceDate.month &&
                      trip.serviceDate.day == serviceDate.day &&
                      trip.childIds.contains(child.id),
                )
                .firstOrNull;
            final coordinatesAvailable =
                school != null &&
                !school.isArchived &&
                hasCoordinates(child.pickupLat, child.pickupLng) &&
                hasCoordinates(school.lat, school.lng);
            final available = coordinatesAvailable && conflict == null;
            studentWidgets.add(
              CheckboxListTile(
                dense: true,
                value: selectedChildIds.contains(child.id),
                title: Text(child.name),
                subtitle: Text(
                  available
                      ? child.pickupLabel
                      : !coordinatesAvailable
                      ? 'Missing student or school coordinates'
                      : 'Already assigned to ${conflict!.id}',
                ),
                onChanged: (saving || !available)
                    ? null
                    : (value) {
                        setModalState(() {
                          if (value == true) {
                            selectedChildIds.add(child.id);
                          } else {
                            selectedChildIds.remove(child.id);
                          }
                        });
                        scheduleRoute();
                      },
              ),
            );
          }

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
                      value: selectedBusId.isEmpty ? null : selectedBusId,
                      decoration: const InputDecoration(labelText: 'Bus'),
                      items: provider.buses
                          .where((bus) => !bus.isArchived)
                          .map(
                            (bus) => DropdownMenuItem(
                              value: bus.id,
                              child: Text(bus.busNumber),
                            ),
                          )
                          .toList(),
                      onChanged: (saving || isActive)
                          ? null
                          : (value) {
                              setModalState(() {
                                selectedBusId = value ?? '';
                                origin = defaultOrigin(selectedBusId);
                              });
                              scheduleRoute();
                            },
                    ),
                    DropdownButtonFormField<TripRound>(
                      value: round,
                      decoration: const InputDecoration(labelText: 'Round'),
                      items: const [
                        DropdownMenuItem(
                          value: TripRound.toSchool,
                          child: Text('To school'),
                        ),
                        DropdownMenuItem(
                          value: TripRound.toHome,
                          child: Text('To home'),
                        ),
                      ],
                      onChanged: (saving || isActive)
                          ? null
                          : (value) {
                              setModalState(
                                () => round = value ?? TripRound.toSchool,
                              );
                              scheduleRoute();
                            },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Date: ${serviceDate.toIso8601String().split('T').first}',
                      ),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: (saving || isActive)
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: serviceDate,
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setModalState(() => serviceDate = picked);
                                scheduleRoute();
                              }
                            },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Start time: ${selectedTime.format(context)}',
                      ),
                      trailing: const Icon(Icons.schedule_outlined),
                      onTap: (saving || isActive)
                          ? null
                          : () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setModalState(() => selectedTime = picked);
                                scheduleRoute();
                              }
                            },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(origin?['label'] as String? ?? 'Start point'),
                      subtitle: origin == null
                          ? const Text('Choose a start location')
                          : Text('${origin!['lat']}, ${origin!['lng']}'),
                      trailing: const Icon(Icons.map_outlined),
                      onTap: (saving || isActive)
                          ? null
                          : () async {
                              final picked =
                                  await Navigator.push<PickupLocationResult>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MapPickerScreen(
                                        initialLat: (origin?['lat'] as num?)
                                            ?.toDouble(),
                                        initialLng: (origin?['lng'] as num?)
                                            ?.toDouble(),
                                      ),
                                    ),
                                  );
                              if (picked != null) {
                                setModalState(() {
                                  origin = {
                                    'lat': picked.lat,
                                    'lng': picked.lng,
                                    'label': picked.label,
                                  };
                                });
                                scheduleRoute();
                              }
                            },
                    ),
                    if (!isActive) ...[
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search student or school',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) => setModalState(
                          () => searchQuery = value.trim().toLowerCase(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...studentWidgets,
                    ],
                    if (calculating)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (routeError != null) ...[
                      Text(
                        routeError!,
                        style: const TextStyle(color: AppColors.statusRed),
                      ),
                      OutlinedButton(
                        onPressed: calculating
                            ? null
                            : () => calculateRoute(manual: true),
                        child: const Text('Build manual route'),
                      ),
                    ],
                    if (routePlan != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        routePlan!['provider'] == 'manual'
                            ? 'Manual route'
                            : 'Google optimized route',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(_routeSummary(routePlan!)),
                      const SizedBox(height: 8),
                      if (origin != null && routeStops.isNotEmpty)
                        SizedBox(
                          height: 240,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                (origin!['lat'] as num).toDouble(),
                                (origin!['lng'] as num).toDouble(),
                              ),
                              zoom: 10,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('origin'),
                                position: LatLng(
                                  (origin!['lat'] as num).toDouble(),
                                  (origin!['lng'] as num).toDouble(),
                                ),
                                infoWindow: const InfoWindow(title: 'Start'),
                              ),
                              for (var i = 0; i < routeStops.length; i++)
                                Marker(
                                  markerId: MarkerId(
                                    routeStops[i]['id'] as String,
                                  ),
                                  position: LatLng(
                                    (routeStops[i]['lat'] as num).toDouble(),
                                    (routeStops[i]['lng'] as num).toDouble(),
                                  ),
                                  infoWindow: InfoWindow(
                                    title:
                                        '${i + 1}. ${routeStops[i]['label']}',
                                  ),
                                ),
                            },
                            polylines: _routePolylines(routePlan!),
                            liteModeEnabled: true,
                            myLocationButtonEnabled: false,
                          ),
                        ),
                      ...routeStops.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stop = entry.value;
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(stop['label'] as String? ?? ''),
                          subtitle: Text(
                            '${stop['action']} • ${(stop['childNames'] as List? ?? const []).join(', ')}',
                          ),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_upward, size: 18),
                                onPressed:
                                    index > 0 &&
                                        routeStops[index - 1]['type'] ==
                                            stop['type']
                                    ? () => moveStop(index, -1)
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_downward,
                                  size: 18,
                                ),
                                onPressed:
                                    index < routeStops.length - 1 &&
                                        routeStops[index + 1]['type'] ==
                                            stop['type']
                                    ? () => moveStop(index, 1)
                                    : null,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: Text(context.tr(AppStrings.cancel)),
              ),
              ElevatedButton(
                onPressed:
                    saving ||
                        calculating ||
                        routePlan == null ||
                        selectedChildIds.isEmpty ||
                        origin == null ||
                        isActive
                    ? null
                    : () async {
                        setModalState(() => saving = true);
                        final ok = await provider.saveTrip(
                          AdminTripInput(
                            id: existing?.id,
                            busId: selectedBusId,
                            serviceDate: serviceDate,
                            round: round,
                            scheduledStartAt: scheduledStart(),
                            childIds: selectedChildIds.toList(),
                            origin: origin!,
                            routePlan: routePlan!,
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
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(existing == null ? 'Create' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
    routeTimer?.cancel();
    searchController.dispose();
  }

  String _routeSummary(Map<String, dynamic> routePlan) {
    final distance = routePlan['distanceMeters'] as num?;
    final duration = routePlan['durationSeconds'] as num?;
    if (distance == null || duration == null) return 'No distance or ETA';
    final distanceLabel = distance >= 1000
        ? '${(distance / 1000).toStringAsFixed(1)} km'
        : '${distance.round()} m';
    final minutes = (duration / 60).round();
    final durationLabel = minutes >= 60
        ? '${minutes ~/ 60}h ${minutes % 60}m'
        : '$minutes min';
    return '$distanceLabel • $durationLabel';
  }

  Set<Polyline> _routePolylines(Map<String, dynamic> routePlan) {
    final values = List<String>.from(
      routePlan['polylines'] as List? ?? const [],
    );
    return values.asMap().entries.map((entry) {
      return Polyline(
        polylineId: PolylineId('route-${entry.key}'),
        points: _decodePolyline(entry.value),
        color: AppColors.primary,
        width: 5,
      );
    }).toSet();
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;
    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      lat += (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      lng += (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  Future<void> _toggleSchoolArchive(School school) async {
    await context.read<AdminProvider>().setSchoolArchived(
      school.id,
      !school.isArchived,
    );
  }

  Future<void> _togglePersonArchive(Object item) async {
    final provider = context.read<AdminProvider>();
    final type = item is Parent
        ? AdminEntityType.parent
        : item is Teacher
        ? AdminEntityType.teacher
        : AdminEntityType.driver;
    final id = item is Parent
        ? item.id
        : item is Teacher
        ? item.id
        : (item as Driver).id;
    final archived = item is Parent
        ? item.isArchived
        : item is Teacher
        ? item.isArchived
        : (item as Driver).isArchived;
    await provider.setManagedUserArchived(
      type: type,
      referenceId: id,
      archived: !archived,
    );
  }

  Future<void> _toggleChildArchive(Child child) async {
    await context.read<AdminProvider>().setChildArchived(
      child.id,
      !child.isArchived,
    );
  }

  Future<void> _toggleBusArchive(Bus bus) async {
    await context.read<AdminProvider>().setBusArchived(bus.id, !bus.isArchived);
  }

  Future<void> _toggleTripArchive(Trip trip) async {
    await context.read<AdminProvider>().setTripArchived(
      trip.id,
      !trip.isArchived,
    );
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
            TextButton(
              onPressed: onArchive,
              child: Text(archived ? 'Restore' : 'Archive'),
            ),
            if (extra != null) extra,
          ],
        ),
      ],
    ),
  );
}
