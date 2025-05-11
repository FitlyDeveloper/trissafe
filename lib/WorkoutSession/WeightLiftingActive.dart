import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import '../NewScreens/AddExercise.dart';
import 'package:flutter/cupertino.dart';
import '../Screens/WeightLifting.dart';
import 'package:flutter/services.dart';
import '../NewScreens/ExerciseInfo.dart';

// Model for exercise sets
class ExerciseSet {
  int kg;
  int reps;
  bool isCompleted;

  ExerciseSet({
    this.kg = 0,
    this.reps = 0,
    this.isCompleted = false,
  });
}

// Extended Exercise model to include sets
class ExerciseWithSets {
  final String name;
  final String muscle;
  final String equipment;
  List<ExerciseSet> sets;

  ExerciseWithSets({
    required this.name,
    required this.muscle,
    required this.equipment,
    List<ExerciseSet>? sets,
  }) : sets = sets ?? [ExerciseSet()]; // Initialize with one empty set

  // Convert from basic Exercise
  factory ExerciseWithSets.fromExercise(Exercise exercise) {
    return ExerciseWithSets(
      name: exercise.name,
      muscle: exercise.muscle,
      equipment: exercise.equipment,
    );
  }
}

class WeightLiftingActive extends StatefulWidget {
  final List<Exercise> selectedExercises;
  const WeightLiftingActive({Key? key, this.selectedExercises = const []}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WeightLiftingActive();
}

class _WeightLiftingActive extends State<WeightLiftingActive> with TickerProviderStateMixin {
  late List<ExerciseWithSets> _exercises;
  final Map<String, TextEditingController> _controllers = {};
  // Add focus nodes map to track focus state
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _initializeExercises();
  }

  void _initializeExercises() {
    _exercises = widget.selectedExercises
        .map((e) => ExerciseWithSets.fromExercise(e))
        .toList();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Clear existing controllers and focus nodes
    _controllers.values.forEach((controller) => controller.dispose());
    _focusNodes.values.forEach((node) => node.dispose());
    _controllers.clear();
    _focusNodes.clear();
    
    // Create new controllers and focus nodes with default values
    for (int i = 0; i < _exercises.length; i++) {
      for (int j = 0; j < _exercises[i].sets.length; j++) {
        final kgKey = 'kg_${i}_${j}';
        final repsKey = 'reps_${i}_${j}';
        
        // Always initialize with '0'
        _controllers[kgKey] = TextEditingController(text: '0');
        _controllers[repsKey] = TextEditingController(text: '0');
        
        // Ensure exercise set values match
        _exercises[i].sets[j].kg = 0;
        _exercises[i].sets[j].reps = 0;
        
        _focusNodes[kgKey] = FocusNode();
        _focusNodes[repsKey] = FocusNode();
        
        _focusNodes[kgKey]?.addListener(() => _handleFocusChange(kgKey, i, j, true));
        _focusNodes[repsKey]?.addListener(() => _handleFocusChange(repsKey, i, j, false));
      }
    }
  }

