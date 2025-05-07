import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import '../NewScreens/AddExercise.dart';

class WeightLiftingActive extends StatefulWidget {
  final List<Exercise> selectedExercises;
  const WeightLiftingActive({Key? key, this.selectedExercises = const []}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WeightLiftingActive();
}

class _WeightLiftingActive extends State<WeightLiftingActive> {
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
                      onPressed: () => Navigator.pop(context),
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
                    Image.asset('assets/images/Stopwatch.png', width: 24, height: 24),
                  ],
                ),
              ),
              // Slim divider line
              Container(
                margin: EdgeInsets.symmetric(horizontal: 29),
                height: 1,
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
                height: 1,
                color: Color(0xFFBDBDBD),
              ),
              SizedBox(height: 12),
              // Exercise Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
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
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bench Press (Barbell)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                                  Text('Chest', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            Icon(Icons.bookmark_border, color: Colors.black, size: 22),
                            SizedBox(width: 8),
                            Icon(Icons.check_circle, color: Colors.green, size: 22),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Text('SET', style: TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold))),
                            Expanded(child: Text('PREVIOUS', style: TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold))),
                            Expanded(child: Text('KG', style: TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold))),
                            Expanded(child: Text('REPS', style: TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold))),
                            Icon(Icons.check, color: Colors.black, size: 18),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: Text('1', style: TextStyle(fontSize: 14, color: Colors.black))),
                            Expanded(child: Text('-', style: TextStyle(fontSize: 14, color: Colors.black))),
                            Expanded(child: Text('0', style: TextStyle(fontSize: 14, color: Colors.black))),
                            Expanded(child: Text('0', style: TextStyle(fontSize: 14, color: Colors.black))),
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                          ],
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: SizedBox(
                            width: 246,
                            height: 33,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF908F8F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 2,
                              ),
                              onPressed: () {},
                              child: Text('+ Add Set', style: TextStyle(color: Colors.white, fontSize: 15)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18),
              // Add Exercise Button
              Center(
                child: SizedBox(
                  width: 338,
                  height: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {},
                    icon: Icon(Icons.add, color: Colors.white),
                    label: Text('Add Exercise', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ),
              Spacer(),
              // Bottom Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () {},
                          icon: Icon(Icons.delete_outline, color: Color(0xFFE97372)),
                          label: Text('Discard Meal', style: TextStyle(color: Color(0xFFE97372), fontSize: 15)),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () {},
                          icon: Icon(Icons.check, color: Colors.black),
                          label: Text('Finish', style: TextStyle(color: Colors.black, fontSize: 15)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
