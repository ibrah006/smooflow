class ProjectOverallStatus {
  int activeLength = 0;
  int pendingLength = 0;
  int finishedLength = 0;
  int countThisMonth = 0;
  int countLastMonth = 0;
  int increaseWRTPrevMonth = 0;

  set({
    required int activeLength,
    required int pendingLength,
    required int finishedLength,
    required int countThisMonth,
    required int countLastMonth,
    required int increaseWRTPrevMonth,
  }) {
    // set all attributes of the class from this function's parameters
    this.activeLength = activeLength;
    this.pendingLength = pendingLength;
    this.finishedLength = finishedLength;
    this.countThisMonth = countThisMonth;
    this.countLastMonth = countLastMonth;
    this.increaseWRTPrevMonth = increaseWRTPrevMonth;
  }
}