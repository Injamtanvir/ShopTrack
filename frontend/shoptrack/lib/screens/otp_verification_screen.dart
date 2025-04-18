import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/api_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic> registrationData;

  const OTPVerificationScreen({
    Key? key,
    required this.email,
    required this.registrationData,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _generatedShopId;
  
  // Countdown timer for resend OTP
  int _remainingSeconds = 60;
  Timer? _timer;
  bool _enableResend = false;
  
  // Confetti controller for success animation
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Debug print to see the mobile number
    print('OTP screen initialized with mobile number: ${widget.registrationData['mobileNumber']}');
    
    _startResendTimer();
    // In a real app, you would trigger OTP sending here
    _sendOTP();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _remainingSeconds = 60;
    _enableResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _enableResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  Future<void> _sendOTP() async {
    // Call the API to send OTP
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Debug: Check mobile number
      String mobileNumber = widget.registrationData['mobileNumber'] ?? '';
      print('Sending OTP with mobile number: $mobileNumber');
      
      if (mobileNumber.isEmpty) {
        throw Exception("Mobile number is required for OTP verification");
      }
      
      // Use the API service to send OTP
      final apiService = ApiService();
      await apiService.sendOTP(
        email: widget.email,
        mobileNumber: mobileNumber,
      );
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to ${widget.email}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send OTP: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOTPAndRegister() async {
    final otp = _otpController.text.trim();
    
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First verify OTP with API
      final apiService = ApiService();
      await apiService.verifyOTP(
        email: widget.email,
        otp: otp,
      );
      
      // Remove check for owner photo which is now optional
      
      // Then register the shop
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = await authProvider.registerShop(
        name: widget.registrationData['shopName'],
        address: widget.registrationData['shopAddress'],
        ownerName: widget.registrationData['ownerName'],
        licenseNumber: widget.registrationData['licenseNumber'],
        email: widget.registrationData['email'],
        password: widget.registrationData['password'],
        confirmPassword: widget.registrationData['confirmPassword'],
        mobileNumber: widget.registrationData['mobileNumber'],
        nidNumber: widget.registrationData['nidNumber'],
        ownerPhotoPath: widget.registrationData['ownerPhotoPath'], // This will be null but API should handle it
      );

      if (shopId != null && mounted) {
        setState(() {
          _generatedShopId = shopId;
          _isLoading = false;
        });
        
        // Play confetti animation on success
        _confettiController.play();
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: Unable to connect to the server. Please check your internet connection.';
          _isLoading = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network timeout: The server took too long to respond. Please try again later.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_generatedShopId != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFEDF2F9),
        body: Stack(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 80,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Registration Successful!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your shop has been registered successfully.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.indigo.shade200),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Your Shop ID',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _generatedShopId!,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: Colors.indigo),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: _generatedShopId!),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Shop ID copied to clipboard'),
                                          duration: Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    tooltip: 'Copy to Clipboard',
                                    padding: EdgeInsets.zero,
                                    iconSize: 28,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Please save this Shop ID. You will need it to login.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                                context, LoginScreen.routeName, (route) => false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Proceed to Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Confetti overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.1,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.indigo,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F9),
      appBar: AppBar(
        title: const Text('OTP Verification'),
        backgroundColor: Colors.indigo,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Error message if any
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),

                const Icon(
                  Icons.sms_outlined,
                  size: 72,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 24),
                const Text(
                  'OTP Verification',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'We have sent a verification code to\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),
                
                // OTP Input Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _otpController,
                    obscureText: false,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.grey.shade50,
                      selectedFillColor: Colors.indigo.shade50,
                      activeColor: Colors.indigo,
                      inactiveColor: Colors.grey.shade300,
                      selectedColor: Colors.indigo,
                    ),
                    cursorColor: Colors.indigo,
                    animationDuration: const Duration(milliseconds: 300),
                    enableActiveFill: true,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // Auto-verify when 6 digits are entered
                      if (value.length == 6) {
                        // Optional: Auto-verify when all digits are entered
                        // _verifyOTPAndRegister();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 32),
                
                // Verify Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTPAndRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify & Complete Registration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                
                // Resend OTP option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive the code? ",
                      style: TextStyle(color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: _enableResend
                          ? () {
                              _sendOTP();
                              _startResendTimer();
                            }
                          : null,
                      child: Text(
                        _enableResend
                            ? "Resend OTP"
                            : "Resend in $_remainingSeconds seconds",
                        style: TextStyle(
                          color: _enableResend ? Colors.indigo : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Info note
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Verification Instructions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the 6-digit code sent to your email. If you don\'t receive it, you can request another code after the countdown.',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                        ),
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
} 