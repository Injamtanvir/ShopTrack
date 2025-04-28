import 'package:flutter/material.dart';
import 'dart:math';

class IDCard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> shopData;
  final bool isUserCard; // To distinguish between user and shop card
  
  const IDCard({
    Key? key, 
    required this.userData, 
    required this.shopData,
    this.isUserCard = true,
  }) : super(key: key);

  @override
  State<IDCard> createState() => _IDCardState();
}

class _IDCardState extends State<IDCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showFrontSide = true;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _toggleCard() {
    setState(() {
      _showFrontSide = !_showFrontSide;
      if (_showFrontSide) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: _toggleCard,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final angle = _controller.value * pi;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle);
            
            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: angle >= pi / 2 && angle < 3 * pi / 2
                  ? Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: widget.isUserCard ? _buildUserBackCard() : _buildShopBackCard(),
                    )
                  : widget.isUserCard ? _buildUserFrontCard() : _buildShopFrontCard(),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildUserFrontCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: 320,
        height: 500,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1551),
              Color(0xFF0A3A8F),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Shop logo
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                (widget.shopData['shopName'] ?? 'Shop').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Profile Image
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  size: 100,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Name
            Text(
              widget.userData['name'] ?? 'User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Position
            Text(
              widget.userData['designation'] ?? 'Employee',
              style: TextStyle(
                color: Colors.blue.shade100,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            // Barcode placeholder
            Container(
              width: 200,
              height: 50,
              color: Colors.white,
              child: Center(
                child: Text(
                  '||||| ||| ||||||| ||| |||||',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ID Number and Department
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${widget.userData['userId'] ?? ''}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Role: ${widget.userData['designation'] ?? ''}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // Bottom wave design
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 60,
                width: double.infinity,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserBackCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: 320,
        height: 500,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1551),
              Color(0xFF0A3A8F),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Shop name
            Text(
              widget.shopData['shopName'] ?? 'Shop',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            // Terms & conditions header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'User Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // User details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Name:', widget.userData['name'] ?? ''),
                  const SizedBox(height: 8),
                  _buildDetailRow('Role:', widget.userData['designation'] ?? ''),
                  const SizedBox(height: 8),
                  _buildDetailRow('User ID:', widget.userData['userId'] ?? ''),
                  const SizedBox(height: 8),
                  _buildDetailRow('Email:', widget.userData['email'] ?? ''),
                  const SizedBox(height: 8),
                  _buildDetailRow('Shop ID:', widget.shopData['shopId'] ?? ''),
                  const SizedBox(height: 30),
                  Text(
                    'This ID card is property of ShopTrack. If found, please return to the shop or contact the shop owner.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Generated by ShopTrack
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Generated by ShopTrack',
                style: TextStyle(
                  color: Colors.blue.shade200,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopFrontCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: 320,
        height: 500,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1551),
              Color(0xFF0A3A8F),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            // Shop logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  (widget.shopData['shopName'] ?? 'Shop').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Shop name
            Text(
              widget.shopData['shopName'] ?? 'Shop',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Shop category
            Text(
              widget.shopData['shopCategory'] ?? 'Business',
              style: TextStyle(
                color: Colors.blue.shade100,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            // Barcode placeholder
            Container(
              width: 200,
              height: 50,
              color: Colors.white,
              child: Center(
                child: Text(
                  '||||| ||| ||||||| ||| |||||',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Shop Info
            Column(
              children: [
                Text(
                  'Shop ID: ${widget.shopData['shopId'] ?? ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Est. ${widget.shopData['registrationDate'] ?? 'N/A'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Bottom wave design
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 60,
                width: double.infinity,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildShopBackCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: 320,
        height: 500,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1551),
              Color(0xFF0A3A8F),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Shop name
            Text(
              widget.shopData['shopName'] ?? 'Shop',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            // Shop information header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Shop Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Shop details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Shop Name:', widget.shopData['shopName'] ?? ''),
                  const SizedBox(height: 8),
                  _buildDetailRow('Category:', widget.shopData['shopCategory'] ?? '******'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Shop ID:', widget.shopData['shopId'] ?? ''),
                  const SizedBox(height: 8),
                  _buildDetailRow('License No:', widget.shopData['shopLicense'] ?? '******'),
                  const SizedBox(height: 8),
                  _buildDetailRow('VAT License:', widget.shopData['shopVatLicense'] ?? '******'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Address:', widget.shopData['shopAddress'] ?? ''),
                  const SizedBox(height: 30),
                  Text(
                    'This shop is registered with ShopTrack. For verification or more information, please contact ShopTrack support.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Generated by ShopTrack
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Generated by ShopTrack',
                style: TextStyle(
                  color: Colors.blue.shade200,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.blue.shade200,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Clipper for wave effect
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.6);
    
    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    
    final secondControlPoint = Offset(size.width * 0.75, size.height * 0.6);
    final secondEndPoint = Offset(size.width, size.height);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
} 