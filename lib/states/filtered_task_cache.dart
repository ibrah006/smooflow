// The state model now represents data bound strictly to this filter set
import 'package:flutter/widgets.dart';
import 'package:smooflow/change_events/task_change_event.dart';
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
    ConnectionStatus connectionStatus = ConnectionStatus.disconnected,
    Task? selectedTask,
  }) : _taskNameChangeEventsUnderway = taskNameChangeEventsUnderway,
       _currentlyCreatingSpecs = currentlyCreatingSpecs,
       _currentlyDeletingSpecs = const {},
       _connectionStatus = connectionStatus,
       _selectedTask = selectedTask;

  const FilteredTaskCacheState.empty()
    : totalCounts = const {},
      cachedTasks = const {},
      isLoadingCounts = false,
      _taskNameChangeEventsUnderway = const [],
      _currentlyCreatingSpecs = const {},
      _currentlyDeletingSpecs = const {},
      _connectionStatus = ConnectionStatus.disconnected,
      _selectedTask = null;

  final List<TaskNameChangeEventUnderway> _taskNameChangeEventsUnderway;

  /// { taskId: creating print specs for this task }
  final Map<int, List<CreatingPrintSpecID>> _currentlyCreatingSpecs;

  /// { print_spec_id: true/false } -> true means the spec has been deleted, false means it is being deleted
  final Map<int, bool> _currentlyDeletingSpecs;
  Map<int, bool> get currentlyDeletingSpecs => _currentlyDeletingSpecs;

  final ConnectionStatus _connectionStatus;
  ConnectionStatus get connectionStatus => _connectionStatus;

  final Task? _selectedTask;
  Task? get selectedTask => _selectedTask;

  FilteredTaskCacheState copyWith({
    Map<TaskStatus, Map<int, int>>? totalCounts,
    Map<TaskStatus, Map<int, Task>>? cachedTasks,
    bool? isLoadingCounts,
    List<TaskNameChangeEventUnderway>? taskNameChangeEventsUnderway,
    Map<int, List<CreatingPrintSpecID>>? currentlyCreatingSpecs = const {},
    ConnectionStatus? connectionStatus,
  }) {
    return FilteredTaskCacheState(
      totalCounts: totalCounts ?? this.totalCounts,
      cachedTasks: cachedTasks ?? this.cachedTasks,
      isLoadingCounts: isLoadingCounts ?? this.isLoadingCounts,
      taskNameChangeEventsUnderway:
          taskNameChangeEventsUnderway ?? _taskNameChangeEventsUnderway,
      currentlyCreatingSpecs: currentlyCreatingSpecs ?? _currentlyCreatingSpecs,
      connectionStatus: connectionStatus ?? _connectionStatus,
    );
  }

  void initializeCurrentlyCreatingSpec(
    int taskId,
    int specLocalId,
    int specCreatedId,
  ) {
    _currentlyCreatingSpecs[taskId] =
        _currentlyCreatingSpecs[taskId]?.map((spec) {
          if (spec.tempLocalId == specLocalId) {
            spec.initializeId(specCreatedId);
          }

          return spec;
        }).toList() ??
        [];
  }

  /// ---- Get Local State ----

  TaskStatus getLocalTaskStatus(int taskId) {
    try {
      final task = cachedTasks.values
          .expand((statusMap) => statusMap.values)
          .firstWhere((task) => task.id == taskId);

      return task.status;
    } catch (e) {
      throw "Task with ID $taskId not found in memory";
    }
  }

  Task? getLocalTask(int taskId) {
    try {
      final task = cachedTasks.values
          .expand((statusMap) => statusMap.values)
          .firstWhere((task) => task.id == taskId);

      return task;
    } catch (e) {
      throw "Task with ID $taskId not found in memory";
    }
  }

  /// ---- Task Name change ----

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

  /// ---- Task Messages State management  ----

  // This function assumes as a task state update when a SINGLE new message comes in
  FilteredTaskCacheState updateUnreadCount({
    required int taskId,
    required int messageId,
    int? unreadCount,
    int? incrementCount,
  }) {
    if (unreadCount == null && incrementCount == null) {
      debugPrint(
        "EITHER unreadCount OR incrementCount MUST BE PROVIDED to update the unread count of a task",
      );
      return this;
    }

    // DEBUG
    if (incrementCount != null) {
      print("[TaskState] called to increment unread count by $incrementCount");
    } else {
      print("[TaskState] called to update unread count to $unreadCount");
    }

    final task = getLocalTask(taskId);

    if (task != null) {
      getLocalTask(taskId)!
        ..unreadCount = unreadCount ?? task.unreadCount + (incrementCount ?? 0)
        ..messageCount += 1
        ..lastMessageId = messageId
        // TODO: Might have to check this
        ..firstMessageId ??= messageId;
    }

    return this;
  }
}
