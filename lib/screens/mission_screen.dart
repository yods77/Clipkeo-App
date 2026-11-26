import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../services/mission_service.dart';
import '../widgets/app_background_scaffold.dart';

class MissionScreen extends StatefulWidget {
  final VoidCallback onBack;
  const MissionScreen({super.key, required this.onBack});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MissionService _missionService = MissionService();
  List<dynamic> _allMissions = [];
  bool _isLoading = true;

  final currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp. ', // Pakai titik sesuai request Anda
    decimalDigits: 0, // Hilangkan desimal (.00)
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMissions();

    // 👇 TAMBAHAN: Auto-Refresh saat ganti Tab
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Panggil refresh diam-diam (silent: true)
        _loadMissions(silent: true);
      }
    });
  }

  /**
   * -- LOAD MISSIONS (LOGIKA TETAP) --
   */
  Future<void> _loadMissions({bool silent = false}) async {
    // Kalau silent=true (lagi pindah tab), jangan nyalakan loading screen
    if (!silent) setState(() => _isLoading = true);

    final data = await _missionService.getMyMissions();

    if (!mounted) return;
    setState(() {
      _allMissions = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBackgroundScaffold(
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                /** 2. HEADER CENTERED (UPDATED) **/
                _buildCenteredAppBar(),

                SizedBox(height: 15.h),

                /** 3. DARK FLOATING TABS (UPDATED) **/
                _buildDarkEliteTabBar(),

                /** 4. CONTENT LIST (CARD TETAP DARK) **/
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFC8FF00),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMissionList("pending"),
                            _buildMissionList("approved"),
                            _buildMissionList("rejected"),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredAppBar() {
    final double spacerWidth = 45.w;

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Penyeimbang Kiri (Kotak Kosong)
          SizedBox(width: spacerWidth),

          // 2. Judul di Tengah
          Text(
            "Misi Saya",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 18.sp,
            ),
          ),

          // 3. Penyeimbang Kanan (Menggantikan tombol refresh agar tetap simetris)
          SizedBox(
            width: spacerWidth,
          ), // Cukup biarkan kotak kosong dengan lebar yang sama
        ],
      ),
    );
  }

  /**
   * -- DARK ELITE TAB BAR --
   * Mengubah tampilan Tab menjadi kapsul hitam mewah.
   * Background: Hitam | Text Unselected: Putih | Text Selected: Hitam
   */
  Widget _buildDarkEliteTabBar() {
    return Container(
      height: 55.h,
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: const Color(0xFF252525), // Hitam Pekat
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: TabBar(
          controller: _tabController,
          labelColor:
              Colors.black, // Warna teks saat dipilih (kontras dengan Lime)
          unselectedLabelColor:
              Colors.grey[400], // Warna teks saat tidak dipilih
          labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.sp),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: const Color(0xFFC8FF00), // Lime Green Indicator
            borderRadius: BorderRadius.circular(25.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC8FF00).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Disetujui"),
            Tab(text: "Ditolak"),
          ],
        ),
      ),
    );
  }

  /**
   * -- MISSION LIST (DARK CARD TETAP DIPERTAHANKAN) --
   */
  Widget _buildMissionList(String status) {
    final filtered = _allMissions.where((m) {
      String s = m['status'].toString().toLowerCase();

      // 👇 PERBAIKAN: Jika Tab 'Lolos' (approved), terima juga status 'paid'
      if (status == 'approved') {
        return s == 'approved' || s == 'paid';
      }

      return s == status;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: FadeIn(
          // 🔥 Tambahkan animasi biar nggak kaget munculnya
          duration: const Duration(milliseconds: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  SolarIconsOutline.clipboardList,
                  size: 40.sp,
                  color: const Color.fromARGB(255, 70, 70, 70),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Tidak ada misi ${status}",
                style: TextStyle(
                  color: const Color.fromARGB(255, 49, 49, 49),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMissions,
      color: const Color(0xFFC8FF00),
      backgroundColor: const Color(0xFF000000),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 40.h),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          final bounty = item['bounty'];

          return FadeInUp(
            // PENTING: Gunakan key unik agar animasi terpicu ulang saat pindah TAB
            key: ValueKey("${status}_${item['id']}"),
            duration: const Duration(milliseconds: 600),
            delay: Duration(milliseconds: 100 * index),
            child: Container(
              margin: EdgeInsets.only(bottom: 20.h),
              padding: EdgeInsets.all(22.w),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bounty?['title'] ?? "Campaign",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16.sp,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  Row(
                    children: [
                      Icon(
                        SolarIconsOutline.eye,
                        color: Colors.grey[500],
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Laporan: ${NumberFormat.decimalPattern('id').format(item['views_count'])} Views",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  if (status == "rejected")
                    _buildRejectionBox(item['rejection_reason']),
                  if (status == "approved")
                    _buildRewardInfo(item['prize_amount']),

                  SizedBox(height: 15.h),
                  Divider(color: Colors.grey[800], thickness: 0.5),
                  SizedBox(height: 10.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat(
                          'dd MMM yyyy',
                        ).format(DateTime.parse(item['created_at'])),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC8FF00).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          SolarIconsOutline.arrowRight,
                          size: 14.sp,
                          color: const Color(0xFFC8FF00),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /**
   * -- HELPER WIDGETS TETAP SAMA --
   */
  Widget _buildRejectionBox(String? reason) {
    return Container(
      margin: EdgeInsets.only(top: 15.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(SolarIconsBold.infoCircle, color: Colors.red[400], size: 16.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              "Ditolak: ${reason ?? 'Data tidak valid'}",
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardInfo(dynamic amount) {
    double value = double.tryParse(amount.toString()) ?? 0;
    return Container(
      margin: EdgeInsets.only(top: 15.h),
      child: Row(
        children: [
          Icon(
            SolarIconsOutline.dollar,
            color: const Color(0xFFC8FF00),
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Text(
            "Reward: ${currencyFormat.format(value)}",
            style: TextStyle(
              color: const Color(0xFFC8FF00),
              fontWeight: FontWeight.w900,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    String label = "PENDING";
    if (status == "approved") {
      color = const Color(0xFFC8FF00);
      label = "DISETUJUI";
    }
    if (status == "rejected") {
      color = Colors.redAccent;
      label = "DITOLAK";
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
