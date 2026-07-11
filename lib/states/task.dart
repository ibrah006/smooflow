import 'package:flutter/material.dart';
import 'package:smooflow/core/models/print_spec.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/enums/task_status.dart';

class TaskNameChangeEventUnderway {
  final int taskId;
  final String newName, oldName;
  final int localEventId;

  TaskNameChangeEventUnderway({
    required this.taskId,
    required this.oldName,
    required this.newName,
    required this.localEventId,
  });
}

class TaskFilter {
  final String? projectId;
  final int? assigneeId;
  final String? searchQuery;

  const TaskFilter({this.projectId, this.assigneeId, this.searchQuery});

  TaskFilter copyWith({
    String? projectId,
    int? assigneeId,
    String? searchQuery,
  }) {
    return TaskFilter(
      projectId: projectId ?? this.projectId,
      assigneeId: assigneeId ?? this.assigneeId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // CRITICAL: Value equality must be implemented so Riverpod knows
  // when two filter configurations are identical.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskFilter &&
          runtimeType == other.runtimeType &&
          projectId == other.projectId &&
          assigneeId == other.assigneeId &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => Object.hash(projectId, assigneeId, searchQuery);

  // Convenient empty state helper
  static const empty = TaskFilter();
}

class TaskState {
  List<Task> _tasks;

  List<Task> get tasks => _tasks;

  set tasks(List<Task> value) {
    _tasks = value;
  }

  bool _isLoading;

  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
  }

  String? _error;

  String? get error => _error;

  set error(String? value) {
    _error = value;
  }

  Task? _selectedTask;

  Task? get selectedTask => _selectedTask;

  set selectedTask(Task? value) {
    _selectedTask = value;
  }

  ConnectionStatus _connectionStatus;

  ConnectionStatus get connectionStatus => _connectionStatus;

  set connectionStatus(ConnectionStatus value) {
    _connectionStatus = value;
  }

  /// { print_spec_id: true/false } -> true means the spec has been deleted, false means it is being deleted
  Map<int, bool> _currentlyDeletingSpecs;

  Map<int, bool> get currentlyDeletingSpecs => _currentlyDeletingSpecs;

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

    // _currentlyDeletingSpecs.removeWhere((specId, isDeleted) {
    //   if (targetSpecIds.contains(specId) && isDeleted) {
    //     _tasks.firstWhere((task) => task.id == taskId);
    //     return true;
    //   }
    //   return false;
    // });
  }

  bool isCurrentlyDeletingSpec(int targetSpecId) {
    return _currentlyDeletingSpecs.containsKey(targetSpecId);
  }

  /// { taskId: creating print specs for this task }
  Map<int, List<CreatingPrintSpecID>> _currentlyCreatingSpecs;

  Map<int, List<CreatingPrintSpecID>> get currentlyCreatingSpecs =>
      _currentlyCreatingSpecs;

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

  TaskState({
    List<Task> tasks = const [],
    bool isLoading = false,
    String? error,
    Task? selectedTask,
    ConnectionStatus connectionStatus = ConnectionStatus.disconnected,
    Map<int, List<CreatingPrintSpecID>> currentlyCreatingSpecs = const {},
    Map<int, bool> currentlyDeletingSpecs = const {},
  }) : _error = error,
       _isLoading = isLoading,
       _tasks = tasks,
       _selectedTask = selectedTask,
       _connectionStatus = connectionStatus,
       _currentlyCreatingSpecs = currentlyCreatingSpecs,
       _currentlyDeletingSpecs = currentlyDeletingSpecs;

  final List<TaskNameChangeEventUnderway> _taskNameChangeEventsUnderway = [];

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
    try {
      _taskNameChangeEventsUnderway.firstWhere(
        (event) =>
            event.taskId == taskId && event.newName.trim() == newName.trim(),
      );

      return false;
    } catch (e) {
      return true;
    }
  }

  TaskState insert(int index, Task task) {
    _tasks.insert(index, task);

    return copyWith(tasks: _tasks);
  }

  TaskState add(Task task) {
    _tasks.add(task);

    return copyWith(tasks: _tasks);
  }

  TaskState updateTask(Task task) {
    _tasks.add(task);

    return copyWith(tasks: _tasks);
  }

  /// This function assumes as a task state update when a SINGLE new message comes in
  TaskState updateUnreadCount({
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

    final task = taskById(taskId);

    if (task != null) {
      final updatedTasks = _tasks.map((task) {
        if (task.id == taskId) {
          if (unreadCount != null) {
            task.unreadCount = unreadCount;
          } else if (incrementCount != null) {
            task.unreadCount += incrementCount;
          }

          task.messageCount += 1;
          task.lastMessageId = messageId;

          if (task.messageCount == 1) {
            // first message
            task.firstMessageId = messageId;
          }
        }
        return task;
      });

      return this.copyWith(tasks: updatedTasks.toList());
    }

    return this;
  }

  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    Task? newTask,
    Task? selectedTask,
    ConnectionStatus? connectionStatus,
    Map<int, List<CreatingPrintSpecID>>? currentlyCreatingSpecs,
    Map<int, bool>? currentlyDeletingSpecs,
  }) {
    final List<Task> ts = tasks ?? _tasks;
    // if (tasks != null) {
    //   // Adds the tasks to the existing list of tasks memory without any dusplicates

    //   final temp = _tasks.toSet();
    //   temp.addAll(tasks);

    //   ts = temp.toList();
    // } else {
    //   ts = _tasks;
    // }

    if (newTask != null) ts.add(newTask);

    return TaskState(
      tasks: ts,
      isLoading: isLoading ?? _isLoading,
      error: error,
      selectedTask: selectedTask,
      connectionStatus: connectionStatus ?? _connectionStatus,
      currentlyCreatingSpecs: Map<int, List<CreatingPrintSpecID>>.from(
        currentlyCreatingSpecs ?? _currentlyCreatingSpecs,
      ),
      currentlyDeletingSpecs: Map<int, bool>.from(
        currentlyDeletingSpecs ?? _currentlyDeletingSpecs,
      ),
    );
  }

  Task? taskById(int taskId) {
    try {
      return _tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }
}

class CreatingPrintSpecID {
  int tempLocalId;
  int? _createdId;

  CreatingPrintSpecID(this.tempLocalId);

  initializeId(int id) {
    _createdId = id;
  }

  int? get createdId => _createdId;
}
