import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/api_edit.dart';

class EditDataPage extends StatefulWidget {
  final Map<String, dynamic> transaction;

  EditDataPage({required this.transaction});

  @override
  _EditDataPageState createState() => _EditDataPageState();
}

class _EditDataPageState extends State<EditDataPage> {
  bool isIncome = true;
  String? selectedCategory;
  DateTime? selectedDate;
  TextEditingController nominalController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  String? userId;

  List<dynamic> categories = [];
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();

    // Debugging untuk memeriksa data transaksi yang diterima
    print("Transaction data received: ${widget.transaction}");

    // Inisialisasi data transaksi
    nominalController.text = widget.transaction['nominal'] ?? '';
    descriptionController.text = widget.transaction['deskripsi'] ?? '';
    selectedCategory = widget.transaction['id_kategori']?.toString();
    isIncome = widget.transaction['id_tipe'] == "1";
    selectedDate =
        DateTime.tryParse(widget.transaction['tanggal_transaksi'] ?? '');

    fetchUserId();
    fetchCategories();
  }

  void fetchUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('id_user');
    });
  }

  void fetchCategories() async {
    setState(() {
      isLoadingCategories = true;
    });

    // Simulasi fetch kategori dari API
    final fetchedCategories = await ApiServiceEdit.fetchCategories();

    setState(() {
      categories = fetchedCategories
          .where((category) => category['id_tipe'] == (isIncome ? "1" : "2"))
          .toList();

      if (categories.isNotEmpty && selectedCategory == null) {
        selectedCategory = categories[0]['id_kategori'].toString();
      }
      isLoadingCategories = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Transaksi"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle Income/Expense
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
                ),
                Text(
                  isIncome ? "Income" : "Expense",
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Input Nominal
            TextField(
              controller: nominalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Nominal",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            // Dropdown Kategori
            isLoadingCategories
                ? Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category['id_kategori'].toString(),
                        child: Text(category['nama_kategori']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(),
                    ),
                  ),
            SizedBox(height: 20),
            // Input Tanggal
            InkWell(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: "Tanggal",
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  selectedDate != null
                      ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                      : "Pilih tanggal",
                ),
              ),
            ),
            SizedBox(height: 20),
            // Input Deskripsi
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(),
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
                      SnackBar(content: Text("Semua kolom wajib diisi")),
                    );
                    return;
                  }

                  final formattedDate =
                      "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

                  final response = await ApiServiceEdit.updateTransaction(
                    idUser: userId!,
                    idTransaksi: widget.transaction['id_transaksi'],
                    idTipe: isIncome ? "1" : "2",
                    nominal: nominalController.text,
                    tanggalTransaksi: formattedDate,
                    deskripsi: descriptionController.text,
                  );

                  if (response['status'] == 'success') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Data berhasil diperbarui")),
                    );
                    Navigator.pop(context,
                        true); // Mengembalikan true sebagai indikasi sukses
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            response['message'] ?? "Gagal memperbarui data"),
                      ),
                    );
                  }
                },
                child: Text("Simpan"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
