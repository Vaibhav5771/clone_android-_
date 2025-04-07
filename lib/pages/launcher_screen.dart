import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Add this import
import 'home_page.dart';

class LauncherScreen extends StatefulWidget {
  final bool autoLogin;

  const LauncherScreen({super.key, this.autoLogin = false});

  @override
  _LauncherScreenState createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    print('LauncherScreen init');
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        print('Animation completed');
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) {
            print('Navigating to HomePage');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }
        });
      }
    });

    print('Starting animation');
    _controller.forward();
  }

  @override
  void dispose() {
    print('LauncherScreen dispose started');
    _controller.stop();
    _controller.dispose();
    super.dispose();
    print('LauncherScreen dispose completed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/Logo.svg',
                width: 120, // Match your size
                height: 100,
              ),
              SizedBox(height: 15),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Color(0xFF56F8FA), Color(0xFF3388D7)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                child: Text(
                  "Transforming the way\nyou print",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: Colors.white, // Base color (gradient overrides this)
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}