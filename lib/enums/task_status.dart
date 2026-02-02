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

  TaskStatus get nextStage {
    switch (this) {
      case TaskStatus.pending:
        return TaskStatus.designing;
      case TaskStatus.designing:
        return TaskStatus.printing;
      case TaskStatus.printing:
        return TaskStatus.finishing;
      case TaskStatus.delivery:
        return TaskStatus.delivery;
      case TaskStatus.finishing:
        return TaskStatus.installing;
      case TaskStatus.installing:
        return TaskStatus.waitingApproval;
      case TaskStatus.waitingApproval:
        return TaskStatus.clientApproved;
      case TaskStatus.clientApproved:
        throw "No explicit next stage from Client Approved, should be set manually";
      case TaskStatus.paused:
        throw "No explicit next stage from Pause State, should be set manually"; // No next status from paused
      case TaskStatus.revision:
        return TaskStatus.designing;
      case TaskStatus.blocked:
        throw "No explicit next stage from Blocked State, should be set manually"; // No next status from blocked
      case TaskStatus.completed:
        throw "No next stage from Completed State"; // No next status from completed
    }
  }
}

/// New statuses to consider
// revision, waitingApproval, clientApproved