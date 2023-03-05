import 'package:flutter/material.dart';
import 'package:reef/record/record_view.dart';
//import 'package:reef/timer/view/timer_list.dart';
import 'package:reef/timer/view/timer_view.dart';
import 'package:reef/search/search_view.dart';

//intlを使うときには地域情報の初期化が必要。main()で使う。
import 'package:intl/date_symbol_data_local.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _screens = [
    //TipsView(),
    //ScheduleView(),
    SearchView(),
    //TimerView(),
    RecordView(),
    TimerView(pomosec: 3, restsec: 3, isHided: false),
  ];

  int _selectedIndex = 2;
  bool isHided = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            /*
            BottomNavigationBarItem(
                icon: Icon(Icons.library_books), label: '勉強法を学ぶ'),
            BottomNavigationBarItem(icon: Icon(Icons.event), label: '計画を立てる'),
            */
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(
                icon: Icon(Icons.trending_up), label: 'Record'),
            BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Effort'),
          ],
          type: BottomNavigationBarType.fixed,
        ));
  }
}
