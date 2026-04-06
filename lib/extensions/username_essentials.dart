extension UsernameEssentials on String {
  String get initials {
    final splitted = this.split(" ");

    String result = "";

    while (splitted.isNotEmpty && result.length < 4) {
      result += splitted[0][0].toUpperCase();
      splitted.removeAt(0);
    }

    return result;
  }
}
