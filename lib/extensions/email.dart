final _publicDomains = {
  'gmail.com',
  'yahoo.com',
  'hotmail.com',
  'outlook.com',
  'aol.com',
  'icloud.com',
  'live.com',
  'msn.com',
  'mail.com',
  'protonmail.com',
  'zoho.com',
  'gmx.com',
};

extension EmailStringExtension on String {
  bool get isPrivateEmail {
    try {
      final domain = this.split('@').last.toLowerCase();
      return !_publicDomains.contains(domain);
    } catch (e) {
      return false; // invalid email
    }
  }

  bool get isEmail {
    final parts = this.split('@');
    if (parts.length != 2) return false;

    return true;
  }

  String? get getEmailDomain {
    if (!this.isEmail) {
      return null;
    }

    final parts = this.split('@');

    return parts[1].toLowerCase();
  }
}
