enum TaskStatus {
  pending,
  designing,
  waitingApproval,
  clientApproved,
  waitingPrinting,
  printing,
  printingCompleted,
  finishing,
  productionCompleted,
  waitingDelivery,
  delivery,
  delivered,
  waitingInstallation,
  installing,
  completed, // installation complete
  // Other states
  blocked,
  paused,
  revision;

  TaskStatus? get nextStage {
    switch (this) {
      case TaskStatus.pending:
        return TaskStatus.designing;
      case TaskStatus.designing:
        return TaskStatus.waitingApproval;
      case TaskStatus.waitingApproval:
        return TaskStatus.clientApproved;
      case TaskStatus.clientApproved:
        return TaskStatus.waitingPrinting;
      case TaskStatus.waitingPrinting:
        return TaskStatus.printing;
      case TaskStatus.printing:
        return TaskStatus.printingCompleted;
      case TaskStatus.printingCompleted:
        return TaskStatus.finishing;
      case TaskStatus.finishing:
        return TaskStatus.productionCompleted;
      case TaskStatus.productionCompleted:
        return TaskStatus.waitingDelivery;
      case TaskStatus.waitingDelivery:
        return TaskStatus.delivery;
      case TaskStatus.delivery:
        return TaskStatus.delivered;
      case TaskStatus.delivered:
        return TaskStatus.waitingInstallation;
      case TaskStatus.waitingInstallation:
        return TaskStatus.installing;
      case TaskStatus.installing:
        return TaskStatus.completed;
      // ---- Other States ---- //
      case TaskStatus.revision:
        return TaskStatus.designing;
      // "No explicit next stage from beloe stages, should be set manually"
      
      // case TaskStatus.clientApproved:
      //   return null;
      case TaskStatus.paused:
        return null;
      case TaskStatus.blocked:
        return null;
      case TaskStatus.completed:
        return null;
    }
  }
}