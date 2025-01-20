import 'package:fixcfinance/service/api_add.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddDataPage extends StatefulWidget {
  @override
  _AddDataPageState createState() => _AddDataPageState();
}

class _AddDataPageState extends State<AddDataPage> {
  bool isIncome = true; // Default tipe transaksi adalah Income
  String? selectedCategory; // Kategori yang dipilih
  DateTime? selectedDate; // Tanggal yang dipilih
  TextEditingController nominalController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  String? userId;

  List<dynamic> categories = []; // Daftar kategori
  bool isLoadingCategories = true; // Indikator loading kategori

  @override
  void initState() {
    super.initState();
    fetchUserId();
    fetchCategories(); // Ambil data kategori saat halaman dimuat
  }

  // Fungsi untuk mendapatkan id_user dari SharedPreferences
  void fetchUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('id_user');
    });
  }

  // Fungsi untuk mengambil data kategori dari API
  void fetchCategories() async {
    setState(() {
      isLoadingCategories = true;
    });

    // Ambil data kategori
    final fetchedCategories = await ApiService.fetchCategories();
    print("Fetched Categories in AddDataPage: $fetchedCategories");

    setState(() {
      // Filter kategori berdasarkan tipe transaksi (Income/Expenses)
      categories = fetchedCategories
          .where((category) => category['id_tipe'] == (isIncome ? "1" : "2"))
          .toList();

      // Set default kategori jika tersedia
      if (categories.isNotEmpty) {
        selectedCategory = categories[0]['id_kategori'].toString();
      }
      isLoadingCategories = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.blue[800],
      appBar: AppBar(
        title: Text(
          'Tambahkan Data',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        // Menambahkan ikon back
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Kembali ke halaman sebelumnya
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 30),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    // Tambahkan SingleChildScrollView
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Toggle Income/Expenses
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Switch(
                                value: isIncome,
                                onChanged: (value) {
                                  setState(() {
                                    isIncome = value;
                                    fetchCategories(); // Refresh kategori saat tipe berubah
                                  });
                                },
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.red,
                                inactiveTrackColor: Colors.red.withOpacity(0.5),
                              ),
                              Text(
                                isIncome ? "Income" : "Expenses",
                                style: TextStyle(
                                  color: isIncome ? Colors.green : Colors.red,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          // Input Nominal
                          Text(
                            "Nominal",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: nominalController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "Masukkan nominal",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                          ),
                          SizedBox(height: 20),

                          // Dropdown Kategori
                          Text(
                            "Kategori",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          isLoadingCategories
                              ? CircularProgressIndicator()
                              : categories.isEmpty
                                  ? Center(
                                      child: Text("Kategori tidak tersedia"))
                                  : DropdownButtonFormField<String>(
                                      value: selectedCategory,
                                      items: categories.map((category) {
                                        return DropdownMenuItem(
                                          value: category['id_kategori']
                                              .toString(),
                                          child:
                                              Text(category['nama_kategori']),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedCategory = value!;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[200],
                                      ),
                                    ),
                          SizedBox(height: 20),

                          // Input Tanggal
                          Text(
                            "Tanggal",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          InkWell(
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  selectedDate = pickedDate;
                                });
                              }
                            },
                            child: Container(
                              height: 50,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedDate == null
                                        ? "Pilih tanggal"
                                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                  Icon(Icons.calendar_today,
                                      color: Colors.blue),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // Input Deskripsi
                          Text(
                            "Deskripsi",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: descriptionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: "Tambahkan deskripsi",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                          ),
                          SizedBox(height: 20),

                          // Tombol Simpan
                          Center(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (nominalController.text.isEmpty ||
                                    selectedDate == null ||
                                    selectedCategory == null ||
                                    userId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text("Semua kolom wajib diisi")),
                                  );
                                  return;
                                }

                                final formattedDate =
                                    "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

                                final success = await ApiService.addTransaction(
                                  idUser:
                                      userId!, // Gunakan id_user dari SharedPreferences
                                  idTipe: isIncome ? "1" : "2",
                                  idKategori: selectedCategory!,
                                  nominal: nominalController.text,
                                  tanggalTransaksi: formattedDate,
                                  deskripsi: descriptionController.text.isEmpty
                                      ? null
                                      : descriptionController.text,
                                );

                                if (success) {
                                  // Membuat objek transaksi baru yang akan dikembalikan ke halaman sebelumnya
                                  final newTransaction = {
                                    'id_tipe': isIncome
                                        ? "1"
                                        : "2", // 1 untuk Income, 2 untuk Expenses
                                    'id_kategori':
                                        selectedCategory, // ID kategori yang dipilih
                                    'nominal': nominalController
                                        .text, // Nominal transaksi
                                    'tanggal_transaksi':
                                        formattedDate, // Tanggal transaksi (format: yyyy-MM-dd)
                                    'deskripsi':
                                        descriptionController.text.isEmpty
                                            ? null
                                            : descriptionController
                                                .text, // Deskripsi (opsional)
                                  };

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "Transaksi berhasil ditambahkan"),
                                    ),
                                  );

                                  // Kembalikan data transaksi baru ke halaman sebelumnya
                                  Navigator.pop(context, newTransaction);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text("Gagal menambahkan transaksi"),
                                    ),
                                  );
                                }
                              },
                              child: Text("Simpan"),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
