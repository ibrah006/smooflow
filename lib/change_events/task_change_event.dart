import 'dart:async';
import 'package:smooflow/core/models/task.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Task change event types
enum TaskChangeType {
  created,
  updated,
  deleted,
  statusChanged,
  assigneeAdded,
  assigneeRemoved,
}

/// Task change event
class TaskChangeEvent {
  final TaskChangeType type;
  final int taskId;
  final Task? task;
  final String? changedBy;
  final DateTime timestamp;
  final Map<String, dynamic>? changes;

  TaskChangeEvent({
    required this.type,
    required this.taskId,
    this.task,
    this.changedBy,
    required this.timestamp,
    this.changes,
  });

  factory TaskChangeEvent.fromJson(Map<String, dynamic> json) {
    TaskChangeType getType(String typeStr) {
      switch (typeStr) {
        case 'created':
          return TaskChangeType.created;
        case 'updated':
          return TaskChangeType.updated;
        case 'deleted':
          return TaskChangeType.deleted;
        case 'status_changed':
          return TaskChangeType.statusChanged;
        case 'assignee_added':
          return TaskChangeType.assigneeAdded;
        case 'assignee_removed':
          return TaskChangeType.assigneeRemoved;
        default:
          return TaskChangeType.updated;
      }
    }

    return TaskChangeEvent(
      type: getType(json['type'] as String),
      taskId: json['taskId'] as int,
      task: json['task'] != null ? Task.fromJson(json['task']) : null,
      changedBy: json['changedBy'] as String?,
      timestamp: DateTime.parse(json['timestamp']),
      changes: json['changes'] as Map<String, dynamic>?,
    );
  }
}

/// WebSocket connection status
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Task WebSocket Client
class TaskWebSocketClient {
  final String authToken;
  final String baseUrl;
  IO.Socket? _socket;

  // Status streams
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  final _taskChangeController = StreamController<TaskChangeEvent>.broadcast();
  final _taskListController = StreamController<List<Task>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // State
  ConnectionStatus _status = ConnectionStatus.disconnected;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Set<int> _subscribedTasks = {};

  TaskWebSocketClient({
    required this.authToken,
    required this.baseUrl,
  });

  // Getters for streams
  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<TaskChangeEvent> get taskChanges => _taskChangeController.stream;
  Stream<List<Task>> get taskList => _taskListController.stream;
  Stream<String> get errors => _errorController.stream;

  ConnectionStatus get status => _status;
  bool get isConnected => _status == ConnectionStatus.connected;

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _updateStatus(ConnectionStatus.connecting);

    try {
      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setPath('/ws/tasks')
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': authToken})
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(_maxReconnectAttempts)
            .build(),
      );

      _setupEventHandlers();
      _socket!.connect();
    } catch (e) {
      _updateStatus(ConnectionStatus.error);
      _errorController.add('Connection failed: $e');
      rethrow;
    }
  }

  /// Setup WebSocket event handlers
  void _setupEventHandlers() {
    if (_socket == null) return;

    // Connection established
    _socket!.on('connected', (data) {
      print('WebSocket connected: $data');
      _reconnectAttempts = 0;
      _updateStatus(ConnectionStatus.connected);

      // Re-subscribe to tasks after reconnection
      for (final taskId in _subscribedTasks) {
        subscribeToTask(taskId);
      }
    });

    // Connection error
    _socket!.on('connect_error', (error) {
      print('WebSocket connection error: $error');
      _reconnectAttempts++;
      
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        _updateStatus(ConnectionStatus.error);
        _errorController.add('Failed to connect after $_maxReconnectAttempts attempts');
      } else {
        _updateStatus(ConnectionStatus.reconnecting);
      }
    });

    // Disconnected
    _socket!.on('disconnect', (reason) {
      print('WebSocket disconnected: $reason');
      _updateStatus(ConnectionStatus.disconnected);
    });

    // Reconnected
    _socket!.on('reconnect', (attemptNumber) {
      print('WebSocket reconnected after $attemptNumber attempts');
      _reconnectAttempts = 0;
      _updateStatus(ConnectionStatus.connected);
    });

    // Task change events
    _socket!.on('task:changed', (data) {
      try {
        final event = TaskChangeEvent.fromJson(data as Map<String, dynamic>);
        _taskChangeController.add(event);
      } catch (e) {
        print('Error parsing task:changed event: $e');
      }
    });

    _socket!.on('task:updated', (data) {
      try {
        final event = TaskChangeEvent.fromJson(data as Map<String, dynamic>);
        _taskChangeController.add(event);
      } catch (e) {
        print('Error parsing task:updated event: $e');
      }
    });

    // Task list response
    _socket!.on('tasks:list', (data) {
      try {
        final response = data as Map<String, dynamic>;
        final tasksJson = response['tasks'] as List;
        final tasks = tasksJson
            .map((json) => Task.fromJson(json as Map<String, dynamic>))
            .toList();
        _taskListController.add(tasks);
      } catch (e) {
        print('Error parsing tasks:list: $e');
        _errorController.add('Failed to parse task list: $e');
      }
    });

    // Single task data
    _socket!.on('task:data', (data) {
      try {
        final response = data as Map<String, dynamic>;
        final task = Task.fromJson(response['task']);
        // Emit as single-item list or create separate stream if needed
        _taskListController.add([task]);
      } catch (e) {
        print('Error parsing task:data: $e');
      }
    });

    // Error events
    _socket!.on('error', (data) {
      final errorMsg = data['message'] ?? 'Unknown error';
      _errorController.add(errorMsg);
    });

    // User presence
    _socket!.on('user:connected', (data) {
      print('User connected: ${data['userId']}');
    });

    _socket!.on('user:disconnected', (data) {
      print('User disconnected: ${data['userId']}');
    });
  }

  /// Update connection status
  void _updateStatus(ConnectionStatus status) {
    _status = status;
    _connectionStatusController.add(status);
  }

  /// Subscribe to a specific task
  void subscribeToTask(int taskId) {
    _ensureConnected();
    _subscribedTasks.add(taskId);
    _socket!.emit('task:subscribe', taskId);
  }

  /// Unsubscribe from a specific task
  void unsubscribeFromTask(int taskId) {
    _ensureConnected();
    _subscribedTasks.remove(taskId);
    _socket!.emit('task:unsubscribe', taskId);
  }

  /// Request current task data
  void getTask(int taskId) {
    _ensureConnected();
    _socket!.emit('task:get', taskId);
  }

  /// Request list of all tasks
  void listTasks({Map<String, dynamic>? filters}) {
    _ensureConnected();
    _socket!.emit('tasks:list', filters);
  }

  /// Refresh tasks list
  void refreshTasks() {
    _ensureConnected();
    _socket!.emit('tasks:refresh');
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _subscribedTasks.clear();
    _updateStatus(ConnectionStatus.disconnected);
  }

  /// Ensure socket is connected
  void _ensureConnected() {
    if (_socket == null || !_socket!.connected) {
      throw StateError('WebSocket is not connected. Call connect() first.');
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _connectionStatusController.close();
    _taskChangeController.close();
    _taskListController.close();
    _errorController.close();
  }
}