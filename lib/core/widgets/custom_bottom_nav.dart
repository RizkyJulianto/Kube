import 'package:flutter/material.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/order/ui/order_screen.dart';
import '../../features/history/ui/history_screen.dart';
import '../../theme/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return; // Nggak perlu reload kalau diklik tab yang sama

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const HomeScreen();
        break;
      case 1:
        nextScreen = const OrderScreen();
        break;
      case 2:
        nextScreen = const Scaffold(body: Center(child: Text('Halaman Lacak')));
        break;
      case 3:
        nextScreen = const HistoryScreen();
        break;
      default:
        return;
    }

    // Pindah halaman tanpa menumpuk backstack & tanpa animasi slide
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => nextScreen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.cerulean,
      unselectedItemColor: AppColors.black50,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_filled),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
          label: 'Pesan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.alt_route_outlined),
          activeIcon: Icon(Icons.alt_route_rounded),
          label: 'Lacak',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history_rounded),
          label: 'Riwayat',
        ),
      ],
    );
  }
}