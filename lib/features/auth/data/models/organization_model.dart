import '../../../../core/network/json_reader.dart';
import '../../domain/entities/organization.dart';

/// Converts [Organization] to and from JSON (`organization` in GET /dashboard).
abstract final class OrganizationModel {
  static Organization fromJson(JsonMap json) => Organization(
    name: json.readString('organization_name'),
    industry: json.readString('industry'),
    location: json.readString('location'),
  );

  static JsonMap toJson(Organization organization) => {
    'organization_name': organization.name,
    'industry': organization.industry,
    'location': organization.location,
  };
}