  void _handleFocusChange(String key, int exerciseIndex, int setIndex, bool isKg) {
    final focusNode = _focusNodes[key];
    final controller = _controllers[key];
    
    if (focusNode != null && controller != null) {
      if (!focusNode.hasFocus) {
        // Field lost focus - ensure it shows 0 if empty
        if (controller.text.isEmpty) {
          setState(() {
            controller.text = '0';
            if (isKg) {
              _exercises[exerciseIndex].sets[setIndex].kg = 0;
            } else {
              _exercises[exerciseIndex].sets[setIndex].reps = 0;
            }
          });
        }
      } else {
        // Field gained focus - clear only if it's 0
        if (controller.text == '0') {
          controller.clear();
        }
      }
    }
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      final newSetIndex = _exercises[exerciseIndex].sets.length;
      _exercises[exerciseIndex].sets.add(ExerciseSet());
      
      // Initialize new set controllers with '0' as default
      final kgKey = 'kg_${exerciseIndex}_${newSetIndex}';
      final repsKey = 'reps_${exerciseIndex}_${newSetIndex}';
      
      _controllers[kgKey] = TextEditingController(text: '0');
      _controllers[repsKey] = TextEditingController(text: '0');
      
      _focusNodes[kgKey] = FocusNode();
      _focusNodes[repsKey] = FocusNode();
      
      _focusNodes[kgKey]?.addListener(() => _handleFocusChange(kgKey, exerciseIndex, newSetIndex, true));
      _focusNodes[repsKey]?.addListener(() => _handleFocusChange(repsKey, exerciseIndex, newSetIndex, false));
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    _focusNodes.values.forEach((node) => node.dispose());
    _controllers.clear();
    _focusNodes.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(WeightLiftingActive oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize if the selected exercises changed
    if (oldWidget.selectedExercises != widget.selectedExercises) {
      _initializeExercises();
    }
  }

  void _updateSet(int exerciseIndex, int setIndex, {int? kg, int? reps, bool? isCompleted}) {
    setState(() {
      final set = _exercises[exerciseIndex].sets[setIndex];
      if (kg != null) {
        set.kg = kg;
        _controllers['kg_${exerciseIndex}_${setIndex}']?.text = kg.toString();
      }
      if (reps != null) {
        set.reps = reps;
        _controllers['reps_${exerciseIndex}_${setIndex}']?.text = reps.toString();
      }
      if (isCompleted != null) set.isCompleted = isCompleted;
    });
  }

  Future<void> _addExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CodiaPage()),
    );
    if (result != null && result is List<Exercise>) {
      setState(() {
        // Convert new exercises to ExerciseWithSets with default values
        final newExercises = result.map((e) {
          final exercise = ExerciseWithSets.fromExercise(e);
          // Initialize all sets with default values
          exercise.sets = [ExerciseSet(kg: 0, reps: 0, isCompleted: false)];
          return exercise;
        }).toList();
        
        _exercises.addAll(newExercises);
        
        // Initialize controllers for new exercises
        for (int i = _exercises.length - newExercises.length; i < _exercises.length; i++) {
          for (int j = 0; j < _exercises[i].sets.length; j++) {
            final kgKey = 'kg_${i}_${j}';
            final repsKey = 'reps_${i}_${j}';
            
            _controllers[kgKey] = TextEditingController(text: '0');
            _controllers[repsKey] = TextEditingController(text: '0');
            
            _focusNodes[kgKey] = FocusNode();
            _focusNodes[repsKey] = FocusNode();
            
            _focusNodes[kgKey]?.addListener(() => _handleFocusChange(kgKey, i, j, true));
            _focusNodes[repsKey]?.addListener(() => _handleFocusChange(repsKey, i, j, false));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background4.jpg',
          fit: BoxFit.cover,
        ),
      ),
          SafeArea(
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
                            opaque: false,
                            pageBuilder: (context, animation, secondaryAnimation) => WeightLifting(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return Stack(
                                children: [
                                  child,
                                  SlideTransition(
                                    position: Tween<Offset>(
                                      begin: Offset.zero,
                                      end: const Offset(1.0, 0.0),
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOut,
                                    )),
                                    child: Container(
                                      color: Colors.transparent,
                                      child: this.widget,
                                    ),
                                  ),
                                ],
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
                // Exercise Cards and Bottom Buttons Container
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 0,
                      bottom: 0,
                    ),
                    children: [
              // Exercise Cards
                      ...List.generate(_exercises.length, (idx) {
                    final exercise = _exercises[idx];
                    return Padding(
                          padding: EdgeInsets.only(bottom: 18),
                          child: Stack(
                            children: [
                              Container(
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
                                  // 3-dot menu icon in header, aligned with title
                                  Material(
                                    color: Colors.white.withOpacity(0.7),
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      splashColor: Colors.grey[300],
                                      highlightColor: Colors.grey[200],
                                      onTap: () => _showExerciseMenu(context, idx),
                                      child: SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: Center(
                                          child: Image.asset(
                                            'assets/images/more2.png',
                                            width: 21.6,
                                            height: 21.6,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
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
                                      // Dynamic set rows
                                      ...List.generate(_exercises[idx].sets.length, (setIndex) {
                                        final set = _exercises[idx].sets[setIndex];
                                        // Find the most recent completed set before this one
                                        String previousText = '-';
                                        for (int prev = setIndex - 1; prev >= 0; prev--) {
                                          final prevSet = _exercises[idx].sets[prev];
                                          if (prevSet.isCompleted) {
                                            previousText = '${prevSet.kg}kg x ${prevSet.reps}';
                                            break;
                                          }
                                        }
                                        return Column(
                                          children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                                Expanded(flex: 2, child: Text('${setIndex + 1}', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400))),
                                  SizedBox(width: 8),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    previousText,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black.withOpacity(0.5),
                                                      fontWeight: FontWeight.w400,
                                                      fontFamily: '.SF Pro Display',
                                                    ),
                                                  ),
                                                ),
                                  SizedBox(width: 8),
                                                Expanded(
                                                  flex: 2,
                                                  child: TextField(
                                                    controller: _controllers['kg_${idx}_${setIndex}'],
                                                    focusNode: _focusNodes['kg_${idx}_${setIndex}'],
                                                    keyboardType: TextInputType.number,
                                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                    textAlign: TextAlign.center,
                                                    cursorColor: Colors.black,
                                                    cursorWidth: 1.2,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.w400,
                                                      fontFamily: '.SF Pro Display',
                                                    ),
                                                    decoration: InputDecoration(
                                                      isDense: true,
                                                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                                                      border: InputBorder.none,
                                                      enabledBorder: InputBorder.none,
                                                      focusedBorder: InputBorder.none,
                                                    ),
                                                    onChanged: (value) {
                                                      if (value.isNotEmpty) {
                                                        final controller = _controllers['kg_${idx}_${setIndex}'];
                                                        _updateSet(idx, setIndex, kg: int.parse(value));
                                                        controller?.selection = TextSelection.fromPosition(
                                                          TextPosition(offset: controller?.text.length ?? 0),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),
                                  SizedBox(width: 8),
                                                Expanded(
                                                  flex: 2,
                                                  child: TextField(
                                                    controller: _controllers['reps_${idx}_${setIndex}'],
                                                    focusNode: _focusNodes['reps_${idx}_${setIndex}'],
                                                    keyboardType: TextInputType.number,
                                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                    textAlign: TextAlign.center,
                                                    cursorColor: Colors.black,
                                                    cursorWidth: 1.2,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.w400,
                                                      fontFamily: '.SF Pro Display',
                                                    ),
                                                    decoration: InputDecoration(
                                                      isDense: true,
                                                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                                                      border: InputBorder.none,
                                                      enabledBorder: InputBorder.none,
                                                      focusedBorder: InputBorder.none,
                                                    ),
                                                    onChanged: (value) {
                                                      if (value.isNotEmpty) {
                                                        final controller = _controllers['reps_${idx}_${setIndex}'];
                                                        _updateSet(idx, setIndex, reps: int.parse(value));
                                                        controller?.selection = TextSelection.fromPosition(
                                                          TextPosition(offset: controller?.text.length ?? 0),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Align(
                                                    alignment: Alignment.centerRight,
                                                    child: GestureDetector(
                                                      onTap: () => _updateSet(idx, setIndex, isCompleted: !set.isCompleted),
                                                      child: Icon(
                                                        set.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                                                        color: set.isCompleted ? Color(0xFF34C759) : Colors.grey[400],
                                                        size: 24,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (setIndex < _exercises[idx].sets.length - 1) SizedBox(height: 12),
                                          ],
                                        );
                                      }),
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
                                                    return Color(0xFF6D6D6D);
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                            onPressed: () => _addSet(idx),
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
                            ],
                          ),
                        );
                      }),
                      
                      // Bottom Buttons Section - Part of scrollable content
                      Padding(
                        padding: EdgeInsets.only(top: 18, bottom: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
              // Add Exercise Button
                            Container(
                  height: 48,
                              margin: EdgeInsets.symmetric(horizontal: 9),
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
              SizedBox(height: 20),
                            // Discard and Finish Buttons
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 9),
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
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => WeightLifting()),
                              );
                            },
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        ],
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

  void _showExerciseMenu(BuildContext context, int exerciseIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withOpacity(0.18),
      isScrollControlled: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItem(context, 'Exercise Info', 'assets/images/CircleMenu.png', onTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseInfo(
                    exerciseName: _exercises[exerciseIndex].name,
                    muscle: _exercises[exerciseIndex].muscle,
                    // Add other fields as needed
                  ),
                ),
              );
            }),
            SizedBox(height: 8),
            _buildMenuItem(context, 'Replace Exercise', 'assets/images/replace.png', onTap: () async {
              Navigator.of(context).pop();
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CodiaPage()),
              );
              if (result != null && result is List<Exercise> && result.isNotEmpty) {
                setState(() {
                  _exercises[exerciseIndex] = ExerciseWithSets.fromExercise(result.first);
                });
              }
            }),
            SizedBox(height: 8),
            _buildMenuItem(context, 'Delete Exercise', 'assets/images/trashcan.png', isDelete: true, onTap: () {
              Navigator.of(context).pop();
              _showDeleteConfirmation(context, exerciseIndex);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, String iconAsset, {bool isDelete = false, VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap ?? () => Navigator.of(context).pop(),
      child: Container(
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Image.asset(
              iconAsset,
              width: 20,
              height: 20,
              color: isDelete ? Color(0xFFE97372) : Colors.black,
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isDelete ? Color(0xFFE97372) : Colors.black,
                fontSize: 16,
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int exerciseIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withOpacity(0.18),
      isScrollControlled: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Delete Exercise?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF Pro Display',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Color(0xFFE97372)),
                        ),
                      ),
                      icon: Image.asset('assets/images/closeicon.png', width: 20, height: 20, color: Colors.grey[600]),
                      onPressed: () => Navigator.of(context).pop(),
                      label: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE97372),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Image.asset('assets/images/trashcan.png', width: 20, height: 20, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _exercises.removeAt(exerciseIndex);
                        });
                        Navigator.of(context).pop();
                      },
                      label: Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
