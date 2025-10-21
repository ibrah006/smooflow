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

extension on String {
  bool get isPrivateEmail {
    try {
      final domain = this.split('@').last.toLowerCase();
      return !_publicDomains.contains(domain);
    } catch (e) {
      return false; // invalid email
    }
  }
}
