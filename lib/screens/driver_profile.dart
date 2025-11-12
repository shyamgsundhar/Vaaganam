import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _experienceController;
  late TextEditingController _licenseController;

  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _experienceController = TextEditingController();
    _licenseController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated || !authProvider.isDriver) {
          return const Scaffold(
            body: Center(
              child: Text('Please log in as a driver to view this page'),
            ),
          );
        }

        final userProfile = authProvider.userProfile;
        if (userProfile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!_isEditing) {
          _updateControllers(userProfile);
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(),
          body: _buildBody(userProfile),
        );
      },
    );
  }

  void _updateControllers(Map<String, dynamic> profile) {
    _nameController.text = profile['name'] ?? '';
    _emailController.text = profile['email'] ?? '';
    _phoneController.text = profile['phone'] ?? '';
    _experienceController.text = profile['experience'] ?? '';
    _licenseController.text = profile['licenseNumber'] ?? '';
    _selectedGender = profile['gender'];
  }

  AppBar _buildAppBar() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AppBar(
      title: Text(
        'Driver Profile',
        style: TextStyle(fontWeight: FontWeight.bold, color: primary),
      ),
      backgroundColor: Colors.grey[50],
      elevation: 0,
      toolbarHeight: 60,
      iconTheme: IconThemeData(color: primary),
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            onPressed: _toggleEditMode,
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            tooltip: _isEditing ? 'Save Changes' : 'Edit Profile',
          ),
      ],
    );
  }

  Widget _buildBody(Map<String, dynamic> profile) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(profile, primary, secondary),
          const SizedBox(height: 16),

          _buildPersonalInfoCard(profile),
          const SizedBox(height: 16),

          _buildWorkInfoCard(profile),
          const SizedBox(height: 16),

          _buildStatisticsCard(profile),
          const SizedBox(height: 16),

          _buildAccountActionsCard(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    Map<String, dynamic> profile,
    Color primary,
    Color secondary,
  ) {
    final joiningDate = profile['joiningDate']?.toDate();
    final memberSince = joiningDate != null
        ? DateFormat('MMM yyyy').format(joiningDate)
        : 'Recent';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 60, color: primary),
            ),
            const SizedBox(height: 16),
            Text(
              profile['name'] ?? 'Driver',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${profile['uid']?.substring(0, 8).toUpperCase() ?? 'N/A'}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusChip(
                  icon: Icons.star,
                  label:
                      '${(profile['rating'] ?? 5.0).toStringAsFixed(1)} Rating',
                  color: Colors.amber,
                ),
                const SizedBox(width: 12),
                _buildStatusChip(
                  icon: Icons.calendar_today,
                  label: 'Since $memberSince',
                  color: Colors.white70,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStatusChip(
              icon: profile['isActive'] ?? false
                  ? Icons.check_circle
                  : Icons.pause_circle,
              label: profile['isActive'] ?? false ? 'Active' : 'Inactive',
              color: profile['isActive'] ?? false
                  ? Colors.green
                  : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(Map<String, dynamic> profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoField(
              icon: Icons.person_outline,
              label: 'Full Name',
              value: profile['name'] ?? 'Not provided',
              controller: _nameController,
              isEditable: true,
            ),
            const SizedBox(height: 12),
            _buildInfoField(
              icon: Icons.email_outlined,
              label: 'Email',
              value: profile['email'] ?? 'Not provided',
              controller: _emailController,
              isEditable: true,
            ),
            const SizedBox(height: 12),
            _buildInfoField(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: profile['phone'] ?? 'Not provided',
              controller: _phoneController,
              isEditable: true,
            ),
            const SizedBox(height: 12),
            _buildInfoField(
              icon: Icons.cake_outlined,
              label: 'Age',
              value: profile['age']?.toString() ?? 'Not provided',
              isEditable: false,
            ),
            const SizedBox(height: 12),
            _buildGenderField(profile['gender']),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkInfoCard(Map<String, dynamic> profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Work Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoField(
              icon: Icons.credit_card_outlined,
              label: 'License Number',
              value: profile['licenseNumber'] ?? 'Not provided',
              controller: _licenseController,
              isEditable: true,
            ),
            const SizedBox(height: 12),
            _buildInfoField(
              icon: Icons.work_outline,
              label: 'Experience',
              value: profile['experience'] ?? 'Not provided',
              controller: _experienceController,
              isEditable: true,
            ),
            const SizedBox(height: 12),
            _buildInfoField(
              icon: Icons.lock_outline,
              label: 'Passcode',
              value: '****',
              isEditable: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Trips',
                    '${profile['totalTrips'] ?? 0}',
                    Icons.local_shipping,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Rating',
                    '${(profile['rating'] ?? 5.0).toStringAsFixed(1)}⭐',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help with your account',
              onTap: _showHelpDialog,
            ),
            const Divider(),
            _buildActionTile(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              onTap: _showLogoutDialog,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required String value,
    TextEditingController? controller,
    bool isEditable = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (_isEditing && isEditable && controller != null)
                TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                )
              else
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField(String? currentGender) {
    return Row(
      children: [
        Icon(Icons.person_outline, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gender',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (_isEditing)
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                )
              else
                Text(
                  currentGender ?? 'Not specified',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _toggleEditMode() async {
    if (_isEditing) {
      await _saveProfile();
    } else {
      setState(() {
        _isEditing = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final updates = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'experience': _experienceController.text.trim(),
        'licenseNumber': _licenseController.text.trim(),
        if (_selectedGender != null) 'gender': _selectedGender,
      };

      final success = await authProvider.updateProfile(updates);

      if (success) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Failed to update profile',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For assistance, please contact:'),
            SizedBox(height: 8),
            Text('📧 Email: support@vaaganam.com'),
            Text('📞 Phone: +91 80000 12345'),
            Text('🕒 Support Hours: 9 AM - 6 PM'),
            SizedBox(height: 12),
            Text(
              'You can also report issues or request features through the app.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout();

                if (mounted) {
                  Navigator.of(context).pop();

                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
