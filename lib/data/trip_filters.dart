/// User-configurable trip filters. Only the settings live here: the trip is
/// parsed and judged natively in TripParser.kt / TripEvaluator.kt, which use
/// the same filter names (`FilterKind.name`).
enum FilterKind {
  perHour(defaultValue: 150, min: 50, max: 500, step: 10),
  perKm(defaultValue: 8, min: 2, max: 30, step: 0.5),
  maxPickupKm(defaultValue: 3, min: 0.5, max: 10, step: 0.5);

  const FilterKind({
    required this.defaultValue,
    required this.min,
    required this.max,
    required this.step,
  });

  final double defaultValue;
  final double min;
  final double max;
  final double step;
}

class TripFilter {
  const TripFilter({
    required this.kind,
    required this.enabled,
    required this.value,
  });

  final FilterKind kind;
  final bool enabled;
  final double value;

  TripFilter copyWith({bool? enabled, double? value}) => TripFilter(
    kind: kind,
    enabled: enabled ?? this.enabled,
    value: value ?? this.value,
  );
}
