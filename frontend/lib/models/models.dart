class MedicamentoModel {
  final String idMedicamento;
  final String nombre;
  final String descripcion;
  final String efectosSecundarios;

  MedicamentoModel({
    required this.idMedicamento,
    required this.nombre,
    required this.descripcion,
    required this.efectosSecundarios,
  });

  factory MedicamentoModel.fromJson(Map<String, dynamic> json) {
    return MedicamentoModel(
      idMedicamento: json['IdMedicamento'] ?? '',
      nombre: json['Nombre'] ?? '',
      descripcion: json['Descripcion'] ?? '',
      efectosSecundarios: json['EfectosSecundarios'] ?? '',
    );
  }
}

class ItemCalendarioModel {
  final String idItemCalendario;
  final String idCalendario;
  final String? idDetalleReceta;
  final String idMedicamento;
  final String nombre;
  final String descripcion;
  final String efectosSecundarios;
  final int frecuenciaHoras;
  final int duracionDias;
  final String horaInicio;
  final DateTime? fechaInicio;
  final DateTime? fechaTermino;

  ItemCalendarioModel({
    required this.idItemCalendario,
    required this.idCalendario,
    this.idDetalleReceta,
    required this.idMedicamento,
    required this.nombre,
    required this.descripcion,
    required this.efectosSecundarios,
    required this.frecuenciaHoras,
    required this.duracionDias,
    required this.horaInicio,
    this.fechaInicio,
    this.fechaTermino,
  });

  factory ItemCalendarioModel.fromJson(Map<String, dynamic> json) {
    return ItemCalendarioModel(
      idItemCalendario: json['IdItemCalendario'] ?? '',
      idCalendario: json['IdCalendario'] ?? '',
      idDetalleReceta: json['IdDetalleReceta'],
      idMedicamento: json['IdMedicamento'] ?? '',
      nombre: json['Nombre'] ?? '',
      descripcion: json['Descripcion'] ?? '',
      efectosSecundarios: json['EfectosSecundarios'] ?? '',
      frecuenciaHoras: json['FrecuenciaHoras'] ?? 8,
      duracionDias: json['DuracionDias'] ?? 7,
      horaInicio: json['HoraInicio'] ?? '08:00',
      fechaInicio: json['FechaInicio'] != null ? DateTime.tryParse(json['FechaInicio']) : null,
      fechaTermino: json['FechaTermino'] != null ? DateTime.tryParse(json['FechaTermino']) : null,
    );
  }
}

class NotaModel {
  final String idNota;
  final String idPaciente;
  final String? idMedicamento;
  final String nombreMedicamento;
  final String descripcion;
  final String? fecha;

  NotaModel({
    required this.idNota,
    required this.idPaciente,
    this.idMedicamento,
    required this.nombreMedicamento,
    required this.descripcion,
    this.fecha,
  });

  factory NotaModel.fromJson(Map<String, dynamic> json) {
    return NotaModel(
      idNota: json['IdNota'] ?? '',
      idPaciente: json['IdPaciente'] ?? '',
      idMedicamento: json['IdMedicamento'],
      nombreMedicamento: json['NombreMedicamento'] ?? 'Ninguno específico',
      descripcion: json['Descripcion'] ?? '',
      fecha: json['Fecha'],
    );
  }
}
