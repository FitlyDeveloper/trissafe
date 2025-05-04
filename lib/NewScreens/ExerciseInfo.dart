import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseInfo extends StatefulWidget {
  final String exerciseName;
  final String muscle;

  const ExerciseInfo({
    Key? key,
    required this.exerciseName,
    required this.muscle,
  }) : super(key: key);

  @override
  State<ExerciseInfo> createState() => _ExerciseInfoState();
}

class _ExerciseInfoState extends State<ExerciseInfo> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
  }

  Future<void> _loadFavoriteState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isFavorite = prefs.getBool('favorite_${widget.exerciseName}') ?? false;
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isFavorite = !isFavorite;
    });
    await prefs.setBool('favorite_${widget.exerciseName}', isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background4.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button and title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 29).copyWith(top: 16, bottom: 8.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      Text(
                        widget.exerciseName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Pro Display',
                          color: Colors.black,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      SizedBox(width: 24),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 29),
                  height: 1,
                  color: Color(0xFFBDBDBD),
                ),
                SizedBox(height: 10), // Updated from 24 to 10
                // Exercise Info Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 31, vertical: 8),
                  child: Container(
                    width: 331,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x14000000),
                          offset: Offset(0, 3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 13),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/dumbbell.png',
                              width: 24,
                              height: 24,
                              color: Colors.grey[700],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.exerciseName,
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontFamily: 'SFProDisplay-Regular',
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              Text(
                                widget.muscle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0x7f000000),
                                  fontFamily: 'SFProDisplay-Regular',
                                  fontWeight: FontWeight.normal,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        GestureDetector(
                          onTap: _toggleFavorite,
                          child: Image.asset(
                            isFavorite ? 'assets/images/bookmarkfilled.png' : 'assets/images/bookmark.png',
                            width: 20,
                            height: 20,
                            color: isFavorite ? Color(0xFFFFC300) : Colors.black,
                          ),
                        ),
                        SizedBox(width: 13),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24), // Updated from 16 to 24

                // Weight and date info
                Padding(
                  padding: const EdgeInsets.only(left: 29, right: 29, top: 14),
                  child: Row(
                    children: [
                      Text(
                        '60 kg',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '(March 21)',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Last 3 months',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Graph
                Container(
                  height: 200,
                  padding: EdgeInsets.symmetric(horizontal: 29),
                  child: Stack(
                    children: [
                      // Y-axis labels
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('70kg', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text('50kg', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text('30kg', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      // Graph
                      Padding(
                        padding: EdgeInsets.only(left: 40),
                        child: CustomPaint(
                          size: Size(double.infinity, 200),
                          painter: ChartPainter(),
                        ),
                      ),
                      // X-axis labels
                      Positioned(
                        left: 40,
                        right: 0,
                        bottom: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Jan 15', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text('Feb 01', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text('Feb 15', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text('Mar 01', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text('Mar 15', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Stat buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildStatButton('Heaviest Weight', true)),
                          SizedBox(width: 8),
                          Expanded(child: _buildStatButton('One Rep Max', false)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: _buildStatButton('Best Set Volume', false),
                        ),
                      ),
                    ],
                  ),
                ),

                // Personal Records title
                Padding(
                  padding: const EdgeInsets.only(left: 29, right: 29, top: 24, bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/weekstreak.png',
                        width: 24,
                        height: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Personal Records',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Personal Records entries
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 29),
                  child: Column(
                    children: [
                      _buildRecord('Heaviest Weight:', '90kg'),
                      Divider(height: 24, thickness: 0.5, color: Color(0xFFEEEEEE)),
                      _buildRecord('Best 1RM:', '92.5kg'),
                      Divider(height: 24, thickness: 0.5, color: Color(0xFFEEEEEE)),
                      _buildRecord('Best Set Volume:', '65kg x 12'),
                    ],
                  ),
                ),
                // Set Records title
                Padding(
                  padding: const EdgeInsets.only(left: 29, right: 29, top: 32, bottom: 12),
                  child: Text(
                    'Set Records',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Set Records table header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 29),
                  child: Row(
                    children: [
                      Text(
                        'Reps',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Personal Best',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                // Set Records
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 29),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSetRecordRow('1', '90kg'),
                      Divider(height: 24, thickness: 0.5, color: Color(0xFFEEEEEE)),
                      _buildSetRecordRow('2', '80kg'),
                      Divider(height: 24, thickness: 0.5, color: Color(0xFFEEEEEE)),
                      _buildSetRecordRow('3', '75kg'),
                      Divider(height: 24, thickness: 0.5, color: Color(0xFFEEEEEE)),
                      _buildSetRecordRow('4', '70kg'),
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

  Widget _buildStatButton(String label, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Color(0xFFEEEEEE).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRecord(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSetRecordRow(String reps, String weight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              reps,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Spacer(),
          SizedBox(
            width: 80,
            child: Text(
              weight,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final points = [
      Offset(0, size.height * 0.6),
      Offset(size.width * 0.25, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.75, size.height * 0.6),
      Offset(size.width, size.height * 0.7),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      path.lineTo(p2.dx, p2.dy);
    }

    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
