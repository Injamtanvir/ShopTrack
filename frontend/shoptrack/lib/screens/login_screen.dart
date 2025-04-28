import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'admin_home_screen.dart';
import 'register_screen.dart';
import 'seller_home_screen.dart';
import 'owner_home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _shopIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      shopId: _shopIdController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      // Navigate based on user role
      if (authProvider.isOwner) {
        Navigator.pushReplacementNamed(context, OwnerHomeScreen.routeName);
      } else if (authProvider.isManager) {
        Navigator.pushReplacementNamed(context, AdminHomeScreen.routeName);
      } else {
        Navigator.pushReplacementNamed(context, SellerHomeScreen.routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top decoration
                Container(
                  height: size.height * 0.35,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5D5FEF),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background graphic elements
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 50,
                        right: 30,
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      // Shop icon
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.store,
                              size: 60,
                              color: const Color(0xFF5D5FEF),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'ShopTrack',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage Your Business Efficiently',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Login form
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFF5D5FEF),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Welcome back to your shop account',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Error message if any
                      if (authProvider.errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade800,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  authProvider.errorMessage!,
                                  style: TextStyle(color: Colors.red.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Shop ID Field
                      _buildTextField(
                        controller: _shopIdController,
                        label: 'Shop ID',
                        prefixIcon: Icons.business,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter shop ID';
                          }
                          if (value.length != 8) {
                            return 'Shop ID must be 8 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D5FEF),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: const Color(0xFF5D5FEF).withOpacity(0.6),
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have a shop account?",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, RegisterScreen.routeName);
                            },
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                color: Color(0xFF5D5FEF),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF5D5FEF),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF5D5FEF),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF5D5FEF),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.shade300,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.shade500,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}

class ShopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Define paints
    final buildingPaint = Paint()
      ..color = const Color(0xFFE8EAF6)
      ..style = PaintingStyle.fill;
    
    final roofPaint = Paint()
      ..color = const Color(0xFF5D5FEF)
      ..style = PaintingStyle.fill;
    
    final doorPaint = Paint()
      ..color = const Color(0xFF3949AB)
      ..style = PaintingStyle.fill;
      
    final windowPaint = Paint()
      ..color = const Color(0xFFBBDEFB)
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = const Color(0xFF3F51B5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    final signPaint = Paint()
      ..color = const Color(0xFFFFC107)
      ..style = PaintingStyle.fill;

    // Building base
    final buildingPath = Path()
      ..moveTo(width * 0.15, height * 0.35)
      ..lineTo(width * 0.15, height * 0.92)
      ..lineTo(width * 0.85, height * 0.92)
      ..lineTo(width * 0.85, height * 0.35)
      ..close();
    
    // Roof
    final roofPath = Path()
      ..moveTo(width * 0.08, height * 0.35)
      ..lineTo(width * 0.5, height * 0.12)
      ..lineTo(width * 0.92, height * 0.35)
      ..close();
    
    // Draw building and roof
    canvas.drawPath(buildingPath, buildingPaint);
    canvas.drawPath(buildingPath, borderPaint);
    canvas.drawPath(roofPath, roofPaint);
    canvas.drawPath(roofPath, borderPaint);
    
    // Door
    final doorRect = Rect.fromLTWH(
      width * 0.38, 
      height * 0.65,
      width * 0.24,
      height * 0.27
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(doorRect, Radius.circular(4)),
      doorPaint
    );
    
    // Door handle
    canvas.drawCircle(
      Offset(width * 0.42, height * 0.78),
      width * 0.02,
      Paint()..color = Colors.yellow
    );
    
    // Windows
    final leftWindowRect = Rect.fromLTWH(
      width * 0.23, 
      height * 0.45,
      width * 0.18,
      height * 0.15
    );
    final rightWindowRect = Rect.fromLTWH(
      width * 0.59, 
      height * 0.45,
      width * 0.18,
      height * 0.15
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(leftWindowRect, Radius.circular(2)),
      windowPaint
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(leftWindowRect, Radius.circular(2)),
      borderPaint
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rightWindowRect, Radius.circular(2)),
      windowPaint
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rightWindowRect, Radius.circular(2)),
      borderPaint
    );
    
    // Window panes
    canvas.drawLine(
      Offset(width * 0.32, height * 0.45),
      Offset(width * 0.32, height * 0.60),
      borderPaint
    );
    canvas.drawLine(
      Offset(width * 0.23, height * 0.525),
      Offset(width * 0.41, height * 0.525),
      borderPaint
    );
    
    canvas.drawLine(
      Offset(width * 0.68, height * 0.45),
      Offset(width * 0.68, height * 0.60),
      borderPaint
    );
    canvas.drawLine(
      Offset(width * 0.59, height * 0.525),
      Offset(width * 0.77, height * 0.525),
      borderPaint
    );
    
    // Shop sign
    final signRect = Rect.fromLTWH(
      width * 0.3, 
      height * 0.25,
      width * 0.4,
      height * 0.08
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(signRect, Radius.circular(4)),
      signPaint
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(signRect, Radius.circular(4)),
      borderPaint
    );
    
    // Text on sign
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'SHOP',
        style: TextStyle(
          color: Color(0xFF3F51B5),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(
        width * 0.5 - textPainter.width / 2, 
        height * 0.25 + (height * 0.08 - textPainter.height) / 2
      )
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}