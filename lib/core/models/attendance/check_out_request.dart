import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_out_request.freezed.dart';
part 'check_out_request.g.dart';

@freezed
class CheckOutRequest with _$CheckOutRequest {
  const factory CheckOutRequest({
    required String employeeId,
    DateTime? timestamp,
  }) = _CheckOutRequest;

  factory CheckOutRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckOutRequestFromJson(json);
}
