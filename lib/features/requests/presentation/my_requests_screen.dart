import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/request_provider.dart';
import '../domain/request_status.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final notifier = ref.read(requestsProvider.notifier);
      switch (_tabController.index) {
        case 0:
          notifier.setStatusFilter(null);
          break;
        case 1:
          notifier.setStatusFilter(RequestStatus.pendingManagerApproval);
          break;
        case 2:
          notifier.setStatusFilter(RequestStatus.approved);
          break;
        case 3:
          notifier.setStatusFilter(RequestStatus.rejected);
          break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
        elevation: 0,
        title: Text(
          'My Requests',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: isDark ? Colors.white : AppColors.neoBorder,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 2.5),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.all(3),
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              indicator: BoxDecoration(
                color: AppColors.neoYellow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.neoBorder, width: 2),
              ),
              labelColor: AppColors.neoBorder,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12.5),
              unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12.5),
              tabs: const [
                Tab(text: 'All Requests'),
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Category Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: borderColor,
                    offset: const Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(requestsProvider.notifier).setSearchQuery(val);
                },
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.neoBorder,
                ),
                decoration: InputDecoration(
                  hintText: 'Search Request ID, type, or reason...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? AppColors.neoYellow : AppColors.neoIndigo,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: isDark ? Colors.white : AppColors.neoBorder),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(requestsProvider.notifier).setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor, width: 2.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor, width: 2.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.neoYellow : AppColors.neoIndigo,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main Request List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(requestsProvider.notifier).loadRequests(),
              child: state.filteredRequests.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No requests found',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.neoBorder,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Submit a new request to see it listed here.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: state.filteredRequests.length,
                      itemBuilder: (context, index) {
                        final request = state.filteredRequests[index];
                        final isPending = request.status == RequestStatus.pendingManagerApproval ||
                            request.status == RequestStatus.pendingHrApproval;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: borderColor,
                                offset: const Offset(4, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.push('/requests/${request.requestId}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.neoCyan,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: borderColor, width: 2),
                                              ),
                                              child: Icon(
                                                request.requestType.icon,
                                                size: 18,
                                                color: AppColors.neoBorder,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                request.requestId,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                  color: isDark ? Colors.white : AppColors.neoBorder,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusBadge(status: request.status, compact: true),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    request.requestType.title,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : AppColors.neoBorder,
                                    ),
                                  ),
                                  if (request.summaryText.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      request.summaryText,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Submitted ${DateFormatter.formatDateTime(request.submittedAt)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                      if (isPending)
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            foregroundColor: AppColors.statusRejected,
                                          ),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  side: BorderSide(color: borderColor, width: 2.5),
                                                ),
                                                title: Text(
                                                  'Cancel Request?',
                                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
                                                ),
                                                content: Text(
                                                  'Are you sure you want to cancel this pending request?',
                                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: Text(
                                                      'No',
                                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppColors.statusRejected,
                                                    ),
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    child: Text(
                                                      'Yes, Cancel',
                                                      style: GoogleFonts.outfit(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              await ref.read(requestsProvider.notifier).cancelRequest(request.requestId);
                                            }
                                          },
                                          child: Text(
                                            'Cancel',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.statusRejected,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
