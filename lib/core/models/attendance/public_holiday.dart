import 'package:freezed_annotation/freezed_annotation.dart';

part 'public_holiday.freezed.dart';
part 'public_holiday.g.dart';

@freezed
class PublicHoliday with _$PublicHoliday {
  const factory PublicHoliday({
    required String id,
    required String name,
    required DateTime date,
    String? region,
    @Default(true) bool isCompensated,
    String? description,
  }) = _PublicHoliday;

  factory PublicHoliday.fromJson(Map<String, dynamic> json) =>
      _$PublicHolidayFromJson(json);

  String get displayDate => '${date.month}/${date.day}/${date.year}';
}
