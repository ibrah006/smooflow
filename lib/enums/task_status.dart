enum TaskStatus {
  pending,
  designing,
  printing,
  finishing,
  installing,
  delivery,
  completed,
  blocked,
  paused,
  waitingApproval,
  clientApproved,
  revision;

  TaskStatus? get nextStage {
    switch (this) {
      case TaskStatus.pending:
        return TaskStatus.designing;
      case TaskStatus.designing:
        return TaskStatus.waitingApproval;
      case TaskStatus.printing:
        return TaskStatus.finishing;
      case TaskStatus.finishing:
        return TaskStatus.delivery;
      case TaskStatus.delivery:
        return TaskStatus.installing;
      case TaskStatus.installing:
        return TaskStatus.completed;
      case TaskStatus.waitingApproval:
        return TaskStatus.clientApproved;
      // "No explicit next stage from beloe stages, should be set manually"
      case TaskStatus.revision:
        return TaskStatus.designing;
      case TaskStatus.clientApproved:
        return null;
      case TaskStatus.paused:
        return null;
      case TaskStatus.blocked:
        return null;
      case TaskStatus.completed:
        return null;
    }
  }
}

/// New statuses to consider
// revision, waitingApproval, clientApproved