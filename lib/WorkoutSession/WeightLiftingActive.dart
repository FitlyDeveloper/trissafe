import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import '../NewScreens/AddExercise.dart';
import 'package:flutter/cupertino.dart';
import '../Screens/WeightLifting.dart';

class WeightLiftingActive extends StatefulWidget {
  final List<Exercise> selectedExercises;
  const WeightLiftingActive({Key? key, this.selectedExercises = const []}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WeightLiftingActive();
}

class _WeightLiftingActive extends State<WeightLiftingActive> {
  late List<Exercise> _exercises;

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.selectedExercises);
  }

  Future<void> _addExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CodiaPage()),
    );
    if (result != null && result is Exercise) {
      setState(() {
        _exercises.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background4.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header (Figma/Memories style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 29).copyWith(top: 16, bottom: 8.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => WeightLifting(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.ease;
                              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    Text(
                      'Weight Lifting',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Display',
                        color: Colors.black,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showRestTimerPopup(context),
                      child: Image.asset('images/stopwatch.png', width: 24, height: 24),
                    ),
                  ],
                ),
              ),
              // Slim divider line
              Container(
                margin: EdgeInsets.symmetric(horizontal: 29),
                height: 0.5,
                color: Color(0xFFBDBDBD),
              ),
              // Stats Row (match StartWorkout.dart exactly)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 29, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          '0',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Duration',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '0',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Volume',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '0',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'PRs',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 29),
                height: 0.5,
                color: Color(0xFFBDBDBD),
              ),
              SizedBox(height: 20),
              // Exercise Cards
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  itemCount: _exercises.length,
                  itemBuilder: (context, idx) {
                    final exercise = _exercises[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF4F4F4),
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
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontFamily: 'SF Pro Display',
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          exercise.muscle,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0x7f000000),
                                            fontFamily: 'SFProDisplay-Regular',
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 18),
                              // Table Headers
                              Row(
                                children: [
                                  Expanded(flex: 2, child: Text('SET', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
                                  SizedBox(width: 8),
                                  Expanded(flex: 3, child: Text('PREVIOUS', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
                                  SizedBox(width: 8),
                                  Expanded(flex: 2, child: Text('KG', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
                                  SizedBox(width: 8),
                                  Expanded(flex: 2, child: Text('REPS', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
                                  Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Icon(Icons.check, size: 24, color: Colors.black))),
                                ],
                              ),
                              SizedBox(height: 7),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(flex: 2, child: Text('1', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400))),
                                  SizedBox(width: 8),
                                  Expanded(flex: 3, child: Text('-', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400))),
                                  SizedBox(width: 8),
                                  Expanded(flex: 2, child: Text('0', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400))),
                                  SizedBox(width: 8),
                                  Expanded(flex: 2, child: Text('0', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400))),
                                  Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: SizedBox(width: 24, height: 24, child: Icon(Icons.check_circle, color: Colors.green, size: 24)))),
                                ],
                              ),
                              SizedBox(height: 18),
                              Center(
                                child: Container(
                                  width: 246,
                                  height: 33,
                                  child: ElevatedButton(
                                    style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty.all(Color(0xFF908F8F)),
                                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      )),
                                      elevation: MaterialStateProperty.all(2),
                                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 0, vertical: 0)),
                                      overlayColor: MaterialStateProperty.resolveWith<Color?>(
                                        (states) {
                                          if (states.contains(MaterialState.hovered) || states.contains(MaterialState.pressed)) {
                                            return Color(0xFF6D6D6D); // darker shade, not purple
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    onPressed: _addExercise,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset('assets/images/add.png', width: 18, height: 18, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Add Set', style: TextStyle(color: Colors.white, fontSize: 15)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Add Exercise Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 29),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _addExercise,
                    icon: Image.asset('assets/images/add.png', width: 20, height: 20, color: Colors.white),
                    label: Text('Add Exercise', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 29),
                child: Row(
                  children: [
                    // Discard Button
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(15),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/trashcan.png',
                                    width: 20,
                                    height: 20,
                                    color: Color(0xFFFF3B30),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Discard',
                                    style: TextStyle(
                                      color: Color(0xFFFF3B30),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Finish Button
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(15),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/Finish.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Finish',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestTimerPopup(BuildContext context) {
    final List<String> restTimes = [
      for (int i = 0; i <= 60; i += 5) i < 60 ? '${i}s' : '1min 0s',
      for (int min = 1; min < 5; min++)
        for (int sec = 0; sec < 60; sec += 5)
          sec == 0 ? '${min + 0}min 0s' : '${min}min ${sec}s',
      '5min 0s',
    ];
    int selectedIndex = 0;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              insetPadding: EdgeInsets.symmetric(horizontal: 32),
              child: Stack(
                children: [
                  Container(
                    width: 326,
                    height: 320,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 23),
                        Stack(
                          children: [
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: Center(
                                child: Text(
                                  'Rest Timer',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 20,
                              top: 0,
                              child: SizedBox(
                                height: 48,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Image.asset(
                                      'assets/images/closeicon.png',
                                      width: 19,
                                      height: 19,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            backgroundColor: Colors.white,
                            itemExtent: 44,
                            scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                selectedIndex = index;
                              });
                            },
                            children: List.generate(restTimes.length, (i) {
                              final isSelected = i == selectedIndex;
                              return Center(
                                child: Text(
                                  restTimes[i],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'SF Pro Display',
                                    color: isSelected ? Colors.black : Colors.grey[400],
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24, top: 8),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Save', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
