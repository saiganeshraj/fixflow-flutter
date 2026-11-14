import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/clock.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/widgets/loading_error_empty.dart';
import '../models.dart';

const _uuid = Uuid();

class BookingFormScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const BookingFormScreen({super.key, required this.serviceId});

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addr1Controller = TextEditingController();
  final _addr2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedSlot;
  bool _submitting = false;
  String? _submitError;
  late final String _idempotencyKey;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = _uuid.v4();
    // Pre-fill city for the demo.
    _cityController.text = 'Bengaluru';
    _addr1Controller.text = '';
    _pincodeController.text = '';
  }

  @override
  void dispose() {
    _addr1Controller.dispose();
    _addr2Controller.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(serviceProvider(widget.serviceId));
    final slotsAsync = ref.watch(availableSlotsProvider(widget.serviceId));
    final slots = slotsAsync.valueOrNull ?? <DateTime>[];
    if (slotsAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Service')),
        body: ErrorState(
          message: slotsAsync.error.toString(),
          onRetry: () =>
              ref.invalidate(availableSlotsProvider(widget.serviceId)),
        ),
      );
    }
    if (slotsAsync.isLoading) {
      return const Scaffold(
        body: LoadingState(message: 'Checking availability…'),
      );
    }

    return serviceAsync.when(
      data: (service) {
        if (service == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Book Service')),
            body: const ErrorState(message: 'Service not found.'),
          );
        }
        return _buildForm(context, service, slots);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Book Service')),
        body: const LoadingState(message: 'Loading…'),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Book Service')),
        body: ErrorState(message: err.toString()),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    Service service,
    List<DateTime> slots,
  ) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.serviceDetailPath(widget.serviceId)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: isWide
            ? _buildWideLayout(context, service, slots, theme)
            : _buildNarrowLayout(context, service, slots, theme),
      ),
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    Service service,
    List<DateTime> slots,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ServiceSummaryCard(service: service),
              const SizedBox(height: 20),
              _buildSlotSection(slots, theme),
              const SizedBox(height: 20),
              _buildAddressSection(theme),
              const SizedBox(height: 20),
              _buildNotesSection(theme),
              if (_submitError != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _submitError!),
              ],
            ],
          ),
        ),
        _buildPriceSummaryBar(context, service),
      ],
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    Service service,
    List<DateTime> slots,
    ThemeData theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.all(32),
            children: [
              _buildSlotSection(slots, theme),
              const SizedBox(height: 24),
              _buildAddressSection(theme),
              const SizedBox(height: 24),
              _buildNotesSection(theme),
              if (_submitError != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _submitError!),
              ],
            ],
          ),
        ),
        Container(
          width: 320,
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Color(0xFFE5E0DB))),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ServiceSummaryCard(service: service),
              const SizedBox(height: 24),
              _buildPriceSummaryContent(service, theme),
              const SizedBox(height: 24),
              _buildSubmitButton(context, service),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotSection(List<DateTime> slots, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date & Time',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Slots show IST (India Standard Time). 60-minute appointments.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        if (slots.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD700)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFF856404)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No available slots in the next 7 days.',
                    style: TextStyle(color: Color(0xFF856404), fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          _SlotPicker(
            slots: slots,
            selectedSlot: _selectedSlot,
            onSlotSelected: (slot) => setState(() => _selectedSlot = slot),
          ),
        if (_selectedSlot == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Please select a time slot.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddressSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Address',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addr1Controller,
          decoration: const InputDecoration(
            labelText: 'Address Line 1 *',
            hintText: 'House / flat number, street',
          ),
          textCapitalization: TextCapitalization.words,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Address line 1 is required';
            }
            if (v.trim().length < 5) return 'Please enter a complete address';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addr2Controller,
          decoration: const InputDecoration(
            labelText: 'Address Line 2',
            hintText: 'Apartment, landmark (optional)',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'City is required';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 130,
              child: TextFormField(
                controller: _pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode *'),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (v) {
                  if (v == null ||
                      !RegExp(r'^[1-9][0-9]{5}$').hasMatch(v.trim())) {
                    return 'Valid 6-digit pincode required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes for the technician (optional)',
            hintText: 'e.g. "Please call when 10 minutes away"',
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildPriceSummaryContent(Service service, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Summary',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                service.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            Text(
              formatPaise(service.pricePaise),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Platform fee',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text('₹0', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              formatPaise(service.pricePaise),
              style: theme.textTheme.titleSmall?.copyWith(
                color: const Color(0xFF007A7A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Fixed price — no hidden charges.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
        ),
        if (_selectedSlot != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF007A7A).withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  size: 16,
                  color: Color(0xFF007A7A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formatSlot(_selectedSlot!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF007A7A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceSummaryBar(BuildContext context, Service service) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E0DB))),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatPaise(service.pricePaise),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF007A7A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Fixed price',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            _buildSubmitButton(context, service),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, Service service) {
    return SizedBox(
      width: 160,
      child: ElevatedButton(
        onPressed: _submitting ? null : () => _submit(context, service),
        child: _submitting
            ? const InlineLoading(label: 'Booking…')
            : const Text('Confirm Booking'),
      ),
    );
  }

  Future<void> _submit(BuildContext context, Service service) async {
    if (_submitting) return;
    // Validate slot selection separately.
    if (_selectedSlot == null) {
      setState(
        () => _submitError =
            'Please select a date and time slot before confirming.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final customerId = ref.read(bookingCustomerIdProvider);

      final repo = ref.read(repositoryProvider);
      final booking = await repo.createBooking(
        BookingRequest(
          serviceId: service.id,
          slotStartUtc: _selectedSlot!,
          addressLine1: _addr1Controller.text,
          addressLine2: _addr2Controller.text,
          city: _cityController.text,
          pincode: _pincodeController.text,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          idempotencyKey: _idempotencyKey,
        ),
        customerId,
      );

      ref.invalidate(customerBookingsProvider);
      if (context.mounted) {
        context.go(AppRoutes.bookingConfirmationPath(booking.id));
      }
    } on DuplicateBookingError catch (e) {
      // Idempotent — navigate to the existing booking.
      ref.invalidate(customerBookingsProvider);
      if (context.mounted) {
        context.go(AppRoutes.bookingConfirmationPath(e.existingBookingId));
      }
    } on AppError catch (e) {
      if (!mounted) return;
      ref.invalidate(availableSlotsProvider(widget.serviceId));
      setState(() {
        _submitting = false;
        _submitError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = 'An unexpected error occurred. Please try again.';
      });
    }
  }
}

/// Slot picker organized by day.
class _SlotPicker extends StatefulWidget {
  final List<DateTime> slots;
  final DateTime? selectedSlot;
  final ValueChanged<DateTime> onSlotSelected;

  const _SlotPicker({
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  State<_SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends State<_SlotPicker> {
  String? _day;

  @override
  Widget build(BuildContext context) {
    // Group slots by day (IST).
    final Map<String, List<DateTime>> byDay = {};
    for (final slot in widget.slots) {
      final key = formatDate(slot);
      byDay.putIfAbsent(key, () => []).add(slot);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: byDay.keys
              .map(
                (day) => ChoiceChip(
                  label: Text(day),
                  selected: day == (_day ?? byDay.keys.first),
                  onSelected: (_) => setState(() => _day = day),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        ...byDay.entries
            .where((entry) => entry.key == (_day ?? byDay.keys.first))
            .map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value.map((slot) {
                      final ist = toServiceTimezone(slot);
                      final hour = ist.hour == 0
                          ? 12
                          : ist.hour > 12
                          ? ist.hour - 12
                          : ist.hour;
                      final ampm = ist.hour < 12 ? 'AM' : 'PM';
                      final label = '$hour:00 $ampm';
                      final isSelected = widget.selectedSlot == slot;
                      return FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (_) => widget.onSlotSelected(slot),
                        selectedColor: const Color(0xFF007A7A).withAlpha(30),
                        checkmarkColor: const Color(0xFF007A7A),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
      ],
    );
  }
}

class _ServiceSummaryCard extends StatelessWidget {
  final Service service;
  const _ServiceSummaryCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF007A7A).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _icon(service.categoryId),
                color: const Color(0xFF007A7A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${service.durationMinutes} min · Fixed price',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String cat) => switch (cat) {
    'cat-plumbing' => Icons.plumbing_rounded,
    'cat-electrical' => Icons.electrical_services_rounded,
    'cat-cleaning' => Icons.cleaning_services_rounded,
    _ => Icons.build_rounded,
  };
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC0392B).withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFC0392B),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF7A0000), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
