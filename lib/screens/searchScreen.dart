import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_coin/services/coinDetailService.dart';
import 'package:flutter_coin/services/coinSearchService.dart';
import 'package:flutter_coin/services/coinService.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class Searchscreen extends StatefulWidget {
  const Searchscreen({super.key});

  @override
  State<Searchscreen> createState() => _SearchscreenState();
}

class _SearchscreenState extends State<Searchscreen> {
  // เอาไปดึงข้อมูลทุก 10 วิ
  Timer? _timer;
  // เตรียมดึงข้อมูล getCoins
  final coinService = CoinService();
  // เอาไปเก็บค้าตั้งต้น
  List<dynamic> _coins = [];
  // เอาไปแสดงที่ ListView
  List<dynamic> _coinsShowList = [];

  // จับเหตุการณ์การ scroll
  final ScrollController _scrollController = ScrollController();
  // แสดง 10 รายการแรก
  int _displayCount = 10;
  // เลื่อนลงแล้วค่อยเปิดโหลด
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchCoins();
    // ดึงข้อมูลทุกๆ 10 วิ
    _startTimer();
    // ค่อยดูการ scroll ว่าตำแหน่งเลื่อนลงไปถึงไหนแล้ว
    _scrollController.addListener(_onScroll);
  }

  void _startTimer() {
    // ป้องกัน timer ซ้อน
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      print("timer" + timer.tick.toString());
      _fetchCoins();
    });
  }

  // ดึง API coins
  void _fetchCoins() async {
    try {
      final data = await coinService.getCoins();
      setState(() {
        // เอาไปเก็บค้าตั้งต้น
        _coins = data['coins'] ?? [];
        // เอาไปแสดงที่ ListView
        _coinsShowList = data['coins'] ?? [];
      });
    } catch (e) {
      print(
        '$e : API request limit. Generate a free API key: https://developers.coinranking.com/create-account',
      );
    }
  }

  void _onScroll() {
    // ตำแหน่งเลื่อนลงถึง 100 px ค่อยโหลด
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMore();
    }
  }

  void _loadMore() {
    // ถ้า search อยู่ ไม่ต้อง skip 3
    final list = _isSearchData
        ? _coinsShowList.skip(3).toList()
        : _coinsShowList;

    // โหลดอยู่ ไม่ต้องทำซ้ำ
    // แสดงครบ ไม่ต้องทำซ้ำ
    if (_isLoadingMore || _displayCount >= list.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    // หน่วง 300 ms ค่อยโหลด
    Timer(const Duration(milliseconds: 300), () {
      setState(() {
        // แสดงขึ้นอีก 10 แต่ไม่ให้เกินจำนวนรายการทั้งหมด
        _displayCount = (_displayCount + 10).clamp(0, list.length);
        _isLoadingMore = false;
      });
    });
  }

  // เตรียมดึงข้อมูล getCoinsSearch
  final coinSreachService = CoinSearchService();
  // เอาไว้เปิด-ปิด Top 3
  bool _isSearchData = true;
  // เอาไว้นัดเวลาตอนค้นหา เผื่อไม่ให้ถี่เกินไป
  Timer? _debounce;

  @override
  void dispose() {
    // ยังทำงานต่อใน background เลยกัน app crash
    _timer?.cancel();
    _debounce?.cancel();
    // ใช้ memory อยู่ตลอด ถ้าไม่ dispose จะทำให้ memory leak
    _scrollController.dispose();
    super.dispose();
  }

  // ค้นหา coins
  void _fetchCoinsSearch(String value) async {
    // ยกเลิก timer เดิม ถ้ายังไม่หมด
    _debounce?.cancel();

    // พิมพ์เสร็จค่อยจับเวลา 500 ms ก่อน search
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        if (value.isEmpty) {
          setState(() {
            // เปิด Top 3
            _isSearchData = true;
            // คืนค้าเดิมแสดง
            _coinsShowList = _coins;
            // reset displayCount กลับเมื่อ search ว่าง
            _displayCount = 10;
          });
          // เริ่ม timer ใหม่ตอน search ว่าง
          _startTimer();
          return;
        }

        // หยุด timer ก่อน กำลัง search อยู่
        _timer?.cancel();

        final data = await coinSreachService.getCoinsSearch(value);

        setState(() {
          // หาเจอก็เก็บไว้ _coinsShowList ไปแสดง
          _coinsShowList = data['coins'] ?? [];
          // ปิด Top 3
          _isSearchData = false;
          // reset displayCount เมื่อ search ใหม่
          _displayCount = 10;
        });
      } catch (e) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("API request limit."),
            content: Text(
              "Generate a free API key: https://developers.coinranking.com/create-account",
            ),
          ),
        );
      }
    });
  }

  // เตรียมดึงข้อมูล getCoinsDetail
  final coinDetailService = CoinDetailService();
  // เอาไปเก็บค้ารายละเอียด
  Map<String, dynamic>? _coinDetail;
  // ใช้เวลาโหลดนาน
  bool _isLoadingDetail = false;

  Future<void> _fetchCoinDetail(String uuid) async {
    try {
      setState(() => _isLoadingDetail = true);
      final data = await coinDetailService.getCoinsDetail(uuid);
      setState(() => _coinDetail = data['coin']);
    } catch (e) {
      print(
        '$e : API request limit. Generate a free API key: https://developers.coinranking.com/create-account',
      );
    } finally {
      setState(() => _isLoadingDetail = false);
    }
  }

  // แปลงหน่วยเงิน
  String formatMarketCap(dynamic value) {
    if (value == null) return '-';

    // แปลง value เป็น double ถ้าแปลงไม่ได้ให้เป็น 0
    final num = double.tryParse(value.toString()) ?? 0;

    // จาก 1e12 หลัง e คือ 0 มี 12 ตัว
    if (num >= 1e12) {
      return '\$ ${(num / 1e12).toStringAsFixed(2)} trillion';
    } else if (num >= 1e9) {
      return '\$ ${(num / 1e9).toStringAsFixed(2)} billion';
    } else if (num >= 1e6) {
      return '\$ ${(num / 1e6).toStringAsFixed(2)} million';
    } else {
      return '\$ ${num.toStringAsFixed(2)}';
    }
  }

  // จะให้ value ตอน search ที่ ui หายไปด้วย
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // ถ้า search อยู่ _isSearchData = false ไม่ต้อง skip Top 3
    final displayList = _isSearchData
        ? _coinsShowList.skip(3).toList()
        : _coinsShowList;

    // จำนวนที่จะแสดงจริง ไม่ให้เกินขนาด list
    final safeCount = displayList.length < _displayCount
        ? displayList.length
        : _displayCount;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ช่องค้นหา
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(borderSide: BorderSide.none),
                hintText: 'Search',
                filled: true,
                fillColor: const Color(0xFFEEEEEE),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _fetchCoinsSearch("");
                  },
                ),
              ),
              onChanged: (value) => _fetchCoinsSearch(value.toLowerCase()),
            ),

            const SizedBox(height: 15),
            const Divider(height: 10),
            const SizedBox(height: 15),

            // ถ้าค้นหาก็ปิด Top 3
            if (_isSearchData)
              Column(
                // เริ่มซ้าย
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // หัวข้อ Top 3 rank crypto ทำให้เลข 3 สีแดง
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(text: 'Top '),
                        TextSpan(
                          text: '3',
                          style: TextStyle(color: Colors.red),
                        ),
                        TextSpan(text: ' rank crypto'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // _coins ยังเป็น [] ค่าว่างอยู่ เลยดักไว้
                  if (_coins.length >= 3)
                    // แสดง Top 3 แบบ horizontal scroll
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemBuilder: (context, index) {
                          final coin = _coins[index];
                          final change = double.parse(coin['change'] ?? '0');
                          final iconUrl = coin['iconUrl'] ?? '';

                          return GestureDetector(
                            onTap: () =>
                                _showBottomSheet(context, coin["uuid"]),
                            child: Container(
                              width: 130,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E0FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // icon เหรียญ (รองรับทั้ง svg และ image)
                                  iconUrl.endsWith('.svg')
                                      ? SvgPicture.network(
                                          iconUrl,
                                          height: 50,
                                          width: 50,
                                          errorBuilder:
                                              (context, error, stack) =>
                                                  const Icon(
                                                    Icons.monetization_on,
                                                    size: 50,
                                                  ),
                                        )
                                      : Image.network(
                                          iconUrl,
                                          height: 50,
                                          width: 50,
                                          errorBuilder:
                                              (context, error, stack) =>
                                                  const Icon(
                                                    Icons.monetization_on,
                                                    size: 50,
                                                  ),
                                        ),
                                  const SizedBox(height: 8),

                                  // ชื่อย่อเหรียญ
                                  Text(
                                    coin['symbol'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // ชื่อเต็มเหรียญ
                                  Text(
                                    coin['name'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // badge แสดง % การเปลี่ยนแปลง (เขียว/แดง)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: change >= 0
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 10),

            // แสดงรายการ coin
            if (_coinsShowList.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // หัวข้อ list หลัก
                    const Text(
                      'Buy, sell and hold crypto',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // list เหรียญทั้งหมด
                    Expanded(
                      // ดึงโหลดข้อมูล
                      child: RefreshIndicator(
                        onRefresh: () async {
                          // reset กลับ 10 รายการแรกใหม่
                          setState(() {
                            _displayCount = 10;
                          });
                          _fetchCoins();
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          // ใช้ safeCount ที่คำนวณมา ป้องกัน index เกิน
                          itemCount: safeCount + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // แสดง loading indicator ท้ายสุด
                            if (index == safeCount) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            // ใช้ displayList ที่ดึงมาแล้ว
                            final coin = displayList[index];
                            final change = double.parse(coin['change'] ?? '0');
                            final iconUrl = coin['iconUrl'] ?? '';

                            return Container(
                              margin: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: const Color(0xffF8DAF7),
                              ),
                              child: ListTile(
                                onTap: () =>
                                    _showBottomSheet(context, coin["uuid"]),
                                leading: iconUrl.endsWith('.svg')
                                    ? SvgPicture.network(
                                        iconUrl,
                                        height: 36,
                                        width: 36,
                                        placeholderBuilder: (context) =>
                                            const SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                        errorBuilder: (context, error, stack) =>
                                            const Icon(
                                              Icons.monetization_on,
                                              size: 36,
                                            ),
                                      )
                                    : Image.network(
                                        iconUrl,
                                        height: 36,
                                        width: 36,
                                        errorBuilder: (context, error, stack) =>
                                            const Icon(
                                              Icons.monetization_on,
                                              size: 36,
                                            ),
                                      ),
                                title: Text(coin['name'] ?? ''),
                                subtitle: Text(coin['symbol'] ?? ''),
                                trailing: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '\$${double.parse(coin['price']).toStringAsFixed(5)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          change >= 0
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          size: 14,
                                          color: change >= 0
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        Text(
                                          '${change.toStringAsFixed(2)}%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: change >= 0
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // หารายการไม่เจอ
            if (_coinsShowList.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image(
                        image: const AssetImage('assets/images/search.jpg'),
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                      const Text(
                        'Sorry',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const Text(
                        'No result match for this keyword',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context, String uuid) async {
    // เรียก api รายละเอียดเหรียญ
    await _fetchCoinDetail(uuid);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // มุมโค้งด้านบน
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // ถ้ายังโหลดอยู่ แสดง loading
          if (_isLoadingDetail || _coinDetail == null) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final coin = _coinDetail!;
          final iconUrl = coin['iconUrl'] ?? '';
          final color = coin['color']?.replaceAll('#', '0xFF');

          // ลากขึ้นลง
          return DraggableScrollableSheet(
            // เปิดมาครั้งแรก | minChildSize <= initialChildSize <= maxChildSize | 0.1 = 10%
            initialChildSize: 0.4,
            minChildSize: 0.3, // ลากลงปิด
            maxChildSize: 0.9, // ลากขึ้นปิด
            expand: false, // ไม่ขยายเต็มพื้นที่
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header: icon + ชื่อ + ราคา + market cap
                  Row(
                    children: [
                      // icon เหรียญ
                      iconUrl.endsWith('.svg')
                          ? SvgPicture.network(
                              iconUrl,
                              height: 60,
                              width: 60,
                              errorBuilder: (context, error, stack) =>
                                  const Icon(Icons.monetization_on, size: 60),
                            )
                          : Image.network(
                              iconUrl,
                              height: 60,
                              width: 60,
                              errorBuilder: (context, error, stack) =>
                                  const Icon(Icons.monetization_on, size: 60),
                            ),

                      const SizedBox(width: 16),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ชื่อเหรียญ + ชื่อย่อ
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: coin['name'],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(
                                      int.parse(color ?? 'FF808080'),
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: ' (${coin['symbol']})',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ราคาปัจจุบัน
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'PRICE  ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '\$ ${double.parse(coin['price']).toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 4),

                          // กดเปิดเว็บ
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'MARKET CAP  ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: formatMarketCap(coin['marketCap']),
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // คำอธิบายเหรียญ
                  Text(
                    coin['description'] ?? '',
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 10),
                  // ปุ่มไปยังเว็บไซต์
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () async {
                        final url = Uri.parse(coin['coinrankingUrl'] ?? '');
                        if (await canLaunchUrl(url)) {
                          // เปิดเว็บภายในแอป
                          await launchUrl(url, mode: LaunchMode.inAppWebView);
                        }
                      },
                      child: const Text(
                        'GO TO WEBSITE',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
