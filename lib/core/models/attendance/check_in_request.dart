import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_in_request.freezed.dart';
part 'check_in_request.g.dart';

@freezed
abstract class CheckInRequest with _$CheckInRequest {
  const factory CheckInRequest({
    required String employeeId,
    DateTime? timestamp,
  }) = _CheckInRequest;

  factory CheckInRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckInRequestFromJson(json);
}
