enum RequestStatus {
  draft,
  submitted,
  pendingManagerApproval,
  pendingHrApproval,
  approved,
  rejected,
  cancelled;

  String get displayName {
    switch (this) {
      case RequestStatus.draft:
        return 'Draft';
      case RequestStatus.submitted:
        return 'Submitted';
      case RequestStatus.pendingManagerApproval:
        return 'Pending Manager Approval';
      case RequestStatus.pendingHrApproval:
        return 'Pending HR Approval';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get compactDisplayName {
    switch (this) {
      case RequestStatus.pendingManagerApproval:
        return 'Pending (Mgr)';
      case RequestStatus.pendingHrApproval:
        return 'Pending (HR)';
      default:
        return displayName;
    }
  }

  static RequestStatus fromString(String val) {
    return RequestStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => RequestStatus.pendingManagerApproval,
    );
  }
}
