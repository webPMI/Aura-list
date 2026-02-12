import 'package:hive/hive.dart';

part 'notebook_model.g.dart';

@HiveType(typeId: 6)
class Notebook extends HiveObject {
  @HiveField(0)
  late String firestoreId;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String icon; // Emoji o icon name

  @HiveField(3)
  late String color; // Hex color

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  late DateTime updatedAt;

  @HiveField(6)
  late bool isFavorited;

  @HiveField(7)
  String? parentId; // Para notebooks anidados (opcional)

  Notebook({
    this.firestoreId = '',
    required this.name,
    this.icon = '📁',
    this.color = '#6750A4',
    required this.createdAt,
    DateTime? updatedAt,
    this.isFavorited = false,
    this.parentId,
  }) : updatedAt = updatedAt ?? createdAt;

  int get id => key ?? 0;

  Notebook copyWith({
    String? firestoreId,
    String? name,
    String? icon,
    String? color,
    DateTime? updatedAt,
    bool? isFavorited,
    String? parentId,
    bool clearParentId = false,
  }) {
    return Notebook(
      firestoreId: firestoreId ?? this.firestoreId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isFavorited: isFavorited ?? this.isFavorited,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorited': isFavorited,
      'parentId': parentId,
    };
  }

  factory Notebook.fromFirestore(String id, Map<String, dynamic> data) {
    return Notebook(
      firestoreId: id,
      name: data['name'] ?? 'Sin nombre',
      icon: data['icon'] ?? '📁',
      color: data['color'] ?? '#6750A4',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
      isFavorited: data['isFavorited'] ?? false,
      parentId: data['parentId'],
    );
  }

  /// Actualiza los campos in-place cuando el objeto esta en Hive.
  /// Usar este metodo para modificar un objeto que ya esta guardado.
  void updateInPlace({
    String? firestoreId,
    String? name,
    String? icon,
    String? color,
    DateTime? updatedAt,
    bool? isFavorited,
    String? parentId,
    bool clearParentId = false,
  }) {
    if (firestoreId != null) this.firestoreId = firestoreId;
    if (name != null) this.name = name;
    if (icon != null) this.icon = icon;
    if (color != null) this.color = color;
    this.updatedAt = updatedAt ?? DateTime.now();
    if (isFavorited != null) this.isFavorited = isFavorited;
    if (clearParentId) {
      this.parentId = null;
    } else if (parentId != null) {
      this.parentId = parentId;
    }
  }

  // Predefined icon options
  static const List<String> iconOptions = [
    '📁',
    '📋',
    '📝',
    '💼',
    '🏠',
    '💪',
    '🎯',
    '📚',
    '🎨',
    '🔬',
    '🎵',
    '🏃',
    '🍎',
    '💡',
    '🌟',
  ];

  // Predefined color options (Material Design)
  static const Map<String, String> colorOptions = {
    'Morado': '#6750A4',
    'Azul': '#1E88E5',
    'Verde': '#43A047',
    'Naranja': '#FB8C00',
    'Rojo': '#E53935',
    'Rosa': '#D81B60',
    'Cyan': '#00ACC1',
    'Marron': '#6D4C41',
    'Gris': '#757575',
  };

  // Get color name from hex
  static String getColorName(String hex) {
    for (final entry in colorOptions.entries) {
      if (entry.value == hex) return entry.key;
    }
    return 'Morado';
  }
}
