// Generic Exception
class RequestFailedAuthException implements Exception {}

class UnknownAuthException implements Exception {}

// Login Exception
class LoginIncorrectAuthException implements Exception {}

class UserNotLoggedInAuthException implements Exception {}

// Register Exception
class WeakPasswordAuthException implements Exception {}

class EmailAlreadyInUseAuthException implements Exception {}

class InvalidEmailAuthException implements Exception {}

// Forgot Password Exception
class UserNotFoundAuthException implements Exception {}
