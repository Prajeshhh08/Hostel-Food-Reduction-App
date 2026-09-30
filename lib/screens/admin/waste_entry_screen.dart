import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/validators.dart';
import '../../models/waste_log.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/meal_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class WasteEntryScreen extends ConsumerStatefulWidget {
  final int mealId;

  const WasteEntryScreen({super.key, required this.mealId});

  @override
  ConsumerState<WasteEntryScreen> createState() => _WasteEntryScreenState();
}

class _WasteEntryScreenState extends ConsumerState<WasteEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _preparedController = TextEditingController();
  final _servedController = TextEditingController();
  final _wastedController = TextEditingController();
  final _attendanceController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isEditing = false;
  int? _existingWasteLogId;
  String? _validationError;

  @override
  void dispose() {
    _preparedController.dispose();
    _servedController.dispose();
    _wastedController.dispose();
    _attendanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateForm(WasteLog log) {
    _existingWasteLogId = log.id;
    _preparedController.text = log.preparedPortions % 1 == 0
        ? log.preparedPortions.toInt().toString()
        : log.preparedPortions.toString();
    _servedController.text = log.servedPortions % 1 == 0
        ? log.servedPortions.toInt().toString()
        : log.servedPortions.toString();
    _wastedController.text = log.wastedPortions % 1 == 0
        ? log.wastedPortions.toInt().toString()
        : log.wastedPortions.toString();
    _attendanceController.text = log.actualAttendanceCount?.toString() ?? '';
    _notesController.text = log.notes ?? '';
  }

  Future<void> _handleSaveWaste() async {
    if (!_formKey.currentState!.validate()) return;

    final prepared = double.tryParse(_preparedController.text.trim()) ?? 0.0;
    final served = double.tryParse(_servedController.text.trim()) ?? 0.0;
    final wasted = double.tryParse(_wastedController.text.trim()) ?? 0.0;
    final attendanceText = _attendanceController.text.trim();
    final attendance =
        attendanceText.isNotEmpty ? int.tryParse(attendanceText) : null;

    // Validate portion relationships & non-negative constraints
    final portionError = Validators.validateWastePortions(
      prepared: prepared,
      served: served,
      wasted: wasted,
      attendance: attendance,
    );
    if (portionError != null) {
      setState(() {
        _validationError = portionError;
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    try {
      if (_existingWasteLogId != null) {
        await ref.read(wasteLogNotifierProvider.notifier).updateWasteLog(
              mealId: widget.mealId,
              wasteLogId: _existingWasteLogId!,
              preparedPortions: prepared,
              servedPortions: served,
              wastedPortions: wasted,
              actualAttendanceCount: attendance,
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            );
      } else {
        await ref.read(wasteLogNotifierProvider.notifier).createWasteLog(
              mealId: widget.mealId,
              preparedPortions: prepared,
              servedPortions: served,
              wastedPortions: wasted,
              actualAttendanceCount: attendance,
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✓ Waste record saved successfully'),
              ],
            ),
            backgroundColor: Color(0xFF15803D),
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _validationError = ErrorHandler.getFriendlyErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealAsync = ref.watch(mealDetailProvider(widget.mealId));
    final existingLogAsync = ref.watch(mealWasteLogProvider(widget.mealId));
    final predictionAsync = ref.watch(foodPredictionProvider(widget.mealId));
    final submitState = ref.watch(wasteLogNotifierProvider);
    final isSubmitting = submitState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Meal Waste'),
      ),
      body: mealAsync.when(
        data: (meal) {
          return existingLogAsync.when(
            data: (existingLog) {
              final hasExisting = existingLog != null;

              // If record exists and we're not actively in edit mode, show the summary view
              if (hasExisting && !_isEditing) {
                return _buildExistingRecordView(meal, existingLog);
              }

              // Otherwise show the entry/edit form
              return _buildWasteForm(meal, predictionAsync, isSubmitting, hasExisting);
            },
            loading: () => const Center(
              child: LoadingView(message: 'Checking existing waste records...'),
            ),
            error: (err, _) => ErrorView(
              message: ErrorHandler.getFriendlyErrorMessage(err),
              onRetry: () => ref.invalidate(mealWasteLogProvider(widget.mealId)),
            ),
          );
        },
        loading: () => const Center(
          child: LoadingView(message: 'Loading meal info...'),
        ),
        error: (err, _) => ErrorView(
          message: ErrorHandler.getFriendlyErrorMessage(err),
          onRetry: () => ref.invalidate(mealDetailProvider(widget.mealId)),
        ),
      ),
    );
  }

  Widget _buildExistingRecordView(dynamic meal, WasteLog existingLog) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Meal Info Card
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    meal?.displayIcon ?? '🍽️',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal?.displayName ?? 'Meal',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (meal?.menuName != null && meal.menuName.isNotEmpty)
                        Text(
                          meal.menuName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Already Recorded Card
          Card(
            color: const Color(0xFFF0FDF4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF86EFAC)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF15803D),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Meal Result Already Recorded',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRecordRow('Prepared Portions', '${existingLog.preparedPortions}'),
                  _buildRecordRow('Served Portions', '${existingLog.servedPortions}'),
                  _buildRecordRow('Wasted Portions', '${existingLog.wastedPortions}'),
                  if (existingLog.actualAttendanceCount != null)
                    _buildRecordRow(
                      'Actual Attendance',
                      '${existingLog.actualAttendanceCount} students',
                    ),
                  if (existingLog.notes != null && existingLog.notes!.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text(
                      'Notes:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      existingLog.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () {
              _populateForm(existingLog);
              setState(() {
                _isEditing = true;
                _validationError = null;
              });
            },
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Edit Record'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteForm(
    dynamic meal,
    AsyncValue<dynamic> predictionAsync,
    bool isSubmitting,
    bool hasExisting,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Meal Header
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      meal?.displayIcon ?? '🍽️',
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal?.displayName ?? 'Meal',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (meal?.menuName != null && meal.menuName.isNotEmpty)
                          Text(
                            meal.menuName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Optional Preparation Recommendation Reference
            predictionAsync.when(
              data: (predictions) {
                if (predictions.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 16,
                            color: Color(0xFF1D4ED8),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Preparation Recommendation Reference',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...predictions.map((p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text(
                              '• ${p.foodName}: ${p.recommendedPortions} portions (${p.formattedQuantity})',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          )),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
            ),

            if (_validationError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Prepared Portions
            TextFormField(
              controller: _preparedController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Prepared Portions *',
                hintText: 'e.g. 100',
                prefixIcon: Icon(Icons.soup_kitchen_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter prepared portions';
                }
                final val = double.tryParse(v.trim());
                if (val == null || val < 0) {
                  return 'Prepared portions must be 0 or greater';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Served Portions
            TextFormField(
              controller: _servedController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Served Portions *',
                hintText: 'e.g. 92',
                prefixIcon: Icon(Icons.restaurant_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter served portions';
                }
                final val = double.tryParse(v.trim());
                if (val == null || val < 0) {
                  return 'Served portions must be 0 or greater';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Wasted Portions
            TextFormField(
              controller: _wastedController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Wasted Portions *',
                hintText: 'e.g. 8',
                prefixIcon: Icon(Icons.delete_outline_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter wasted portions';
                }
                final val = double.tryParse(v.trim());
                if (val == null || val < 0) {
                  return 'Wasted portions must be 0 or greater';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Actual Attendance (Integer)
            TextFormField(
              controller: _attendanceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Actual Attendance (Students)',
                hintText: 'e.g. 90',
                prefixIcon: Icon(Icons.people_alt_outlined),
              ),
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final val = int.tryParse(v.trim());
                  if (val == null || val < 0) {
                    return 'Attendance must be 0 or greater';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add remarks about meal turnout or waste reasons...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                if (hasExisting) ...[
                  OutlinedButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _isEditing = false;
                              _validationError = null;
                            });
                          },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isSubmitting ? null : _handleSaveWaste,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      isSubmitting
                          ? 'Saving...'
                          : hasExisting
                              ? 'Update Waste Record'
                              : 'Save Waste Record',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
