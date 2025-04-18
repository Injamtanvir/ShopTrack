import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';

class BranchManagementScreen extends StatefulWidget {
  static const routeName = '/branch-management';
  
  const BranchManagementScreen({Key? key}) : super(key: key);

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _managerEmailController = TextEditingController();
  
  List<dynamic>? _branches;
  List<dynamic>? _shopUsers;
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadBranches();
    _loadShopUsers();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _managerEmailController.dispose();
    super.dispose();
  }
  
  Future<void> _loadBranches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final branches = await authProvider.getShopBranches();
      
      setState(() {
        _branches = branches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadShopUsers() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = authProvider.user!.shopId;
      
      _shopUsers = await _apiService.getShopUsersRaw(shopId);
    } catch (e) {
      // Non-critical error, just print it
      print('Error loading shop users: $e');
    }
  }
  
  Future<void> _createBranch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.createBranch(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        managerEmail: _managerEmailController.text.isEmpty 
            ? null 
            : _managerEmailController.text.trim(),
      );
      
      if (result != null) {
        // Clear form
        _nameController.clear();
        _addressController.clear();
        _managerEmailController.clear();
        
        // Reload branches
        await _loadBranches();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Branch created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Close dialog if it was opened
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $_error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _assignUserToBranch(String branchId, String branchName) async {
    final selectedUserEmail = await showDialog<String>(
      context: context,
      builder: (context) => _buildAssignUserDialog(branchName),
    );
    
    if (selectedUserEmail == null || selectedUserEmail.isEmpty) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.assignUserToBranch(
        userEmail: selectedUserEmail,
        branchId: branchId,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User assigned to branch successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload data
        await _loadBranches();
        await _loadShopUsers();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to assign user to branch.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isPremium = authProvider.isPremium;
    
    if (!isPremium) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Branch Management'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: const Center(
          child: Text('Premium subscription required to access this feature.'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBranchDialog(),
        label: const Text('Add Branch'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: $_error'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadBranches,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  : _branches == null || _branches!.isEmpty
                      ? _buildEmptyState()
                      : _buildBranchesList(),
            ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'No Branches Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Create your first branch to manage multiple locations for your business.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Create Branch',
              onPressed: () => _showCreateBranchDialog(),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBranchesList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Branches',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Manage your shop branches and assign staff to each location.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _branches!.length,
            itemBuilder: (context, index) {
              final branch = _branches![index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.business, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              branch['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildBranchDetailItem('Branch ID', branch['branch_id']),
                      _buildBranchDetailItem('Address', branch['address']),
                      _buildBranchDetailItem(
                        'Manager', 
                        branch['manager_name'] ?? 'Not assigned',
                        isHighlighted: branch['manager_name'] != null,
                      ),
                      _buildBranchDetailItem(
                        'Created', 
                        _formatDate(branch['created_at']),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _assignUserToBranch(
                              branch['branch_id'],
                              branch['name'],
                            ),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Assign User'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              // View branch details or edit branch
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
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
        ],
      ),
    );
  }
  
  Widget _buildBranchDetailItem(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: isHighlighted ? Colors.green.shade700 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCreateBranchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Branch'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Branch Name',
                    hintText: 'E.g., Downtown Store',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a branch name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'E.g., 123 Main St, Dhaka',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a branch address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _managerEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Manager Email (Optional)',
                    hintText: 'E.g., manager@example.com',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createBranch,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAssignUserDialog(String branchName) {
    final List<dynamic> availableUsers = _shopUsers?.where((user) {
      // Filter out users who can't be assigned (e.g., already has a branch)
      return user['branch_id'] == null || user['branch_id'].isEmpty;
    }).toList() ?? [];
    
    String? selectedUserEmail;
    
    return AlertDialog(
      title: Text('Assign User to $branchName'),
      content: SingleChildScrollView(
        child: availableUsers.isEmpty
            ? const Text('No available users to assign. All users already have branch assignments.')
            : StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Select a user to assign to this branch:',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      ...availableUsers.map((user) {
                        final userEmail = user['email'];
                        final userName = user['name'];
                        final userRole = user['role'];
                        
                        return RadioListTile<String>(
                          title: Text(userName),
                          subtitle: Text('$userEmail (${_capitalize(userRole)})'),
                          value: userEmail,
                          groupValue: selectedUserEmail,
                          onChanged: (value) {
                            setState(() {
                              selectedUserEmail = value;
                            });
                          },
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: availableUsers.isEmpty
              ? null
              : () => Navigator.of(context).pop(selectedUserEmail),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: const Text('Assign'),
        ),
      ],
    );
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
  
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
} 