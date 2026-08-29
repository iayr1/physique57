import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/request_category_model.dart';
import 'controllers/categories_controller.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;
    final query = ref.watch(categorySearchQueryProvider);
    final filtered = RequestType.values.where((t) {
      if (query.isEmpty) return true;
      return t.title.toLowerCase().contains(query) || t.description.toLowerCase().contains(query);
    }).toList();

    final List<Color> popColors = [
      AppColors.neoYellow,
      AppColors.neoCyan,
      AppColors.neoPink,
      AppColors.neoGreen,
      AppColors.neoPurple,
      AppColors.neoOrange,
      AppColors.neoIndigo,
      AppColors.neoYellow,
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
        elevation: 0,
        title: Text(
          'Submit New Request',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: isDark ? Colors.white : AppColors.neoBorder,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Search Bar
          Container(
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
              controller: _searchCtrl,
              onChanged: (v) => ref.read(categorySearchQueryProvider.notifier).state = v.trim().toLowerCase(),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.neoBorder,
              ),
              decoration: InputDecoration(
                hintText: 'Search request category (e.g. Leave, IT, Travel)...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? AppColors.neoYellow : AppColors.neoIndigo,
                ),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: isDark ? Colors.white : AppColors.neoBorder),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(categorySearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          const SizedBox(height: 22),

          Text(
            'All Request Categories',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.textPrimaryDark : AppColors.neoBorder,
            ),
          ),
          const SizedBox(height: 12),

          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No categories match "$query"',
                  style: GoogleFonts.outfit(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ...filtered.asMap().entries.map((entry) {
              final idx = entry.key;
              final type = entry.value;
              final popColor = popColors[idx % popColors.length];

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
                  onTap: () {
                    switch (type) {
                      case RequestType.leave:
                        context.push('/forms/leave');
                        break;
                      case RequestType.expense:
                        context.push('/forms/expense');
                        break;
                      case RequestType.itSupport:
                        context.push('/forms/it');
                        break;
                      case RequestType.attendance:
                        context.push('/forms/attendance');
                        break;
                      case RequestType.workFromHome:
                        context.push('/forms/wfh');
                        break;
                      case RequestType.hrRequest:
                        context.push('/forms/hr');
                        break;
                      case RequestType.travel:
                        context.push('/forms/travel');
                        break;
                      case RequestType.other:
                        context.push('/forms/generic');
                        break;
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: popColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Icon(
                            type.icon,
                            color: AppColors.neoBorder,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.neoBorder,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                type.description,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: popColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.neoBorder,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
