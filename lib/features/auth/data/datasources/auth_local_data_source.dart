import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/json_reader.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/app_user_model.dart';
import '../models/organization_model.dart';

/// What sign-in keeps on the phone. The token lives in secure storage; the
/// account summary (name, role, company) and the demo flag in preferences,
/// since they are not secret.
class AuthLocalDataSource {
  AuthLocalDataSource(this.tokenStorage);

  final TokenStorage tokenStorage;

  static const _accountKey = 'account.v1';
  static const _demoKey = 'demo.v1';
  static const _legacySignedInKey = 'signedIn.v1';

  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  Future<SavedAccount?> readAccount() async {
    final preferences = await _preferences;
    // The UI prototype kept a plain "signed in" flag; the token replaces it.
    await preferences.remove(_legacySignedInKey);
    final stored = preferences.getString(_accountKey);
    if (stored == null) return null;
    try {
      final json = (jsonDecode(stored) as Map).cast<String, dynamic>();
      final organizationJson = json.readMap('organization');
      return SavedAccount(
        user: AppUserModel.fromJson(json.readMap('user')),
        organization: organizationJson.isEmpty ? null : OrganizationModel.fromJson(organizationJson),
        isWorkspaceSetupPending: json.readBool('workspace_setup_pending'),
      );
    } on Object {
      await preferences.remove(_accountKey);
      return null;
    }
  }

  Future<void> saveAccount(SavedAccount account) async {
    final organization = account.organization;
    await (await _preferences).setString(
      _accountKey,
      jsonEncode({
        'user': AppUserModel.toJson(account.user),
        'organization': organization == null ? null : OrganizationModel.toJson(organization),
        'workspace_setup_pending': account.isWorkspaceSetupPending,
      }),
    );
  }

  Future<void> clearAccount() async => (await _preferences).remove(_accountKey);

  Future<bool> readIsDemo() async => (await _preferences).getBool(_demoKey) ?? false;

  Future<void> saveIsDemo(bool isDemo) async => (await _preferences).setBool(_demoKey, isDemo);
}
