import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/data_table.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_card.dart';

class AdminUsersScreen extends StatefulWidget {
  static const routeName = '/admin-users';

  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final usersData = await authProvider.getShopUsers();
      
      setState(() {
        _users = usersData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String userId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final result = await authProvider.deleteUser(userId);
      if (result) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
        _loadUsers();
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? 'Failed to delete user')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }
    
    final query = _searchQuery.toLowerCase();
    return _users.where((user) {
      final name = user['name'].toString().toLowerCase();
      final email = user['email'].toString().toLowerCase();
      final role = user['role'].toString().toLowerCase();
      
      return name.contains(query) || 
             email.contains(query) || 
             role.contains(query);
    }).toList();
  }

  Map<String, int> get _userStats {
    int total = _users.length;
    int admins = 0;
    int salesPersons = 0;
    int owners = 0;
    
    for (var user in _users) {
      final role = user['role'].toString().toLowerCase();
      if (role == 'owner') {
        owners++;
      } else if (role == 'manager') {
        admins++;
      } else if (role == 'sales') {
        salesPersons++;
      }
    }
    
    return {
      'total': total,
      'admins': admins,
      'salesPersons': salesPersons,
      'owners': owners,
    };
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = authProvider.isOwner;
    final userStats = _userStats;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(
                title: 'User Management',
                subtitle: 'Manage your shop\'s staff accounts',
                hasSearchBar: true,
                onSearch: (query) => setState(() => _searchQuery = query),
                searchHint: 'Search users by name, email or role',
              ),
              const SizedBox(height: AppSpacing.medium),
              // User statistics
              SizedBox(
                height: 120,
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total Users',
                        value: userStats['total'].toString(),
                        icon: Icons.people,
                        iconColor: AppColors.primary,
                        isLoading: _isLoading,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: StatCard(
                        title: 'Admin Users',
                        value: userStats['admins'].toString(),
                        icon: Icons.admin_panel_settings,
                        iconColor: AppColors.accent,
                        isLoading: _isLoading,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: StatCard(
                        title: 'Sales Staff',
                        value: userStats['salesPersons'].toString(),
                        icon: Icons.badge,
                        iconColor: AppColors.secondary,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Expanded(
                child: _errorMessage != null
                    ? EmptyState(
                        title: 'Error Loading Users',
                        message: _errorMessage!,
                        icon: Icons.error_outline,
                        iconColor: AppColors.error,
                        buttonText: 'Try Again',
                        onButtonPressed: _loadUsers,
                      )
                    : _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredUsers.isEmpty
                            ? EmptyState(
                                title: 'No Users Found',
                                message: _searchQuery.isNotEmpty
                                    ? 'No results match your search. Try a different search term.'
                                    : 'No users have been added to your shop yet.',
                                icon: Icons.person_off,
                                buttonText: _searchQuery.isNotEmpty ? 'Clear Search' : null,
                                onButtonPressed: _searchQuery.isNotEmpty 
                                    ? () => setState(() => _searchQuery = '') 
                                    : null,
                              )
                            : CustomDataTable<dynamic>(
                                columns: ['Name', 'Email', 'Role', 'ID', isOwner ? 'Actions' : ''],
                                items: _filteredUsers,
                                cellBuilder: (user) => [
                                  DataTableCell(text: user['name']),
                                  DataTableCell(text: user['email']),
                                  StatusCell(
                                    text: _getRoleDisplay(user['role']),
                                    color: _getRoleColor(user['role']),
                                  ),
                                  DataTableCell(
                                    text: user['seller_id'] ?? '-',
                                    style: AppTextStyles.caption,
                                  ),
                                  if (isOwner)
                                    user['role'] == 'owner'
                                        ? const DataTableCell(text: 'Cannot Delete Owner')
                                        : IconButton(
                                            icon: const Icon(Icons.delete, color: AppColors.error),
                                            onPressed: () => _showDeleteConfirmation(user),
                                          ),
                                ],
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to user registration
          final role = authProvider.user?.role;
          if (role == 'owner') {
            _showUserTypeSelection(context);
          } else if (role == 'manager') {
            Navigator.pushNamed(context, '/register-sales');
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showUserTypeSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Register New User',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: AppSpacing.medium),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: AppColors.accent),
              title: const Text('Admin User'),
              subtitle: const Text('Can manage products and view reports'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/register-admin');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.badge, color: AppColors.secondary),
              title: const Text('Sales Person'),
              subtitle: const Text('Can create invoices and manage inventory'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/register-sales');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(dynamic user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${user['name']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteUser(user['_id']);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplay(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return 'Owner';
      case 'manager':
        return 'Admin';
      case 'sales':
        return 'Sales';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return AppColors.accent;
      case 'manager':
        return AppColors.primary;
      case 'sales':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }
} 