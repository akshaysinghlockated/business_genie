import '../../../../core/network/json_reader.dart';
import '../../domain/entities/app_user.dart';

/// Converts [AppUser] to and from the API's JSON (`user` in verify and
/// GET /auth/me).
abstract final class AppUserModel {
  static AppUser fromJson(JsonMap json) {
    final firstName = json.readString('first_name');
    final lastName = json.readString('last_name');
    final joinedName = [firstName, lastName].where((part) => part.isNotEmpty).join(' ');
    return AppUser(
      id: json.readInt('id'),
      firstName: firstName,
      lastName: lastName,
      fullName: json.readString('full_name', joinedName),
      email: json.readString('email'),
      userType: json.readString('user_type'),
      role: json.readString('role'),
      organizationId: json.readIntOrNull('org_id'),
      departmentId: json.readIntOrNull('department_id'),
    );
  }

  static JsonMap toJson(AppUser user) => {
    'id': user.id,
    'first_name': user.firstName,
    'last_name': user.lastName,
    'full_name': user.fullName,
    'email': user.email,
    'user_type': user.userType,
    'role': user.role,
    'org_id': user.organizationId,
    'department_id': user.departmentId,
  };
}
