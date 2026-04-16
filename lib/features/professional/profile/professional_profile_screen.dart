import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/models/data_models.dart';
import '../controllers/professional_profile_controller.dart';
import 'package:share_plus/share_plus.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  const ProfessionalProfileScreen({super.key});

  @override
  State<ProfessionalProfileScreen> createState() => _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfessionalProfileController>().fetchProfile();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients && _scrollController.offset > 10 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.hasClients && _scrollController.offset <= 10 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  void _shareProfile(Professional? profile) {
    if (profile == null) return;
    
    final String shareText = "Check out my professional profile on BellaVella!\n\n"
        "Name: ${profile.name}\n"
        "Rating: ${profile.rating} ⭐\n\n"
        "Download the app now: https://play.google.com/store/apps/details?id=com.bellavella.professional";
    
    Share.share(shareText);
  }

  Future<void> _pickAndUploadImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Select Profile Picture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (source == null) return; // User canceled the picker

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image;
      
      if (source == ImageSource.camera) {
        // On Web, ImageSource.camera might still open a file picker unless capture is specified.
        // Standard image_picker on web should handle this if source is camera.
        image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
          preferredCameraDevice: CameraDevice.rear,
        );
      } else {
        image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
        );
      }

      if (image != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading image...')));
        final success = await context.read<ProfessionalProfileController>().uploadProfileImage(image);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile image updated successfully!')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile image.')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfessionalProfileController>(
      builder: (context, controller, child) {
        final profile = controller.profile;

        if (controller.isLoading && profile == null) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          );
        }

        if (profile == null) {
          if (controller.error != null) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${controller.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.fetchProfile(),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }
          return Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: _buildAppBar(),
          body: RefreshIndicator(
            onRefresh: () => controller.fetchProfile(),
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(profile),
                  const SizedBox(height: 24),
                  
                  _buildSectionWrapper([
                    _buildSectionHeader("Personal Details"),
                    _buildListOption(
                      Icons.person_outline_rounded,
                      "Personal Information",
                      subtitle: "${profile?.name ?? 'Name'}, ${profile?.gender ?? 'Gender'}",
                      onTap: () async {
                        await context.pushNamed(AppRoutes.proEditPersonalInfoName);
                        controller.fetchProfile();
                      },
                    ),
                    _buildListOption(
                      Icons.near_me_outlined,
                      "Service Area",
                      subtitle: "${profile?.city ?? 'City'} • ${profile?.serviceRadius ?? '0'} km radius",
                      onTap: () async {
                        await context.pushNamed(AppRoutes.proEditServiceAreaName);
                        controller.fetchProfile();
                      },
                    ),
                    _buildListOption(
                      Icons.event_note_outlined,
                      "Leave Apply",
                      subtitle: "Apply for sick, casual or emergency leave",
                      onTap: () => context.pushNamed(AppRoutes.proLeaveApplyName),
                    ),
                    _buildListOption(
                      Icons.call_outlined,
                      "Contact Details",
                      subtitle: "${profile?.phone ?? 'Phone'} • ${profile?.email ?? 'Email'}",
                      onTap: () async {
                        await context.pushNamed(AppRoutes.proEditContactDetailsName);
                        controller.fetchProfile();
                      },
                    ),
                  ]),

                  const SizedBox(height: 16),
                  _buildSectionWrapper([
                    _buildSectionHeader("Rewards & Referrals"),
                    _buildListOption(
                      Icons.card_giftcard_rounded,
                      "Refer & Earn",
                      subtitle: "Invite friends and earn rewards",
                      onTap: () => context.pushNamed(AppRoutes.proReferEarnName),
                    ),
                  ]),

                  const SizedBox(height: 16),
                  _buildSectionWrapper([
                    _buildSectionHeader("Kit Orders"),
                    _buildListOption(
                      Icons.shopping_bag_outlined,
                      "Order History",
                      subtitle: "View your kit purchase history",
                      onTap: () => context.pushNamed(AppRoutes.proKitOrdersName),
                    ),
                  ]),

                  const SizedBox(height: 16),
                  _buildSectionWrapper([
                    _buildListOption(
                      Icons.notifications_none_rounded, 
                      "Notification Settings",
                      onTap: () => context.pushNamed(AppRoutes.proNotificationSettingsName),
                    ),
                    _buildListOption(
                      Icons.language_rounded, 
                      "App Language", 
                      value: "English",
                      onTap: () => context.pushNamed(AppRoutes.proLanguageSettingsName),
                    ),
                    _buildListOption(
                      Icons.logout_rounded,
                      "Logout",
                      isDestructive: true,
                      onTap: () => _handleLogout(context),
                    ),
                  ]),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: _isScrolled ? 0.5 : 0,
      centerTitle: true,
      title: Text(
        "Profile",
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _shareProfile(context.read<ProfessionalProfileController>().profile),
          icon: const Icon(Icons.share_outlined, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(Professional? profile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1), width: 3),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFF3F4F6),
                  backgroundImage: profile?.photoUrl.isNotEmpty == true 
                    ? NetworkImage('${profile!.photoUrl}?v=${DateTime.now().millisecondsSinceEpoch}') as ImageProvider
                    : null,
                  child: profile?.photoUrl.isEmpty == true 
                    ? const Icon(Icons.person_rounded, size: 48, color: Colors.grey)
                    : null,
                ),
              ),
              InkWell(
                onTap: _pickAndUploadImage,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile?.name ?? 'Professional',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              if (profile?.verification == 'Verified') ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, size: 20, color: Color(0xFF00B0FF)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            (profile?.services != null && profile!.services.isNotEmpty) 
                ? profile.services.first.name 
                : 'Service Professional',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeaderStat("${profile?.rating ?? 4.5}", "Rating"),
                VerticalDivider(color: Colors.grey.shade300, thickness: 1, indent: 4, endIndent: 4, width: 32),
                _buildHeaderStat("${((profile?.rating ?? 4.5) * 27).toInt()}+", "Reviews"),
                VerticalDivider(color: Colors.grey.shade300, thickness: 1, indent: 4, endIndent: 4, width: 32),
                _buildHeaderStat("${profile?.experience ?? '3'}", "Exp"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _badge("Joined: ${profile?.joined?.split('T').first ?? 'Mar 01, 2026'}"),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSectionWrapper(List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Colors.black,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildListOption(
    IconData icon, 
    String label, {
    String? subtitle, 
    String? value, 
    Color? valueColor,
    Widget? trailingWidget,
    bool isVerified = false, 
    bool isDestructive = false, 
    VoidCallback? onTap
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint("ListOption tapped: $label");
          if (onTap != null) {
            onTap();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$label feature coming soon!")),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive ? Colors.red.shade50 : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon, 
                  size: 20, 
                  color: isDestructive ? Colors.red.shade600 : Colors.black87
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? Colors.red.shade600 : Colors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isVerified)
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.check_circle_rounded, size: 16, color: Colors.green.shade600),
                ),
              if (trailingWidget != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: trailingWidget,
                ),
              if (value != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (valueColor ?? (isVerified ? Colors.green.shade600 : Colors.grey.shade700)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: valueColor ?? (isVerified ? Colors.green.shade600 : Colors.grey.shade700),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await context.read<ProfessionalProfileController>().logout();
              if (context.mounted) {
                context.go(AppRoutes.proLogin);
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
