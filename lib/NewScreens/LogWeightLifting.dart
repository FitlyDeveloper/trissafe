import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';

class WeightLiftingActive extends StatefulWidget {
  WeightLiftingActive({super.key});

  @override
  State<WeightLiftingActive> createState() => _WeightLifting();
}

class _WeightLifting extends State<WeightLiftingActive> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SizedBox(
        width: 393,
        height: 852,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              width: 393,
              top: 0,
              height: 852,
              child: Image.asset('assets/images/image1_22199.png', width: 393, height: 852, fit: BoxFit.cover,),
            ),
            Positioned(
              left: 101,
              top: 58,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Weight Lifting',
                      textAlign: TextAlign.left,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 26, color: const Color(0xff000000), fontFamily: 'SFProDisplay-Bold', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 38,
              width: 318,
              top: 109,
              height: 1,
              child: Container(
                width: 318,
                height: 1,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffbdbdbd), width: 0.5),
                ),
              ),
            ),
            Positioned(
              left: 30.622,
              width: 33.684,
              top: 68.5,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset('assets/images/image2_221103.png', width: 33.684,),
              ),
            ),
            Positioned(
              left: 38,
              width: 318,
              top: 180,
              height: 1,
              child: Container(
                width: 318,
                height: 1,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffbdbdbd), width: 0.5),
                ),
              ),
            ),
            Positioned(
              left: 37,
              top: 116,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Duration',
                      textAlign: TextAlign.left,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 16, color: const Color(0xff000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 160,
              top: 116,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Volume',
                      textAlign: TextAlign.left,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 16, color: const Color(0xff000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 297,
              top: 116,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'PRs',
                      textAlign: TextAlign.left,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 16, color: const Color(0xff000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 303,
              width: 30,
              top: 136,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            child: Text(
                              '0',
                              textAlign: TextAlign.left,
                              style: TextStyle(decoration: TextDecoration.none, fontSize: 16, color: const Color(0x87000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                              maxLines: 9999,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 171,
              top: 136,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '0 kg',
                      textAlign: TextAlign.center,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 16, color: const Color(0x87000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 55,
              top: 136,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '0 s',
                      textAlign: TextAlign.center,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 16, color: const Color(0x87000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 28,
              width: 331,
              top: 209,
              height: 193,
              child: Container(
                width: 331,
                height: 193,
                decoration: BoxDecoration(
                  color: const Color(0xffffffff),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: const Color(0x14000000), offset: Offset(0, 3), blurRadius: 8),],
                ),
              ),
            ),
            Positioned(
              left: 308,
              top: 63,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/images/image3_105065.png',),
              ),
            ),
            Positioned(
              left: 92,
              top: 226,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Bench Press (Barbell)',
                      textAlign: TextAlign.center,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 15, color: const Color(0xff000000), fontFamily: 'SFProDisplay-Bold', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 28,
              width: 72,
              top: 211,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/images/image4_105072.png', width: 72,),
              ),
            ),
            Positioned(
              left: 62,
              width: 266,
              top: 338,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/images/image5_105084.png', width: 266,),
              ),
            ),
            Positioned(
              left: 156,
              top: 345,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Add Set',
                      textAlign: TextAlign.left,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 17, color: const Color(0xffffffff), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 138,
              width: 19,
              top: 356,
              height: 19,
              child: Stack(
                children: [
                  Positioned(
                    left: -9.172,
                    width: 62.897,
                    top: -21.621,
                    height: 59.293,
                    child: Container(
                      width: 62.897,
                      height: 59.293,
                      decoration: BoxDecoration(
                        color: const Color(0xffffffff),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 37,
              top: 272,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'SET',
                      textAlign: TextAlign.center,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 14, color: const Color(0xff000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 46,
              width: 27,
              top: 303,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            child: Text(
                              '1',
                              textAlign: TextAlign.center,
                              style: TextStyle(decoration: TextDecoration.none, fontSize: 14, color: const Color(0xff000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                              maxLines: 9999,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 122,
              width: 27,
              top: 303,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            child: Text(
                              '-',
                              textAlign: TextAlign.center,
                              style: TextStyle(decoration: TextDecoration.none, fontSize: 14, color: const Color(0xff000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                              maxLines: 9999,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 93,
              top: 272,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'PREVIOUS',
                      textAlign: TextAlign.center,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 14, color: const Color(0xff000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 266,
              top: 272,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'REPS',
                      textAlign: TextAlign.center,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 14, color: const Color(0xff000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 205,
              top: 272,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'KG',
                      textAlign: TextAlign.center,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 14, color: const Color(0xff000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 279,
              width: 27,
              top: 304,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            child: Text(
                              '0',
                              textAlign: TextAlign.center,
                              style: TextStyle(decoration: TextDecoration.none, fontSize: 14, color: const Color(0xff000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                              maxLines: 9999,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 211,
              width: 27,
              top: 304,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            child: Text(
                              '0',
                              textAlign: TextAlign.center,
                              style: TextStyle(decoration: TextDecoration.none, fontSize: 14, color: const Color(0xff000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                              maxLines: 9999,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 329,
              width: 19,
              top: 312,
              height: 19,
              child: Stack(
                children: [
                  Positioned(
                    left: -3,
                    width: 26,
                    top: -1,
                    height: 22,
                    child: Container(
                      width: 26,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xff89ea4c),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              width: 358,
              top: 412,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/images/image6_105085.png', width: 358,),
              ),
            ),
            Positioned(
              left: 18,
              width: 185,
              top: 467,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/images/image7_105087.png', width: 185,),
              ),
            ),
            Positioned(
              left: 192,
              width: 184,
              top: 467,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/images/image8_105089.png', width: 184,),
              ),
            ),
            Positioned(
              left: 151,
              top: 421,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Add Exercise',
                      textAlign: TextAlign.left,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 17, color: const Color(0xffffffff), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 258,
              top: 477,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Finish',
                      textAlign: TextAlign.left,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 17, color: const Color(0xff000000), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 64,
              top: 477,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Discard Meal',
                      textAlign: TextAlign.left,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 17, color: const Color(0xffe97372), fontFamily: 'SFProDisplay-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 129.671,
              width: 19.527,
              top: 431.736,
              height: 19.527,
              child: Stack(
                children: [
                  Positioned(
                    left: -9.427,
                    width: 64.641,
                    top: -22.221,
                    height: 60.938,
                    child: Container(
                      width: 64.641,
                      height: 60.938,
                      decoration: BoxDecoration(
                        color: const Color(0xffffffff),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 221,
              top: 475,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/images/image9_105091.png',),
              ),
            ),
            Positioned(
              left: 38.947,
              width: 27.749,
              top: 480.625,
              height: 27.749,
              child: Stack(
                children: [
                  Positioned(
                    left: -8.222,
                    width: 41.11,
                    top: -7.194,
                    height: 39.054,
                    child: Container(
                      width: 41.11,
                      height: 39.054,
                      decoration: BoxDecoration(
                        color: const Color(0xffe97372),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 319,
              top: 271,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/images/image10_105082.png',),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
