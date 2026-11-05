/// The answer to "email me a sign-in code".
class CodeRequest {
  const CodeRequest({required this.sentTo, required this.note});

  /// The address the code went to.
  final String sentTo;

  /// The backend's sentence about the code ("It works for ten minutes…").
  final String note;
}
