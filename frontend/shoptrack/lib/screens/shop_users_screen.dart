import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ShopUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? designation;
  final String? sellerId;

  ShopUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.designation,
    this.sellerId,
  });

  factory ShopUser.fromJson(Map<String, dynamic> json) {
    return ShopUser(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      designation: json['designation'],
      sellerId: json['seller_id'],
    );
  }
}

class ShopUsersScreen extends StatefulWidget {
  static const routeName = '/shop-users';

  const ShopUsersScreen({Key? key}) : super(key: key);

  @override
  State<ShopUsersScreen> createState() => _ShopUsersScreenState();
}

class _ShopUsersScreenState extends State<ShopUsersScreen> {
  List<ShopUser> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

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
        _users = usersData.map((userData) => ShopUser.fromJson(userData)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(ShopUser user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      setState(() => _isLoading = true);
      
      try {
        final success = await authProvider.deleteUser(user.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.red;
      case 'admin':
        return Colors.blue;
      case 'seller':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = authProvider.isOwner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Users'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (ctx, i) {
                        final user = _users[i];
                        final canDelete = isOwner && user.role != 'owner';
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: _getRoleColor(user.role),
                              child: Text(
                                user.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Email: ${user.email}'),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text('Role: '),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(user.role).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user.role.toUpperCase(),
                                        style: TextStyle(
                                          color: _getRoleColor(user.role),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (user.designation != null) ...[
                                  const SizedBox(height: 2),
                                  Text('Designation: ${user.designation}'),
                                ],
                                if (user.sellerId != null) ...[
                                  const SizedBox(height: 2),
                                  Text('Seller ID: ${user.sellerId}'),
                                ],
                              ],
                            ),
                            trailing: canDelete 
                                ? IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteUser(user),
                                    tooltip: 'Delete user',
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
    );
  }
} 