import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/audit/data/audit_repository.dart';
import '../features/audit/domain/audit_log_model.dart';

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository();
});

final auditLogsStreamProvider = StreamProvider<List<AuditLogModel>>((ref) {
  final repo = ref.watch(auditRepositoryProvider);
  return repo.getAuditLogsStream();
});
