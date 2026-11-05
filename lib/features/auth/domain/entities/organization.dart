/// The company the person signed in to.
class Organization {
  const Organization({required this.name, this.industry = '', this.location = ''});

  final String name;
  final String industry;
  final String location;
}
