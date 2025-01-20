import 'package:fixcfinance/screens/add_transaksi.dart';
import 'package:fixcfinance/screens/edit_transaksi.dart';
import 'package:fixcfinance/screens/login_transaksi.dart';
import 'package:fixcfinance/service/api_delete.dart';
import 'package:fixcfinance/service/api_home.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String selectedTab = "Transaction"; // Tab aktif default adalah "Transaction"
  String activeButton = "All"; // Tombol aktif di bawah (default: "All")
  String selectedFilter = 'All'; // Filter aktif default

  List allTransactions = []; // Semua transaksi (all data)
  List userTransactions = []; // Transaksi user sendiri
  bool isLoading = true; // Indikator loading
  String idUser = ""; // ID user aktif

  String startDate = ''; // Tanggal awal rentang filter
  String endDate = ''; // Tanggal akhir rentang filter
  String idTipe = "";

  int totalIncome = 0; // Total pemasukan
  int totalExpense = 0; // Total pengeluaran
  int currentBalance = 0; // Saldo sekarang
  int transactionLimit = 10;

  bool _isWithinDateRange(String date) {
    if (startDate.isEmpty || endDate.isEmpty) {
      return true; // Jika tidak ada filter tanggal, tampilkan semua transaksi
    }

    final transactionDate = DateTime.parse(date);
    final startDateParsed = DateTime.parse(startDate);
    final endDateParsed = DateTime.parse(endDate);

    return transactionDate
            .isAfter(startDateParsed.subtract(Duration(days: 1))) &&
        transactionDate.isBefore(endDateParsed.add(Duration(days: 1)));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadUserId();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("Lifecycle state: $state");
    if (state == AppLifecycleState.resumed) {
      debugPrint("Fetching transactions...");
      fetchTransactions(); // Ambil ulang data
    }
  }

  void loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getString('id_user') ??
          "1"; // Default ke "1" jika tidak ditemukan
    });
    fetchTransactions();
    fetchTransactionsByType("1"); // Pemasukan
    fetchTransactionsByType("2"); // Pengeluaran
    // Ambil data setelah ID user di-set
  }

  void fetchTransactionsByType(String idTipe) async {
    setState(() {
      isLoading = true;
    });

    final response = await ApiHomeService.fetchTransactionsByType(idTipe);

    if (response['status'] == 'success' && response['data'] != null) {
      setState(() {
        final newTransactions =
            List<Map<String, dynamic>>.from(response['data']);
        for (var transaction in newTransactions) {
          if (!userTransactions
              .any((t) => t['id_transaksi'] == transaction['id_transaksi'])) {
            userTransactions.add(transaction);
          }
        }
        calculateTotals();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      debugPrint("Data received: ${response['data']}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? "Failed to load data")),
      );
    }
  }

  void fetchTransactions() async {
    setState(() {
      isLoading = true;
    });

    debugPrint("Fetching all transactions...");
    // Ambil semua transaksi
    final allDataResponse = await ApiHomeService.fetchAllTransactions();

    debugPrint("All Data Response: $allDataResponse");
    // Ambil transaksi user sendiri
    final userDataResponse = await ApiHomeService.fetchUserTransactions(idUser);
    if (allDataResponse['status'] == 'success' &&
        userDataResponse['status'] == 'success') {
      setState(() {
        debugPrint("Updating transactions...");
        // Update daftar transaksi dengan mencegah duplikasi
        allTransactions = [
          ...allTransactions,
          ...allDataResponse['data'].where((transaction) =>
              !allTransactions.any((existing) =>
                  existing['id_transaksi'] == transaction['id_transaksi']) &&
              _isWithinDateRange(transaction[
                  'tanggal_transaksi'])), // Tambahkan filter tanggal
        ];

        userTransactions = [
          ...userTransactions,
          ...userDataResponse['data'].where((transaction) =>
              !userTransactions.any((existing) =>
                  existing['id_transaksi'] == transaction['id_transaksi'])),
        ];

        // Debug data setelah pembaruan
        debugPrint("Updated All Transactions: $allTransactions");
        debugPrint("Updated User Transactions: $userTransactions");

        // Urutkan berdasarkan tanggal terbaru (descending)
        allTransactions.sort((a, b) {
          final dateA = DateTime.parse(a['tanggal_transaksi']);
          final dateB = DateTime.parse(b['tanggal_transaksi']);
          return dateB.compareTo(dateA);
        });

        userTransactions.sort((a, b) {
          final dateA = DateTime.parse(a['tanggal_transaksi']);
          final dateB = DateTime.parse(b['tanggal_transaksi']);
          return dateB.compareTo(dateA);
        });

        calculateTotals(); // Hitung ulang total setelah data diperbarui
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load transactions")),
      );
    }
  }

  void calculateTotals() {
    int income = 0;
    int expense = 0;

    for (var transaction in allTransactions) {
      int nominal = int.tryParse(transaction['nominal'].toString()) ?? 0;
      if (transaction['id_tipe'] == "1") {
        // 1 untuk Income
        income += nominal;
      } else if (transaction['id_tipe'] == "2") {
        // 2 untuk Expense
        expense += nominal;
      }
    }
    setState(() {
      totalIncome = income;
      totalExpense = expense;
      currentBalance = income - expense;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: startDate.isNotEmpty && endDate.isNotEmpty
          ? DateTimeRange(
              start: DateTime.parse(startDate),
              end: DateTime.parse(endDate),
            )
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = DateFormat('yyyy-MM-dd').format(picked.start);
        endDate = DateFormat('yyyy-MM-dd').format(picked.end);
        activeButton = "Tanggal";
      });

      debugPrint("Selected Start Date: $startDate, End Date: $endDate");

      // Panggil fungsi untuk memuat data berdasarkan filter tanggal
      // fetchTransactionsByDateRange(startDate, endDate);
    }
  }

  void fetchTransactionsByDateRange(String start, String end) async {
    setState(() {
      isLoading = true;
    });

    final response =
        await ApiHomeService.fetchTransactionsByDateRange(start, end);

    if (response['status'] == 'success' && response['data'] != null) {
      setState(() {
        // Reset daftar transaksi untuk menghindari duplikasi
        allTransactions.clear();
        userTransactions.clear();

        // Filter transaksi berdasarkan tanggal dan tambahkan data baru
        final filteredData = List<Map<String, dynamic>>.from(response['data'])
            .where((transaction) {
          final transactionDate =
              DateTime.parse(transaction['tanggal_transaksi']);
          final startDateParsed = DateTime.parse(start);
          final endDateParsed = DateTime.parse(end);
          return transactionDate
                  .isAfter(startDateParsed.subtract(Duration(days: 1))) &&
              transactionDate.isBefore(endDateParsed.add(Duration(days: 1)));
        }).toList();
        allTransactions.addAll(filteredData.where((transaction) =>
            !allTransactions.any((existing) =>
                existing['id_transaksi'] == transaction['id_transaksi'])));

        // Tambahkan ke userTransactions hanya jika milik user aktif
        userTransactions.addAll(filteredData
            .where((transaction) => transaction['id_user'] == idUser));

        // Set filter aktif dan hitung ulang total
        activeButton = 'Tanggal';
        // calculateTotals();
        fetchTransactions();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? "Failed to load data")),
      );
    }
  }

  String formatCurrency(int amount) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(amount);
  }

  void deleteTransaction(String idTransaksi) async {
    setState(() {
      isLoading = true;
    });

    // Panggil API untuk menghapus transaksi
    final response =
        await ApiHomeDeleteService.deleteTransaction(idUser, idTransaksi);

    if (response['status'] == true) {
      // Jika berhasil, hapus transaksi dari daftar lokal
      setState(() {
        allTransactions.removeWhere(
            (transaction) => transaction['id_transaksi'] == idTransaksi);
        userTransactions.removeWhere(
            (transaction) => transaction['id_transaksi'] == idTransaksi);
        calculateTotals(); // Hitung ulang total setelah penghapusan
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transaction deleted successfully")),
      );
    } else {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(response['message'] ?? "Failed to delete transaction")),
      );
    }
  }

  void _showTransactionDialog(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Detail Transaksi"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Deskripsi: ${transaction['deskripsi'] ?? 'No Description'}"),
              Text("Tanggal: ${transaction['tanggal_transaksi']}"),
              Text(
                  "Nominal: Rp ${formatCurrency(int.tryParse(transaction['nominal'].toString()) ?? 0)}"),
              Text(
                  "Tipe: ${transaction['id_tipe'] == '1' ? 'Pemasukan' : 'Pengeluaran'}"),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                print(
                    "Navigating to EditDataPage with transaction: $transaction");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditDataPage(transaction: transaction),
                  ),
                ).then((isUpdated) {
                  if (isUpdated == true) {
                    fetchTransactions(); // Muat ulang data jika ada perubahan
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Confirm Deletion"),
                      content: Text(
                          "Are you sure you want to delete this transaction?"),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context), // Tutup dialog konfirmasi
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Tutup dialog konfirmasi
                            deleteTransaction(transaction[
                                'id_transaksi']); // Panggil fungsi penghapusan
                          },
                          child: Text("Delete",
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Tutup"),
            ),
          ],
        );
      },
    );
  }

  //limit data
  Widget buildTransactionList(List transactions) {
    debugPrint("Transactions to display: $transactions");
    if (transactions.isEmpty) {
      return Center(
        child: Text("Tidak ada transaksi"),
      );
    }

    // Filter transaksi berdasarkan tab yang dipilih
    final filteredTransactions = selectedTab == "Your Transaction"
        ? transactions
            .where((transaction) => transaction['id_user'] == idUser)
            .toList()
        : transactions;

    // Batasi jumlah transaksi yang ditampilkan jika limit diaktifkan
    final limitedTransactions =
        filteredTransactions.take(transactionLimit).toList();

    if (limitedTransactions.isEmpty) {
      return Center(
        child: Text("Tidak ada transaksi"),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: limitedTransactions.length,
      itemBuilder: (context, index) {
        final transaction = limitedTransactions[index];
        return GestureDetector(
          onTap: () {
            if (selectedTab == "Your Transaction") {
              _showTransactionDialog(
                  transaction); // Tampilkan dialog hanya di tab "Your Transaction"
            }
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction['deskripsi'] ?? "No Description",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Tanggal: ${transaction['tanggal_transaksi']}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  "Rp ${formatCurrency(int.tryParse(transaction['nominal'].toString()) ?? 0)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction['id_tipe'] == "1"
                        ? Colors.green
                        : Colors.red,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildNavigationButton(String label) {
    return TextButton(
      onPressed: () async {
        if (label == 'Tanggal') {
          // Buka date picker untuk filter tanggal
          await _selectDateRange(context);
        } else if (label == 'All') {
          setState(() {
            // Reset filter tanggal
            startDate = '';
            endDate = '';
            activeButton = label; // Set tombol aktif ke "All"
          });
          fetchTransactions(); // Ambil semua transaksi
        } else if (label == 'Pemasukan' || label == 'Pengeluaran') {
          setState(() {
            activeButton = label; // Set tombol aktif ke label
            isLoading = true; // Tampilkan loading
          });

          // Tentukan id_tipe berdasarkan label
          String idTipe = label == 'Pemasukan' ? "1" : "2";

          // Fetch data berdasarkan id_tipe
          final response = await ApiHomeService.fetchTransactionsByType(idTipe);

          if (response['status'] == 'success') {
            setState(() {
              userTransactions =
                  List<Map<String, dynamic>>.from(response['data']);
              calculateTotals(); // Hitung ulang total pemasukan/pengeluaran
              isLoading = false;
            });
          } else {
            setState(() {
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(response['message'] ?? "Failed to load data")),
            );
          }
        }
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
          (states) => activeButton == label ? Colors.blue : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: activeButton == label ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800],
      appBar: AppBar(
        title: Text(
          'Hi, User',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: false,
        backgroundColor: Colors.blue[800],
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'logout',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.black),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
        // Pastikan ikon default juga putih
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: Colors.blue[800],
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Saldo Sekarang",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Rp ${formatCurrency(currentBalance)}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.arrow_upward,
                                      color: Colors.greenAccent, size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    "Pemasukan",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Rp ${formatCurrency(totalIncome)}",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.arrow_downward,
                                      color: Colors.redAccent, size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    "Pengeluaran",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Rp ${formatCurrency(totalExpense)}",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0), // Atur margin kanan dan kiri
                        padding: const EdgeInsets.all(
                            10), // Atur padding dalam kontainer
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedTab = "Transaction";
                                });
                              },
                              child: Column(
                                children: [
                                  Text(
                                    "Transaction",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: selectedTab == "Transaction"
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: selectedTab == "Transaction"
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                  if (selectedTab == "Transaction")
                                    Container(
                                      margin: EdgeInsets.only(top: 4),
                                      height: 2,
                                      width: 100,
                                      color: Colors.black,
                                    ),
                                ],
                              ),
                            ),
                            VerticalDivider(
                              color: Colors.grey,
                              thickness: 1,
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedTab = "Your Transaction";
                                });
                              },
                              child: Column(
                                children: [
                                  Text(
                                    "Your Transaction",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          selectedTab == "Your Transaction"
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color: selectedTab == "Your Transaction"
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                  if (selectedTab == "Your Transaction")
                                    Container(
                                      margin: EdgeInsets.only(top: 4),
                                      height: 2,
                                      width: 140,
                                      color: Colors.black,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(thickness: 1, color: Colors.grey[300]),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            buildNavigationButton("All"),
                            buildNavigationButton("Tanggal"),
                            buildNavigationButton("Pemasukan"),
                            buildNavigationButton("Pengeluaran"),
                          ],
                        ),
                      ),
                      Divider(thickness: 1, color: Colors.grey[300]),
                      Expanded(
                        child: isLoading
                            ? Center(child: CircularProgressIndicator())
                            : buildTransactionList(
                                selectedTab == "Transaction"
                                    ? (activeButton == "All"
                                        ? allTransactions
                                        : allTransactions.where((transaction) {
                                            if (activeButton == "Tanggal") {
                                              return _isWithinDateRange(
                                                  transaction[
                                                      'tanggal_transaksi']);
                                            }
                                            return activeButton == "Pemasukan"
                                                ? transaction['id_tipe'] ==
                                                    "1" // Filter pemasukan
                                                : transaction['id_tipe'] ==
                                                    "2"; // Filter pengeluaran
                                          }).toList())
                                    : (activeButton == "All"
                                        ? userTransactions
                                        : userTransactions.where((transaction) {
                                            if (activeButton == "Tanggal") {
                                              return _isWithinDateRange(
                                                  transaction[
                                                      'tanggal_transaksi']);
                                            }
                                            return activeButton == "Pemasukan"
                                                ? transaction['id_tipe'] ==
                                                    "1" // Filter pemasukan
                                                : transaction['id_tipe'] ==
                                                    "2"; // Filter pengeluaran
                                          }).toList()),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 4,
            left: 5,
            right: 5,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    child: Container(
                      width: 110,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/home.png',
                            width: 24,
                            height: 24,
                          ),
                          SizedBox(height: 5),
                          Text("Home", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddDataPage()),
                      ).then((_) {
                        fetchTransactions(); // Muat ulang data dari backend setelah transaksi baru
                      });
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/add.png',
                            width: 24,
                            height: 24,
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Add",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
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
  }
}
