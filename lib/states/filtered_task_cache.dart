// The state model now represents data bound strictly to this filter set
import 'package:smooflow/core/models/print_spec.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/states/task.dart';

class FilteredTaskCacheState {
  final Map<TaskStatus, Map<int, int>> totalCounts;
  final Map<TaskStatus, Map<int, Task>> cachedTasks;
  final bool isLoadingCounts;

  FilteredTaskCacheState({
    required this.totalCounts,
    required this.cachedTasks,
    this.isLoadingCounts = false,
    List<TaskNameChangeEventUnderway> taskNameChangeEventsUnderway = const [],
    Map<int, List<CreatingPrintSpecID>> currentlyCreatingSpecs = const {},
  }) : _taskNameChangeEventsUnderway = taskNameChangeEventsUnderway,
       _currentlyCreatingSpecs = currentlyCreatingSpecs,
       _currentlyDeletingSpecs = const {};

  const FilteredTaskCacheState.empty()
    : totalCounts = const {},
      cachedTasks = const {},
      isLoadingCounts = false,
      _taskNameChangeEventsUnderway = const [],
      _currentlyCreatingSpecs = const {},
      _currentlyDeletingSpecs = const {};

  final List<TaskNameChangeEventUnderway> _taskNameChangeEventsUnderway;

  /// { taskId: creating print specs for this task }
  final Map<int, List<CreatingPrintSpecID>> _currentlyCreatingSpecs;

  /// { print_spec_id: true/false } -> true means the spec has been deleted, false means it is being deleted
  final Map<int, bool> _currentlyDeletingSpecs;

  Map<int, bool> get currentlyDeletingSpecs => _currentlyDeletingSpecs;

  FilteredTaskCacheState copyWith({
    Map<TaskStatus, Map<int, int>>? totalCounts,
    Map<TaskStatus, Map<int, Task>>? cachedTasks,
    bool? isLoadingCounts,
  }) {
    return FilteredTaskCacheState(
      totalCounts: totalCounts ?? this.totalCounts,
      cachedTasks: cachedTasks ?? this.cachedTasks,
      isLoadingCounts: isLoadingCounts ?? this.isLoadingCounts,
    );
  }

  /// @returns the local event id
  int newNameChangeEvent({
    required int taskId,
    required String oldName,
    required String newName,
  }) {
    final event = TaskNameChangeEventUnderway(
      taskId: taskId,
      oldName: oldName,
      newName: newName,
      localEventId: _taskNameChangeEventsUnderway.length + 1,
    );
    _taskNameChangeEventsUnderway.add(event);

    return event.localEventId;
  }

  void removeTaskNameChangeEvent(int localEventId) {
    _taskNameChangeEventsUnderway.removeWhere(
      (event) => event.localEventId == localEventId,
    );
  }

  bool canUpdateName({required int taskId, required String newName}) {
    return cachedTasks.values
        .expand((statusMap) => statusMap.values)
        .where((task) => task.id != taskId)
        .every((task) => task.name != newName);
  }

  /// ---- Currently Creating Specs ----

  void addCurrentlyCreatingSpec(int taskId, int specLocalId) {
    _currentlyCreatingSpecs[taskId] = [
      ..._currentlyCreatingSpecs[taskId] ?? [],
      // here newPrintSpec.id automatically returns temp local id
      CreatingPrintSpecID(specLocalId),
    ];
  }

  void removeCurrentlyCreatingSpec(int taskId, int specCreatedId) {
    _currentlyCreatingSpecs[taskId]?.removeWhere(
      (spec) => spec.createdId == specCreatedId,
    );
  }

  bool isCurrentlyCreatingSpec(int taskId, int specLocalId) {
    return _currentlyCreatingSpecs[taskId]?.any(
          (spec) => spec.tempLocalId == specLocalId,
        ) ??
        false;
  }

  /// ---- Currently Deleting Specs ----

  void addCurrentlyDeletingSpec(int targetSpecId) {
    _currentlyDeletingSpecs[targetSpecId] = false;
  }

  /// function of _currentlyDeletingSpecs
  void specDeleted(int targetSpecId) {
    _currentlyDeletingSpecs[targetSpecId] = true;
  }

  void removeCurrentlyDeletingSpec({
    required List<PrintSpec> targetSpecs,
    Function(int printSpecIndex)? onRemove,
  }) {
    final targetSpecIds = targetSpecs.map((spec) => spec.id).toList();

    for (MapEntry<int, bool> _currentlyDeletingSpec
        in _currentlyDeletingSpecs.entries) {
      for (int i = 0; i < targetSpecIds.length; i++) {
        final specId = targetSpecIds[i];
        if (_currentlyDeletingSpec.key == specId &&
            // if the spec has already been deleted as well
            _currentlyDeletingSpec.value == true) {
          _currentlyDeletingSpecs.remove(specId);

          targetSpecs.removeAt(i);

          onRemove?.call(i);
        }
      }
    }
  }
}
