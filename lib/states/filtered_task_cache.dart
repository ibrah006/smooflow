// The state model now represents data bound strictly to this filter set
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
       _currentlyCreatingSpecs = currentlyCreatingSpecs;

  const FilteredTaskCacheState.empty()
    : totalCounts = const {},
      cachedTasks = const {},
      isLoadingCounts = false,
      _taskNameChangeEventsUnderway = const [],
      _currentlyCreatingSpecs = const {};

  final List<TaskNameChangeEventUnderway> _taskNameChangeEventsUnderway;

  /// { taskId: creating print specs for this task }
  final Map<int, List<CreatingPrintSpecID>> _currentlyCreatingSpecs;

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

  bool canUpdateName({required int taskId, required String newName}) {
    return cachedTasks.values
        .expand((statusMap) => statusMap.values)
        .where((task) => task.id != taskId)
        .every((task) => task.name != newName);
  }

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
}
