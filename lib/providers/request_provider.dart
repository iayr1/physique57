import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/requests/data/firestore_request_repository.dart';
import '../features/requests/data/google_sheets_request_repository.dart';
import '../features/requests/data/mock_request_repository.dart';
import '../features/requests/data/request_repository.dart';
import '../features/requests/domain/request_category_model.dart';
import '../features/requests/domain/request_model.dart';
import '../features/requests/domain/request_status.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';
import 'theme_provider.dart';

final requestRepositoryProvider = Provider<IRequestRepository>((ref) {
  final backendType = ref.watch(backendTypeProvider);
  if (backendType == BackendType.firebase) {
    return FirestoreRequestRepository();
  } else if (backendType == BackendType.googleSheets) {
    return GoogleSheetsRequestRepository();
  }
  return MockRequestRepository();
});

class RequestsState {
  final List<RequestModel> requests;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final RequestStatus? statusFilter;
  final RequestType? typeFilter;

  const RequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter,
    this.typeFilter,
  });

  RequestsState copyWith({
    List<RequestModel>? requests,
    bool? isLoading,
    String? error,
    String? searchQuery,
    RequestStatus? statusFilter,
    RequestType? typeFilter,
    bool clearStatusFilter = false,
    bool clearTypeFilter = false,
  }) {
    return RequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
    );
  }

  // Filtered requests getter
  List<RequestModel> get filteredRequests {
    return requests.where((r) {
      if (statusFilter != null && r.status != statusFilter) {
        return false;
      }
      if (typeFilter != null && r.requestType != typeFilter) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesId = r.requestId.toLowerCase().contains(query);
        final matchesType = r.requestType.title.toLowerCase().contains(query);
        final matchesManager = r.managerEmail.toLowerCase().contains(query);
        return matchesId || matchesType || matchesManager;
      }
      return true;
    }).toList();
  }

  int get pendingCount => requests.where((r) => r.status == RequestStatus.pendingManagerApproval || r.status == RequestStatus.pendingHrApproval).length;
  int get approvedCount => requests.where((r) => r.status == RequestStatus.approved).length;
  int get rejectedCount => requests.where((r) => r.status == RequestStatus.rejected).length;
  int get totalCount => requests.length;
}

class RequestsNotifier extends StateNotifier<RequestsState> {
  final IRequestRepository _repository;
  final Ref _ref;

  RequestsNotifier(this._repository, this._ref) : super(const RequestsState()) {
    loadRequests();
  }

  Future<void> loadRequests() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = _ref.read(authProvider).value;
      final email = user?.email ?? 'alex.morgan@acmeglobal.com';
      final list = await _repository.getEmployeeRequests(email);
      state = state.copyWith(requests: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<RequestModel?> submitNewRequest(RequestModel newRequest) async {
    state = state.copyWith(isLoading: true);
    try {
      final created = await _repository.submitRequest(newRequest);
      
      // Update state with newly inserted unique request record
      final updatedList = [created, ...state.requests];
      state = state.copyWith(requests: updatedList, isLoading: false);

      // Trigger automatic push/in-app notification trigger!
      _ref.read(notificationProvider.notifier).notifySubmission(created);

      return created;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    final success = await _repository.cancelRequest(requestId);
    if (success) {
      await loadRequests();
    }
    return success;
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(RequestStatus? status) {
    if (status == null) {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
  }

  void setTypeFilter(RequestType? type) {
    if (type == null) {
      state = state.copyWith(clearTypeFilter: true);
    } else {
      state = state.copyWith(typeFilter: type);
    }
  }
}

final requestsProvider = StateNotifierProvider<RequestsNotifier, RequestsState>((ref) {
  final repo = ref.watch(requestRepositoryProvider);
  return RequestsNotifier(repo, ref);
});
