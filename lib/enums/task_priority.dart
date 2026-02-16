enum TaskPriority {
  normal(1),
  high(2),
  urgent(3);

  final int weight;
  const TaskPriority(this.weight);

  int compareTo(TaskPriority other) {
    return weight.compareTo(other.weight);
  }
}