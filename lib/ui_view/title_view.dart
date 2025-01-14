import '../fitness_app_theme.dart';
import 'package:flutter/material.dart';
import 'history_page.dart'; // Import the HistoryPage

class TitleView extends StatelessWidget {
  final String titleTxt;
  final String subTxt;
  final AnimationController? animationController;
  final Animation<double>? animation;

  const TitleView({
    super.key,
    this.titleTxt = "",
    this.subTxt = "",
    this.animationController,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    if (animationController == null || animation == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation!,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - animation!.value),
              0.0,
            ),
            child: Container(
              padding: const EdgeInsets.only(left: 24, right: 24),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      titleTxt,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontFamily: FitnessAppTheme.fontName,
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                        letterSpacing: 0.5,
                        color: FitnessAppTheme.lightText,
                      ),
                    ),
                  ),
                  InkWell(
                    highlightColor: Colors.transparent,
                    borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                    onTap: () {
                      if (subTxt.toLowerCase() == 'history') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  PastWorkoutsScreen(),
                          ),
                        );
                      } else {
                        // Handle other subTxt actions or leave empty
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Row(
                        children: <Widget>[
                          Text(
                            subTxt,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontFamily: FitnessAppTheme.fontName,
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                              letterSpacing: 0.5,
                              color: FitnessAppTheme.nearlyDarkBlue,
                            ),
                          ),
                          const SizedBox(
                            height: 38,
                            width: 26,
                            child: Icon(
                              Icons.arrow_forward,
                              color: FitnessAppTheme.darkText,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
