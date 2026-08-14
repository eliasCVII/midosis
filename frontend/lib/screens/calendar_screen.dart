import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<ItemCalendarioModel> _items = [];
  bool _isLoading = true;

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() => _isLoading = true);
    final items = await ApiService.getCalendar(pacienteId: 'demo');
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  // Calculate exact intake time slots for a specific calendar day (handles cross-midnight shifts and multi-day frequencies)
  List<String> _getIntakeSlotsForDay(ItemCalendarioModel item, DateTime day) {
    final targetDate = DateTime(day.year, day.month, day.day);
    
    final fullStart = item.fechaInicio ?? targetDate;
    final startDateOnly = DateTime(fullStart.year, fullStart.month, fullStart.day);
    
    final endDate = item.fechaTermino != null
        ? DateTime(item.fechaTermino!.year, item.fechaTermino!.month, item.fechaTermino!.day, 23, 59, 59)
        : startDateOnly.add(Duration(days: item.duracionDias));

    if (targetDate.isBefore(startDateOnly) || targetDate.isAfter(DateTime(endDate.year, endDate.month, endDate.day))) {
      return [];
    }

    final List<String> slots = [];
    final freqHours = item.frecuenciaHoras <= 0 ? 8 : item.frecuenciaHoras;
    DateTime currentIntake = fullStart;

    while (!currentIntake.isAfter(endDate)) {
      final intakeDate = DateTime(currentIntake.year, currentIntake.month, currentIntake.day);
      if (DateUtils.isSameDay(intakeDate, targetDate)) {
        final hourStr = currentIntake.hour.toString().padLeft(2, '0');
        final minStr = currentIntake.minute.toString().padLeft(2, '0');
        final slotStr = '$hourStr:$minStr';
        if (!slots.contains(slotStr)) {
          slots.add(slotStr);
        }
      } else if (intakeDate.isAfter(targetDate)) {
        break;
      }
      currentIntake = currentIntake.add(Duration(hours: freqHours));
    }

    return slots;
  }

  // Check if treatment is currently active or completed
  bool _isTreatmentActive(ItemCalendarioModel item) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final startDate = item.fechaInicio != null
        ? DateTime(item.fechaInicio!.year, item.fechaInicio!.month, item.fechaInicio!.day)
        : today;
    
    final endDate = item.fechaTermino != null
        ? DateTime(item.fechaTermino!.year, item.fechaTermino!.month, item.fechaTermino!.day, 23, 59, 59)
        : startDate.add(Duration(days: item.duracionDias));

    return !now.isAfter(endDate);
  }

  // Check if medication intake is active on a specific day based on exact FrecuenciaHoras interval
  bool _isIntakeActiveOnDay(ItemCalendarioModel item, DateTime day) {
    return _getIntakeSlotsForDay(item, day).isNotEmpty;
  }

  // Get active items scheduled for a specific day
  List<ItemCalendarioModel> _getItemsForDay(DateTime day) {
    return _items.where((item) => _isIntakeActiveOnDay(item, day)).toList();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    setState(() {
      _focusedMonth = DateTime.now();
      _selectedDay = DateTime.now();
    });
  }

  // POPUP DETAIL DIALOG WITH EDIT BUTTONS
  void _showMedicationDetailPopUp(ItemCalendarioModel item) {
    final isActive = _isTreatmentActive(item);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.medication, color: Color(0xFF0284C7), size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  avatar: Icon(isActive ? Icons.check_circle : Icons.event_available, color: Colors.white, size: 16),
                  label: Text(
                    isActive ? 'Tratamiento En Curso' : 'Tratamiento Finalizado',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: isActive ? const Color(0xFF0284C7) : Colors.grey.shade600,
                ),
                const SizedBox(height: 8),
                const Divider(),
                const Text('⏱️ Horario y Frecuencia:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Hora inicio: ${item.horaInicio} (Cada ${item.frecuenciaHoras} horas)'),
                const SizedBox(height: 10),
                const Text('📅 Duración del Tratamiento:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${item.duracionDias} días ${item.fechaTermino != null ? "(Término: ${item.fechaTermino!.day}/${item.fechaTermino!.month}/${item.fechaTermino!.year})" : ""}'),
                const SizedBox(height: 10),
                const Text('📖 Descripción / Recomendaciones:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(item.descripcion.isNotEmpty ? item.descripcion : 'Sin recomendaciones específicas'),
                const SizedBox(height: 10),
                const Text('⚠️ Efectos Secundarios:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                Text(item.efectosSecundarios.isNotEmpty ? item.efectosSecundarios : 'No se registraron efectos secundarios'),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16),
                      label: const Text('Modificar Horario'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showModifyScheduleDialog(item);
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.repeat, size: 16),
                      label: const Text('Modificar Frecuencia'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showModifyFrequencyDialog(item);
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.date_range, size: 16),
                      label: const Text('Modificar Duración'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showModifyDurationDialog(item);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteItem(item);
                      },
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cerrar'),
                    ),
                  ],
                )
              ],
            )
          ],
        );
      },
    );
  }

  void _showModifyScheduleDialog(ItemCalendarioModel item) {
    final ctrl = TextEditingController(text: item.horaInicio);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modificar Horario - ${item.nombre}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Hora de consumo (HH:MM)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final ok = await ApiService.modifySchedule('demo', item.idItemCalendario, ctrl.text.trim());
              if (!mounted) return;
              Navigator.pop(ctx);
              if (ok) _loadCalendar();
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  void _showModifyFrequencyDialog(ItemCalendarioModel item) {
    final ctrl = TextEditingController(text: item.frecuenciaHoras.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modificar Frecuencia - ${item.nombre}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Frecuencia (Horas, mayor a 0)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val > 0) {
                final ok = await ApiService.modifyFrequency('demo', item.idItemCalendario, val);
                if (!mounted) return;
                Navigator.pop(ctx);
                if (ok) _loadCalendar();
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  void _showModifyDurationDialog(ItemCalendarioModel item) {
    final ctrl = TextEditingController(text: item.duracionDias.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modificar Duración - ${item.nombre}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Duración (Días, mayor a 0)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val > 0) {
                final ok = await ApiService.modifyDuration('demo', item.idItemCalendario, val);
                if (!mounted) return;
                Navigator.pop(ctx);
                if (ok) _loadCalendar();
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  void _deleteItem(ItemCalendarioModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Medicamento'),
        content: Text('¿Está seguro de eliminar ${item.nombre} de su calendario?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );

    if (confirm == true) {
      final ok = await ApiService.deleteItem('demo', item.idItemCalendario);
      if (ok) _loadCalendar();
    }
  }

  static const List<String> _monthsEs = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  Widget _buildDayCell(DateTime day) {
    final isSelected = DateUtils.isSameDay(day, _selectedDay);
    final isToday = DateUtils.isSameDay(day, DateTime.now());
    final dayItems = _getItemsForDay(day);

    return InkWell(
      onTap: () => setState(() => _selectedDay = day),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0284C7)
              : isToday
                  ? const Color(0xFFE0F2FE)
                  : Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday && !isSelected ? const Color(0xFF0284C7) : Colors.transparent,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : isToday
                          ? Colors.white
                          : Colors.black87,
                ),
              ),
            ),
            if (dayItems.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (dayItems.length > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '+${dayItems.length}',
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelected ? Colors.white : const Color(0xFF0284C7),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ]
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthTable() {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final leadingOffset = firstDayOfMonth.weekday - 1; // Mon = 0, Sun = 6

    List<List<DateTime?>> weeks = [];
    List<DateTime?> currentWeek = [];

    for (int i = 0; i < leadingOffset; i++) {
      currentWeek.add(null);
    }

    for (int day = 1; day <= daysInMonth; day++) {
      currentWeek.add(DateTime(_focusedMonth.year, _focusedMonth.month, day));
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }

    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(null);
      }
      weeks.add(currentWeek);
    }

    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
        borderRadius: BorderRadius.circular(12),
      ),
      children: [
        // WEEKDAY HEADERS
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
          children: const [
            Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Center(child: Text('Lun', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))))),
            Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Center(child: Text('Mar', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))))),
            Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Center(child: Text('Mié', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))))),
            Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Center(child: Text('Jue', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))))),
            Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Center(child: Text('Vie', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))))),
            Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Center(child: Text('Sáb', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))))),
            Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Center(child: Text('Dom', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))))),
          ],
        ),
        // WEEK ROWS
        for (final week in weeks)
          TableRow(
            children: [
              for (final day in week)
                if (day == null)
                  Container(height: 52, color: const Color(0xFFF8FAFC))
                else
                  _buildDayCell(day),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayItems = _getItemsForDay(_selectedDay);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MONTH NAVIGATION HEADER
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: _previousMonth),
                      Text(
                        '${_monthsEs[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        icon: const Icon(Icons.today, size: 16),
                        label: const Text('Hoy'),
                        onPressed: _goToToday,
                      ),
                      const SizedBox(width: 4),
                      IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCalendar),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // FULL 7-COLUMN MONTHLY TABLE
          _isLoading
              ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMonthTable(),
                ),
          const SizedBox(height: 20),

          // SELECTED DAY MEDICATION LIST
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Medicamentos del ${_selectedDay.day} de ${_monthsEs[_selectedDay.month - 1]}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Chip(
                label: Text('${selectedDayItems.length} medicamentos'),
                backgroundColor: const Color(0xFFE0F2FE),
              ),
            ],
          ),
          const SizedBox(height: 8),

          selectedDayItems.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'No hay medicamentos programados para este día.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedDayItems.length,
                  itemBuilder: (ctx, idx) {
                    final item = selectedDayItems[idx];
                    final daySlots = _getIntakeSlotsForDay(item, _selectedDay);
                    final isActive = _isTreatmentActive(item);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () => _showMedicationDetailPopUp(item),
                        leading: CircleAvatar(
                          backgroundColor: isActive ? const Color(0xFFE0F2FE) : Colors.grey.shade200,
                          child: Icon(Icons.alarm, color: isActive ? const Color(0xFF0284C7) : Colors.grey.shade600),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.nombre,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? const Color(0xFF0F172A) : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFFE0F2FE) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'En curso' : 'Finalizado',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? const Color(0xFF0284C7) : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Horario(s) hoy: ${daySlots.isNotEmpty ? daySlots.join(", ") : item.horaInicio} (c/${item.frecuenciaHoras}h) • ${item.duracionDias} días',
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteItem(item),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
